import 'package:smart_finance/data/database/local_database.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

class TransactionRepository {
  final LocalDatabase _db = LocalDatabase.instance;
  final _uuid = const Uuid();

  Future<String> addTransaction({
    String? companyId,
    String? categoryId,
    String? createdBy,
    required double amount,
    required String transactionType,
    required DateTime transactionDate,
    String? description,
    String? receiptImagePath,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final transactionId = _uuid.v4();

    final transaction = TransactionModel(
      transactionId: transactionId,
      companyId: companyId,
      categoryId: categoryId,
      createdBy: createdBy,
      amount: amount,
      transactionType: transactionType,
      transactionDate: transactionDate,
      description: description,
      receiptImagePath: receiptImagePath,
      status: 'completed',
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    await db.insert('transactions', transaction.toMap());
    return transactionId;
  }

  Future<List<TransactionModel>> getRecentTransactions({String? companyId, int limit = 50}) async {
    final db = await _db.database;
    final result = await db.query(
      'transactions',
      where: companyId != null ? 'company_id = ?' : null,
      whereArgs: companyId != null ? [companyId] : null,
      orderBy: 'transaction_date DESC, created_at DESC',
      limit: limit,
    );
    
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }
  
  Future<List<TransactionModel>> getTransactionsByDateRange(DateTime start, DateTime end, {String? companyId}) async {
    final db = await _db.database;
    final result = await db.query(
      'transactions',
      where: 'transaction_date >= ? AND transaction_date <= ? ${companyId != null ? 'AND company_id = ?' : ''}',
      whereArgs: companyId != null 
          ? [start.toIso8601String(), end.toIso8601String(), companyId]
          : [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'transaction_date DESC',
    );
    
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<void> deleteTransaction(String transactionId) async {
    final db = await _db.database;
    await db.delete('transactions', where: 'transaction_id = ?', whereArgs: [transactionId]);
  }

  // --- Sync Methods ---
  
  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    final db = await _db.database;
    final result = await db.query(
      'transactions',
      where: 'is_synced = 0',
    );
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _db.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'transactions',
      {'is_synced': 1},
      where: 'transaction_id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> upsertTransactionFromCloud(TransactionModel cloudTransaction) async {
    final db = await _db.database;

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
