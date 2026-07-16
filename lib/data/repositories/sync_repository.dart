import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_finance/data/database/local_database.dart';
import 'package:smart_finance/data/models/category_model.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/repositories/category_repository.dart';
import 'package:smart_finance/data/repositories/transaction_repository.dart';
import 'package:smart_finance/data/repositories/invoice_repository.dart';

/// Kết quả của một lần chạy sync
class SyncResult {
  final int pushedCategories;
  final int pushedTransactions;
  final int pushedInvoices;
  final int pulledCategories;
  final int pulledTransactions;
  final int pulledInvoices;
  final List<String> errors;

  const SyncResult({
    this.pushedCategories = 0,
    this.pushedTransactions = 0,
    this.pushedInvoices = 0,
    this.pulledCategories = 0,
    this.pulledTransactions = 0,
    this.pulledInvoices = 0,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  int get totalPushed => pushedCategories + pushedTransactions + pushedInvoices;
  int get totalPulled => pulledCategories + pulledTransactions + pulledInvoices;

  @override
  String toString() =>
      'SyncResult(↑$totalPushed pushed, ↓$totalPulled pulled, errors: ${errors.length})';
}

/// [SyncRepository] — Bộ não của Module Sync (Offline-First).
///
/// Thuật toán:
/// 1. **PUSH**: Quét SQLite tìm các dòng `is_synced = 0`, đẩy lên Supabase,
///    nếu thành công → cập nhật `is_synced = 1`.
/// 2. **PULL**: Tải dữ liệu mới từ Supabase về (theo companyId/userId),
///    upsert vào SQLite với `is_synced = 1`.
///
/// Mỗi bảng (categories, transactions, invoices) được xử lý độc lập để
/// một lỗi ở bảng này không làm block các bảng khác.
class SyncRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalDatabase _localDb = LocalDatabase.instance;

  final CategoryRepository _categoryRepo;
  final TransactionRepository _transactionRepo;
  final InvoiceRepository _invoiceRepo;

  SyncRepository({
    CategoryRepository? categoryRepo,
    TransactionRepository? transactionRepo,
    InvoiceRepository? invoiceRepo,
  })  : _categoryRepo = categoryRepo ?? CategoryRepository(),
        _transactionRepo = transactionRepo ?? TransactionRepository(),
        _invoiceRepo = invoiceRepo ?? InvoiceRepository();

  // ──────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ──────────────────────────────────────────────────────────────────────────

  /// Thực hiện toàn bộ chu trình sync: PUSH → PULL.
  /// [companyId] và [userId] dùng để lọc dữ liệu khi PULL.
  Future<SyncResult> sync({String? companyId, String? userId}) async {
    debugPrint('[SyncRepository] Bắt đầu sync...');

    int pushedCat = 0, pushedTx = 0, pushedInv = 0;
    int pulledCat = 0, pulledTx = 0, pulledInv = 0;
    final errors = <String>[];

    // ── PHASE 1: PUSH local → cloud ───────────────────────────────────────
    pushedCat = await _pushTable(
      label: 'Categories',
      fetchUnsynced: _categoryRepo.getUnsyncedCategories,
      buildPayload: (e) => e.toMap()..remove('is_synced'),
      getIds: (list) => list.map((e) => e.categoryId).toList(),
      supabaseTable: 'categories',
      markSynced: _categoryRepo.markAsSynced,
      errors: errors,
    );

    pushedTx = await _pushTable(
      label: 'Transactions',
      fetchUnsynced: _transactionRepo.getUnsyncedTransactions,
      buildPayload: (e) => e.toMap()..remove('is_synced'),
      getIds: (list) => list.map((e) => e.transactionId).toList(),
      supabaseTable: 'transactions',
      markSynced: _transactionRepo.markAsSynced,
      errors: errors,
    );

    pushedInv = await _pushTable(
      label: 'Invoices',
      fetchUnsynced: _invoiceRepo.getUnsyncedInvoices,
      buildPayload: (e) => e.toMap()..remove('is_synced'),
      getIds: (list) => list.map((e) => e.id).toList(),
      supabaseTable: 'invoices',
      markSynced: _invoiceRepo.markAsSynced,
      errors: errors,
    );

    // ── PHASE 2: PULL cloud → local ───────────────────────────────────────
    if (companyId != null || userId != null) {
      pulledCat = await _pullCategories(companyId: companyId, errors: errors);
      pulledTx = await _pullTransactions(companyId: companyId, userId: userId, errors: errors);
      pulledInv = await _pullInvoices(companyId: companyId, userId: userId, errors: errors);
    }

    final result = SyncResult(
      pushedCategories: pushedCat,
      pushedTransactions: pushedTx,
      pushedInvoices: pushedInv,
      pulledCategories: pulledCat,
      pulledTransactions: pulledTx,
      pulledInvoices: pulledInv,
      errors: errors,
    );

    debugPrint('[SyncRepository] Kết thúc sync: $result');
    return result;
  }

  /// Chỉ thực hiện PUSH (không PULL) — dùng khi vừa tạo dữ liệu offline.
  Future<SyncResult> pushOnly() async {
    debugPrint('[SyncRepository] Chỉ PUSH dữ liệu chưa đồng bộ...');
    final errors = <String>[];

    final pushedCat = await _pushTable(
      label: 'Categories',
      fetchUnsynced: _categoryRepo.getUnsyncedCategories,
      buildPayload: (e) => e.toMap()..remove('is_synced'),
      getIds: (list) => list.map((e) => e.categoryId).toList(),
      supabaseTable: 'categories',
      markSynced: _categoryRepo.markAsSynced,
      errors: errors,
    );

    final pushedTx = await _pushTable(
      label: 'Transactions',
      fetchUnsynced: _transactionRepo.getUnsyncedTransactions,
      buildPayload: (e) => e.toMap()..remove('is_synced'),
      getIds: (list) => list.map((e) => e.transactionId).toList(),
      supabaseTable: 'transactions',
      markSynced: _transactionRepo.markAsSynced,
      errors: errors,
    );

    final pushedInv = await _pushTable(
      label: 'Invoices',
      fetchUnsynced: _invoiceRepo.getUnsyncedInvoices,
      buildPayload: (e) => e.toMap()..remove('is_synced'),
      getIds: (list) => list.map((e) => e.id).toList(),
      supabaseTable: 'invoices',
      markSynced: _invoiceRepo.markAsSynced,
      errors: errors,
    );

    return SyncResult(
      pushedCategories: pushedCat,
      pushedTransactions: pushedTx,
      pushedInvoices: pushedInv,
      errors: errors,
    );
  }

  /// Đếm tổng số dòng chưa đồng bộ trong tất cả các bảng.
  Future<int> countUnsynced() async {
    final db = await _localDb.database;

    int count = 0;
    for (final table in ['categories', 'transactions', 'invoices', 'pdf_exports']) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as c FROM $table WHERE is_synced = 0',
      );
      count += (result.first['c'] as int?) ?? 0;
    }
    return count;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Generic PUSH helper — tái sử dụng cho mọi bảng.
  /// Trả về số dòng đã được đẩy thành công.
  Future<int> _pushTable<T>({
    required String label,
    required Future<List<T>> Function() fetchUnsynced,
    required Map<String, dynamic> Function(T) buildPayload,
    required List<String> Function(List<T>) getIds,
    required String supabaseTable,
    required Future<void> Function(List<String>) markSynced,
    required List<String> errors,
  }) async {
    try {
      final unsynced = await fetchUnsynced();
      if (unsynced.isEmpty) {
        debugPrint('[SyncRepository] $label: Không có dữ liệu cần PUSH.');
        return 0;
      }

      debugPrint('[SyncRepository] $label: PUSH ${unsynced.length} dòng...');

      final payload = unsynced.map(buildPayload).toList();

      // Dùng upsert để an toàn khi record đã tồn tại trên cloud
      await _supabase.from(supabaseTable).upsert(payload);

      // Chỉ mark synced sau khi Supabase xác nhận thành công
      final ids = getIds(unsynced);
      await markSynced(ids);

      debugPrint('[SyncRepository] $label: ✓ PUSH thành công ${ids.length} dòng.');
      return ids.length;
    } catch (e, st) {
      final msg = 'Lỗi PUSH $label: $e';
      debugPrint('[SyncRepository] ✗ $msg\n$st');
      errors.add(msg);
      return 0; // Tiếp tục với các bảng khác
    }
  }

  Future<int> _pullCategories({String? companyId, required List<String> errors}) async {
    try {
      var query = _supabase.from('categories').select();
      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }

      final response = await query;
      int count = 0;
      for (final item in response) {
        final category = CategoryModel.fromMap(item);
        await _categoryRepo.upsertCategoryFromCloud(category);
        count++;
      }
      debugPrint('[SyncRepository] Categories: ↓ PULL $count dòng.');
      return count;
    } catch (e) {
      final msg = 'Lỗi PULL Categories: $e';
      debugPrint('[SyncRepository] ✗ $msg');
      errors.add(msg);
      return 0;
    }
  }

  Future<int> _pullTransactions({
    String? companyId,
    String? userId,
    required List<String> errors,
  }) async {
    try {
      var query = _supabase.from('transactions').select();
      if (companyId != null) {
        query = query.eq('company_id', companyId);
      } else if (userId != null) {
        query = query.eq('created_by', userId);
      }

      final response = await query;
      int count = 0;
      for (final item in response) {
        final tx = TransactionModel.fromMap(item);
        await _transactionRepo.upsertTransactionFromCloud(tx);
        count++;
      }
      debugPrint('[SyncRepository] Transactions: ↓ PULL $count dòng.');
      return count;
    } catch (e) {
      final msg = 'Lỗi PULL Transactions: $e';
      debugPrint('[SyncRepository] ✗ $msg');
      errors.add(msg);
      return 0;
    }
  }

  Future<int> _pullInvoices({
    String? companyId,
    String? userId,
    required List<String> errors,
  }) async {
    try {
      var query = _supabase.from('invoices').select();
      if (companyId != null) {
        query = query.eq('company_id', companyId);
      } else if (userId != null) {
        query = query.eq('uploaded_by', userId);
      }

      final response = await query;
      int count = 0;
      for (final item in response) {
        final invoice = InvoiceModel.fromMap(item);
        await _invoiceRepo.upsertInvoiceFromCloud(invoice);
        count++;
      }
      debugPrint('[SyncRepository] Invoices: ↓ PULL $count dòng.');
      return count;
    } catch (e) {
      final msg = 'Lỗi PULL Invoices: $e';
      debugPrint('[SyncRepository] ✗ $msg');
      errors.add(msg);
      return 0;
    }
  }
}
