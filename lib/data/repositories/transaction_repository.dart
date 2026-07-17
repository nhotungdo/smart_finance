import 'package:smart_finance/data/database/local_database.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

class TransactionRepository {
  TransactionRepository({Future<Database> Function()? databaseProvider})
    : _databaseProvider =
          databaseProvider ?? (() => LocalDatabase.instance.database);

  final Future<Database> Function() _databaseProvider;
  final _uuid = const Uuid();

  Future<String> addTransaction({
    required String companyId,
    String? categoryId,
    required String createdBy,
    required int amount,
    required TransactionType transactionType,
    required DateTime transactionDate,
    String? description,
    String? receiptImagePath,
    String? invoiceId,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Số tiền phải lớn hơn 0');
    }
    final db = await _databaseProvider();
    final now = DateTime.now();
    final transactionId = _uuid.v4();

    final transaction = TransactionModel(
      transactionId: transactionId,
      companyId: companyId,
      categoryId: categoryId,
      createdBy: createdBy,
      invoiceId: invoiceId,
      amount: amount,
      transactionType: transactionType,
      transactionDate: transactionDate,
      description: description,
      receiptImagePath: receiptImagePath,
      status: RecordStatus.active,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    await db.insert('transactions', transaction.toMap());
    return transactionId;
  }

  Future<List<TransactionModel>> getRecentTransactions({
    String? companyId,
    int? limit = 50,
  }) async {
    final db = await _databaseProvider();
    final result = await db.query(
      'transactions',
      where: companyId != null ? 'company_id = ? AND status = ?' : 'status = ?',
      whereArgs: companyId != null
          ? [companyId, RecordStatus.active.databaseValue]
          : [RecordStatus.active.databaseValue],
      orderBy: 'transaction_date DESC, created_at DESC',
      limit: limit,
    );

    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<TransactionModel?> getTransactionById(
    String transactionId, {
    String? companyId,
  }) async {
    final db = await _databaseProvider();
    final result = await db.query(
      'transactions',
      where: companyId == null
          ? 'transaction_id = ? AND status = ?'
          : 'transaction_id = ? AND company_id = ? AND status = ?',
      whereArgs: companyId == null
          ? [transactionId, RecordStatus.active.databaseValue]
          : [transactionId, companyId, RecordStatus.active.databaseValue],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return TransactionModel.fromMap(result.first);
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end, {
    String? companyId,
  }) async {
    final db = await _databaseProvider();
    final result = await db.query(
      'transactions',
      where:
          'transaction_date >= ? AND transaction_date <= ? AND status = ? ${companyId != null ? 'AND company_id = ?' : ''}',
      whereArgs: companyId != null
          ? [
              start.toIso8601String(),
              end.toIso8601String(),
              RecordStatus.active.databaseValue,
              companyId,
            ]
          : [
              start.toIso8601String(),
              end.toIso8601String(),
              RecordStatus.active.databaseValue,
            ],
      orderBy: 'transaction_date DESC',
    );

    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<void> deleteTransaction(String transactionId) async {
    final db = await _databaseProvider();
    final transaction = await getTransactionById(transactionId);
    if (transaction == null) {
      throw StateError('Không tìm thấy giao dịch cần xóa.');
    }
    if (transaction.invoiceId != null) {
      throw StateError(
        'Giao dịch đang liên kết với hóa đơn nên không thể xóa.',
      );
    }
    if (await _hasLaterActiveTransaction(transaction)) {
      throw StateError(
        'Không thể xóa giao dịch này vì đã có giao dịch phát sinh sau đó.',
      );
    }
    final affectedRows = await db.update(
      'transactions',
      {
        'status': RecordStatus.deleted.databaseValue,
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      },
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    if (affectedRows == 0) {
      throw StateError('Không tìm thấy giao dịch cần xóa.');
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    if (transaction.amount <= 0) {
      throw ArgumentError.value(
        transaction.amount,
        'amount',
        'Số tiền phải lớn hơn 0',
      );
    }
    final db = await _databaseProvider();
    final current = await getTransactionById(transaction.transactionId);
    if (current == null) {
      throw StateError('Không tìm thấy giao dịch cần sửa.');
    }
    if (current.invoiceId != null) {
      throw StateError(
        'Giao dịch tạo từ hóa đơn được khóa để bảo toàn số liệu.',
      );
    }

    final updated = transaction.copyWith(
      companyId: current.companyId,
      createdBy: current.createdBy,
      createdAt: current.createdAt,
      status: current.status,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    final affectedRows = await db.update(
      'transactions',
      updated.toMap(),
      where: 'transaction_id = ?',
      whereArgs: [transaction.transactionId],
    );
    if (affectedRows == 0) {
      throw StateError('Không tìm thấy giao dịch cần sửa.');
    }
  }

  Future<void> linkInvoiceToTransaction({
    required String transactionId,
    required String invoiceId,
  }) async {
    final db = await _databaseProvider();
    final current = await getTransactionById(transactionId);
    if (current == null) {
      throw StateError('Không tìm thấy giao dịch cần liên kết.');
    }
    if (current.transactionType != TransactionType.expense) {
      throw StateError('Chỉ giao dịch chi mới tạo hóa đơn đầu vào.');
    }
    if (current.invoiceId == invoiceId) return;
    if (current.invoiceId != null) {
      throw StateError('Giao dịch này đã liên kết với một hóa đơn khác.');
    }
    final linkedTransaction = await getActiveTransactionForInvoice(invoiceId);
    if (linkedTransaction != null &&
        linkedTransaction.transactionId != transactionId) {
      throw StateError('Hóa đơn này đã liên kết với một giao dịch khác.');
    }

    final affectedRows = await db.update(
      'transactions',
      {
        'invoice_id': invoiceId,
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      },
      where: 'transaction_id = ? AND status = ?',
      whereArgs: [transactionId, RecordStatus.active.databaseValue],
    );
    if (affectedRows == 0) {
      throw StateError('Không thể liên kết hóa đơn với giao dịch.');
    }
  }

  Future<TransactionModel?> getActiveTransactionForInvoice(
    String invoiceId,
  ) async {
    final db = await _databaseProvider();
    final rows = await db.query(
      'transactions',
      where: 'invoice_id = ? AND status = ?',
      whereArgs: [invoiceId, RecordStatus.active.databaseValue],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TransactionModel.fromMap(rows.first);
  }

  Future<bool> hasActiveTransactionForInvoice(String invoiceId) async {
    return await getActiveTransactionForInvoice(invoiceId) != null;
  }

  Future<bool> _hasLaterActiveTransaction(TransactionModel transaction) async {
    final db = await _databaseProvider();
    final rows = await db.rawQuery(
      '''
      SELECT 1
      FROM transactions
      WHERE status = ?
        AND transaction_id <> ?
        AND company_id IS ?
        AND (
          transaction_date > ?
          OR (
            transaction_date = ?
            AND COALESCE(created_at, '') > ?
          )
        )
      LIMIT 1
      ''',
      [
        RecordStatus.active.databaseValue,
        transaction.transactionId,
        transaction.companyId,
        transaction.transactionDate.toIso8601String(),
        transaction.transactionDate.toIso8601String(),
        transaction.createdAt?.toIso8601String() ?? '',
      ],
    );
    return rows.isNotEmpty;
  }

  // --- Sync Methods ---

  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    final db = await _databaseProvider();
    final result = await db.query('transactions', where: 'is_synced = 0');
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _databaseProvider();
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'transactions',
      {'is_synced': 1},
      where: 'transaction_id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> upsertTransactionFromCloud(
    TransactionModel cloudTransaction,
  ) async {
    final db = await _databaseProvider();

    // Conflict resolution
    final localMaps = await db.query(
      'transactions',
      where: 'transaction_id = ?',
      whereArgs: [cloudTransaction.transactionId],
      limit: 1,
    );

    if (localMaps.isNotEmpty) {
      final localTransaction = TransactionModel.fromMap(localMaps.first);
      if (!localTransaction.isSynced &&
          localTransaction.updatedAt != null &&
          cloudTransaction.updatedAt != null &&
          localTransaction.updatedAt!.isAfter(cloudTransaction.updatedAt!)) {
        return; // Bỏ qua, không ghi đè bản ghi local mới hơn
      }
    }

    final map = cloudTransaction.toMap();
    map['is_synced'] = 1; // Always mark as synced when pulling from cloud
    await db.insert(
      'transactions',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
