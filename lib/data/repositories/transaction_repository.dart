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
    ApprovalStatus approvalStatus = ApprovalStatus.pending,
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
      approvalStatus: approvalStatus,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    await db.insert('transactions', transaction.toMap());
    return transactionId;
  }

  Future<List<TransactionModel>> getRecentTransactions({
    String? companyId,
    String? createdBy,
    ApprovalStatus? approvalStatus,
    int? limit = 50,
  }) async {
    final db = await _databaseProvider();
    final conditions = <String>['status = ?'];
    final arguments = <Object?>[RecordStatus.active.databaseValue];
    if (companyId != null) {
      conditions.add('company_id = ?');
      arguments.add(companyId);
    }
    if (createdBy != null) {
      conditions.add('created_by = ?');
      arguments.add(createdBy);
    }
    if (approvalStatus != null) {
      conditions.add('approval_status = ?');
      arguments.add(approvalStatus.databaseValue);
    }
    final result = await db.query(
      'transactions',
      where: conditions.join(' AND '),
      whereArgs: arguments,
      orderBy: 'transaction_date DESC, created_at DESC',
      limit: limit,
    );

    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  /// Khôi phục quan hệ cho dữ liệu cũ: mỗi hóa đơn hợp lệ phải có một giao
  /// dịch ACTIVE. Không tự đoán danh mục vì dữ liệu OCR cũ không chứa trường đó.
  Future<int> ensureTransactionsForInvoices({
    required String companyId,
    required String createdBy,
  }) async {
    final db = await _databaseProvider();
    final invoices = await db.rawQuery(
      '''
      SELECT i.*
      FROM invoices i
      WHERE i.company_id = ?
        AND COALESCE(i.total_amount, 0) > 0
        AND NOT EXISTS (
          SELECT 1
          FROM transactions t
          WHERE t.invoice_id = i.invoice_id
            AND t.status = ?
        )
      ORDER BY i.created_at ASC
      ''',
      [companyId, RecordStatus.active.databaseValue],
    );
    if (invoices.isEmpty) return 0;

    var created = 0;
    await db.transaction((txn) async {
      for (final invoice in invoices) {
        final invoiceId = invoice['invoice_id'] as String;
        final type = TransactionType.fromDatabase(invoice['invoice_type']);
        final invoiceNumber = invoice['invoice_number'] as String?;
        final now = DateTime.now();
        await txn.insert('transactions', {
          'transaction_id': _uuid.v4(),
          'company_id': companyId,
          'category_id': null,
          'created_by': createdBy,
          'invoice_id': invoiceId,
          'amount': (invoice['total_amount'] as num).round(),
          'transaction_type': type.databaseValue,
          'transaction_date':
              invoice['invoice_date'] ??
              invoice['created_at'] ??
              now.toIso8601String(),
          'description':
              '${type == TransactionType.income ? 'Thu' : 'Chi'} hóa đơn ${invoiceNumber ?? invoiceId}',
          'receipt_image_path': invoice['image_path'],
          'status': RecordStatus.active.databaseValue,
          'approval_status': ApprovalStatus.approved.databaseValue,
          'approved_by': null,
          'approved_at': now.toIso8601String(),
          'rejection_reason': null,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'is_synced': 0,
        });
        created++;
      }
    });
    return created;
  }

  Future<TransactionModel?> getTransactionById(
    String transactionId, {
    String? companyId,
    String? createdBy,
  }) async {
    final db = await _databaseProvider();
    final conditions = <String>['transaction_id = ?', 'status = ?'];
    final arguments = <Object?>[
      transactionId,
      RecordStatus.active.databaseValue,
    ];
    if (companyId != null) {
      conditions.add('company_id = ?');
      arguments.add(companyId);
    }
    if (createdBy != null) {
      conditions.add('created_by = ?');
      arguments.add(createdBy);
    }
    final result = await db.query(
      'transactions',
      where: conditions.join(' AND '),
      whereArgs: arguments,
      limit: 1,
    );
    if (result.isEmpty) return null;
    return TransactionModel.fromMap(result.first);
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end, {
    String? companyId,
    String? createdBy,
    ApprovalStatus? approvalStatus,
  }) async {
    final db = await _databaseProvider();
    final conditions = <String>[
      'transaction_date >= ?',
      'transaction_date <= ?',
      'status = ?',
    ];
    final arguments = <Object?>[
      start.toIso8601String(),
      end.toIso8601String(),
      RecordStatus.active.databaseValue,
    ];
    if (companyId != null) {
      conditions.add('company_id = ?');
      arguments.add(companyId);
    }
    if (createdBy != null) {
      conditions.add('created_by = ?');
      arguments.add(createdBy);
    }
    if (approvalStatus != null) {
      conditions.add('approval_status = ?');
      arguments.add(approvalStatus.databaseValue);
    }
    final result = await db.query(
      'transactions',
      where: conditions.join(' AND '),
      whereArgs: arguments,
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
    if (transaction.approvalStatus == ApprovalStatus.approved) {
      throw StateError('Giao dịch đã duyệt nên không thể xóa.');
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
    if (current.approvalStatus == ApprovalStatus.approved) {
      throw StateError('Giao dịch đã duyệt nên không thể sửa.');
    }

    final updated = transaction.copyWith(
      companyId: current.companyId,
      createdBy: current.createdBy,
      createdAt: current.createdAt,
      status: current.status,
      approvalStatus: ApprovalStatus.pending,
      clearApproval: true,
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
    if (current.approvalStatus != ApprovalStatus.pending) {
      throw StateError('Chỉ giao dịch đang chờ duyệt mới được gắn hóa đơn.');
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

  Future<void> reviewTransaction({
    required String transactionId,
    required String managerId,
    required ApprovalStatus decision,
    String? rejectionReason,
  }) async {
    if (decision == ApprovalStatus.pending) {
      throw ArgumentError('Quyết định phải là APPROVED hoặc REJECTED.');
    }
    if (decision == ApprovalStatus.rejected &&
        (rejectionReason == null || rejectionReason.trim().isEmpty)) {
      throw ArgumentError('Cần nhập lý do từ chối.');
    }
    final db = await _databaseProvider();
    final affectedRows = await db.update(
      'transactions',
      {
        'approval_status': decision.databaseValue,
        'approved_by': managerId,
        'approved_at': DateTime.now().toIso8601String(),
        'rejection_reason': decision == ApprovalStatus.rejected
            ? rejectionReason!.trim()
            : null,
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      },
      where: 'transaction_id = ? AND status = ? AND approval_status = ?',
      whereArgs: [
        transactionId,
        RecordStatus.active.databaseValue,
        ApprovalStatus.pending.databaseValue,
      ],
    );
    if (affectedRows == 0) {
      throw StateError('Giao dịch không còn ở trạng thái chờ duyệt.');
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

  Future<List<TransactionModel>> getUnsyncedTransactions({
    required String companyId,
    required String userId,
    required AppRole role,
  }) async {
    final db = await _databaseProvider();
    final isManager = role == AppRole.manager;
    final result = await db.query(
      'transactions',
      where: isManager
          ? '''
            is_synced = 0
            AND company_id = ?
            AND approved_by = ?
            AND approval_status <> ?
          '''
          : '''
            is_synced = 0
            AND company_id = ?
            AND created_by = ?
            AND approval_status = ?
          ''',
      whereArgs: [companyId, userId, ApprovalStatus.pending.databaseValue],
    );
    final transactions = <TransactionModel>[];
    for (final row in result) {
      final transaction = TransactionModel.fromMap(row);
      final resolvedCategoryId = await _resolveCategoryId(db, transaction);
      if (resolvedCategoryId != transaction.categoryId) {
        await db.update(
          'transactions',
          {'category_id': resolvedCategoryId},
          where: 'transaction_id = ?',
          whereArgs: [transaction.transactionId],
        );
        final normalizedMap = transaction.toMap();
        normalizedMap['category_id'] = resolvedCategoryId;
        transactions.add(TransactionModel.fromMap(normalizedMap));
      } else {
        transactions.add(transaction);
      }
    }
    return transactions;
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
    map['category_id'] = await _resolveCategoryId(db, cloudTransaction);
    map['is_synced'] = 1; // Always mark as synced when pulling from cloud
    await db.insert(
      'transactions',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> _resolveCategoryId(
    Database db,
    TransactionModel transaction,
  ) async {
    final categoryId = transaction.categoryId;
    final companyId = transaction.companyId;
    if (categoryId == null || companyId == null) return categoryId;

    if (await _categoryExists(db, categoryId, companyId)) return categoryId;

    if (categoryId.startsWith('default:')) {
      final companySeparator = categoryId.indexOf(':', 'default:'.length);
      if (companySeparator >= 0) {
        final suffix = categoryId.substring(companySeparator + 1);
        final canonicalId = 'default:$companyId:$suffix';
        if (await _categoryExists(db, canonicalId, companyId)) {
          return canonicalId;
        }
      }
    }

    final fallback = await db.query(
      'categories',
      columns: ['category_id'],
      where: '''
        company_id = ?
        AND category_type = ?
        AND status = ?
      ''',
      whereArgs: [
        companyId,
        transaction.transactionType.databaseValue,
        RecordStatus.active.databaseValue,
      ],
      orderBy: 'is_default DESC, category_name ASC',
      limit: 1,
    );
    return fallback.isEmpty ? null : fallback.first['category_id'] as String?;
  }

  Future<bool> _categoryExists(
    Database db,
    String categoryId,
    String companyId,
  ) async {
    final rows = await db.query(
      'categories',
      columns: ['category_id'],
      where: 'category_id = ? AND company_id = ? AND status = ?',
      whereArgs: [categoryId, companyId, RecordStatus.active.databaseValue],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
