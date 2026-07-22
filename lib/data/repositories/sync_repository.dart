import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_finance/data/database/local_database.dart';
import 'package:smart_finance/data/models/category_model.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:smart_finance/data/repositories/category_repository.dart';
import 'package:smart_finance/data/repositories/transaction_repository.dart';
import 'package:smart_finance/data/repositories/invoice_repository.dart';

/// Kết quả của một lần chạy sync
class SyncResult {
  final int pushedCategories;
  final int pushedTransactions;
  final int pushedInvoices;
  final int pushedInvoiceImages;
  final int pushedOcrResults;
  final int pushedPdfExports;
  final int pushedDeletions;
  final int pulledCategories;
  final int pulledTransactions;
  final int pulledInvoices;
  final List<String> errors;

  const SyncResult({
    this.pushedCategories = 0,
    this.pushedTransactions = 0,
    this.pushedInvoices = 0,
    this.pushedInvoiceImages = 0,
    this.pushedOcrResults = 0,
    this.pushedPdfExports = 0,
    this.pushedDeletions = 0,
    this.pulledCategories = 0,
    this.pulledTransactions = 0,
    this.pulledInvoices = 0,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  int get totalPushed =>
      pushedCategories +
      pushedTransactions +
      pushedInvoices +
      pushedInvoiceImages +
      pushedOcrResults +
      pushedPdfExports +
      pushedDeletions;
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
  }) : _categoryRepo = categoryRepo ?? CategoryRepository(),
       _transactionRepo = transactionRepo ?? TransactionRepository(),
       _invoiceRepo = invoiceRepo ?? InvoiceRepository();

  // ──────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ──────────────────────────────────────────────────────────────────────────

  /// Thực hiện toàn bộ chu trình sync: PUSH → PULL.
  /// [companyId] và [userId] dùng để lọc dữ liệu khi PULL.
  Future<SyncResult> sync({
    required String companyId,
    required String userId,
    required AppRole role,
  }) async {
    debugPrint('[SyncRepository] Bắt đầu sync...');

    int pushedCat = 0, pushedTx = 0, pushedInv = 0;
    int pushedImages = 0, pushedOcr = 0, pushedPdf = 0, pushedDeletes = 0;
    int pulledCat = 0, pulledTx = 0, pulledInv = 0;
    final errors = <String>[];

    // ── PHASE 1: PUSH local → cloud ───────────────────────────────────────
    final canManageInvoices = role == AppRole.accountant;
    if (canManageInvoices) {
      pushedDeletes = await _pushPendingDeletions(
        companyId: companyId,
        userId: userId,
        errors: errors,
      );
    }

    if (role == AppRole.accountant) {
      pushedCat = await _pushTable(
        label: 'Categories',
        fetchUnsynced: () =>
            _categoryRepo.getUnsyncedCategories(companyId: companyId),
        buildPayload: (e) => e.toMap()..remove('is_synced'),
        getIds: (list) => list.map((e) => e.categoryId).toList(),
        supabaseTable: 'categories',
        markSynced: _categoryRepo.markAsSynced,
        errors: errors,
      );
    }

    if (canManageInvoices) {
      final imageResult = await _invoiceRepo.uploadPendingInvoiceImages(
        companyId: companyId,
        createdBy: userId,
      );
      pushedImages = imageResult.uploaded;
      errors.addAll(imageResult.errors);

      pushedInv = await _pushTable(
        label: 'Invoices',
        fetchUnsynced: () => _invoiceRepo.getUnsyncedInvoices(
          companyId: companyId,
          createdBy: userId,
        ),
        buildPayload: (e) => e.toMap()..remove('is_synced'),
        getIds: (list) => list.map((e) => e.id).toList(),
        supabaseTable: 'invoices',
        markSynced: _invoiceRepo.markAsSynced,
        errors: errors,
      );
    }

    pushedTx = await _pushTable(
      label: 'Transactions',
      fetchUnsynced: () => _transactionRepo.getUnsyncedTransactions(
        companyId: companyId,
        userId: userId,
        role: role,
      ),
      buildPayload: (e) => e.toMap()..remove('is_synced'),
      getIds: (list) => list.map((e) => e.transactionId).toList(),
      supabaseTable: 'transactions',
      markSynced: _transactionRepo.markAsSynced,
      errors: errors,
    );

    if (canManageInvoices) {
      pushedOcr = await _pushTable(
        label: 'OCR results',
        fetchUnsynced: () => _invoiceRepo.getUnsyncedOcrResults(
          companyId: companyId,
          createdBy: userId,
        ),
        buildPayload: (e) => e.toMap()..remove('is_synced'),
        getIds: (list) => list.map((e) => e.id).toList(),
        supabaseTable: 'ocr_results',
        markSynced: _invoiceRepo.markOcrResultsAsSynced,
        errors: errors,
      );
    }

    pushedPdf = await _pushTable(
      label: 'PDF exports',
      fetchUnsynced: () => _invoiceRepo.getUnsyncedPdfExports(
        companyId: companyId,
        exportedBy: userId,
      ),
      buildPayload: (e) => e.toMap()..remove('is_synced'),
      getIds: (list) => list.map((e) => e.pdfExportId).toList(),
      supabaseTable: 'pdf_exports',
      markSynced: _invoiceRepo.markPdfExportsAsSynced,
      errors: errors,
    );

    // ── PHASE 2: PULL cloud → local ───────────────────────────────────────
    pulledCat = await _pullCategories(companyId: companyId, errors: errors);
    await _pullCompanyUsers(companyId: companyId, errors: errors);
    pulledInv = await _pullInvoices(
      companyId: companyId,
      userId: userId,
      errors: errors,
    );
    pulledTx = await _pullTransactions(
      companyId: companyId,
      userId: userId,
      errors: errors,
    );

    final result = SyncResult(
      pushedCategories: pushedCat,
      pushedTransactions: pushedTx,
      pushedInvoices: pushedInv,
      pushedInvoiceImages: pushedImages,
      pushedOcrResults: pushedOcr,
      pushedPdfExports: pushedPdf,
      pushedDeletions: pushedDeletes,
      pulledCategories: pulledCat,
      pulledTransactions: pulledTx,
      pulledInvoices: pulledInv,
      errors: errors,
    );

    debugPrint('[SyncRepository] Kết thúc sync: $result');
    return result;
  }

  /// Chỉ thực hiện PUSH (không PULL) — dùng khi vừa tạo dữ liệu offline.
  Future<SyncResult> pushOnly({
    required String companyId,
    required String userId,
    required AppRole role,
  }) async {
    debugPrint('[SyncRepository] Chỉ PUSH dữ liệu chưa đồng bộ...');
    final errors = <String>[];

    final canManageInvoices = role == AppRole.accountant;
    var pushedDeletes = 0;
    var pushedImages = 0;
    var pushedInv = 0;
    var pushedOcr = 0;
    if (canManageInvoices) {
      pushedDeletes = await _pushPendingDeletions(
        companyId: companyId,
        userId: userId,
        errors: errors,
      );
    }

    var pushedCat = 0;
    if (role == AppRole.accountant) {
      pushedCat = await _pushTable(
        label: 'Categories',
        fetchUnsynced: () =>
            _categoryRepo.getUnsyncedCategories(companyId: companyId),
        buildPayload: (e) => e.toMap()..remove('is_synced'),
        getIds: (list) => list.map((e) => e.categoryId).toList(),
        supabaseTable: 'categories',
        markSynced: _categoryRepo.markAsSynced,
        errors: errors,
      );
    }

    if (canManageInvoices) {
      final imageResult = await _invoiceRepo.uploadPendingInvoiceImages(
        companyId: companyId,
        createdBy: userId,
      );
      pushedImages = imageResult.uploaded;
      errors.addAll(imageResult.errors);

      pushedInv = await _pushTable(
        label: 'Invoices',
        fetchUnsynced: () => _invoiceRepo.getUnsyncedInvoices(
          companyId: companyId,
          createdBy: userId,
        ),
        buildPayload: (e) => e.toMap()..remove('is_synced'),
        getIds: (list) => list.map((e) => e.id).toList(),
        supabaseTable: 'invoices',
        markSynced: _invoiceRepo.markAsSynced,
        errors: errors,
      );
    }

    final pushedTx = await _pushTable(
      label: 'Transactions',
      fetchUnsynced: () => _transactionRepo.getUnsyncedTransactions(
        companyId: companyId,
        userId: userId,
        role: role,
      ),
      buildPayload: (e) => e.toMap()..remove('is_synced'),
      getIds: (list) => list.map((e) => e.transactionId).toList(),
      supabaseTable: 'transactions',
      markSynced: _transactionRepo.markAsSynced,
      errors: errors,
    );

    if (canManageInvoices) {
      pushedOcr = await _pushTable(
        label: 'OCR results',
        fetchUnsynced: () => _invoiceRepo.getUnsyncedOcrResults(
          companyId: companyId,
          createdBy: userId,
        ),
        buildPayload: (e) => e.toMap()..remove('is_synced'),
        getIds: (list) => list.map((e) => e.id).toList(),
        supabaseTable: 'ocr_results',
        markSynced: _invoiceRepo.markOcrResultsAsSynced,
        errors: errors,
      );
    }

    final pushedPdf = await _pushTable(
      label: 'PDF exports',
      fetchUnsynced: () => _invoiceRepo.getUnsyncedPdfExports(
        companyId: companyId,
        exportedBy: userId,
      ),
      buildPayload: (e) => e.toMap()..remove('is_synced'),
      getIds: (list) => list.map((e) => e.pdfExportId).toList(),
      supabaseTable: 'pdf_exports',
      markSynced: _invoiceRepo.markPdfExportsAsSynced,
      errors: errors,
    );

    return SyncResult(
      pushedCategories: pushedCat,
      pushedTransactions: pushedTx,
      pushedInvoices: pushedInv,
      pushedInvoiceImages: pushedImages,
      pushedOcrResults: pushedOcr,
      pushedPdfExports: pushedPdf,
      pushedDeletions: pushedDeletes,
      errors: errors,
    );
  }

  /// Đếm tổng số dòng chưa đồng bộ trong tất cả các bảng.
  Future<int> countUnsynced({
    required String companyId,
    required String userId,
    required AppRole role,
  }) async {
    final db = await _localDb.database;
    final queries = <String>[
      if (role == AppRole.accountant)
        '''
      SELECT COUNT(*) AS item_count
      FROM categories
      WHERE is_synced = 0 AND company_id = ?
      ''',
      if (role == AppRole.manager)
        '''
        SELECT COUNT(*)
        FROM transactions
        WHERE is_synced = 0
          AND company_id = ?
          AND approved_by = ?
          AND approval_status <> 'PENDING'
        '''
      else
        '''
        SELECT COUNT(*)
        FROM transactions
        WHERE is_synced = 0
          AND company_id = ?
          AND created_by = ?
          AND approval_status = 'PENDING'
        ''',
      '''
      SELECT COUNT(*)
      FROM pdf_exports
      WHERE is_synced = 0 AND company_id = ? AND exported_by = ?
      ''',
    ];
    final arguments = <Object?>[
      if (role == AppRole.accountant) companyId,
      companyId,
      userId,
      companyId,
      userId,
    ];
    if (role == AppRole.accountant) {
      queries.addAll([
        '''
        SELECT COUNT(*)
        FROM invoices
        WHERE is_synced = 0 AND company_id = ? AND created_by = ?
        ''',
        '''
        SELECT COUNT(*)
        FROM ocr_results o
        JOIN invoices i ON i.invoice_id = o.invoice_id
        WHERE o.is_synced = 0 AND i.company_id = ? AND i.created_by = ?
        ''',
        '''
        SELECT COUNT(*)
        FROM sync_deletions
        WHERE company_id = ? AND created_by = ?
        ''',
        '''
        SELECT COUNT(*)
        FROM pending_invoice_images p
        JOIN invoices i ON i.invoice_id = p.invoice_id
        WHERE p.company_id = ? AND i.created_by = ?
        ''',
      ]);
      arguments.addAll([
        companyId,
        userId,
        companyId,
        userId,
        companyId,
        userId,
        companyId,
        userId,
      ]);
    }
    final rows = await db.rawQuery('''
      SELECT SUM(item_count) AS total
      FROM (
        ${queries.join(' UNION ALL ')}
      )
      ''', arguments);
    return (rows.first['total'] as num?)?.toInt() ?? 0;
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

      debugPrint(
        '[SyncRepository] $label: ✓ PUSH thành công ${ids.length} dòng.',
      );
      return ids.length;
    } catch (e, st) {
      final msg = _formatPushError(label, e);
      debugPrint('[SyncRepository] ✗ $msg\n$st');
      errors.add(msg);
      return 0; // Tiếp tục với các bảng khác
    }
  }

  String _formatPushError(String label, Object error) {
    if (error is PostgrestException && error.code == 'PGRST204') {
      return 'Không thể đồng bộ $label: schema Supabase chưa khớp với ứng '
          'dụng. Hãy chạy file migration mới nhất trong Supabase SQL Editor.';
    }
    if (error is PostgrestException && error.code == '42501') {
      return 'Không thể đồng bộ $label vì dữ liệu không thuộc quyền của tài '
          'khoản hiện tại.';
    }
    return 'Lỗi PUSH $label: $error';
  }

  Future<int> _pullCategories({
    String? companyId,
    required List<String> errors,
  }) async {
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
      const msg = 'Không thể tải danh mục từ máy chủ.';
      debugPrint('[SyncRepository] ✗ $msg $e');
      errors.add(msg);
      return 0;
    }
  }

  Future<int> _pullCompanyUsers({
    required String companyId,
    required List<String> errors,
  }) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('company_id', companyId);
      final db = await _localDb.database;
      var count = 0;
      await db.transaction((txn) async {
        for (final item in response) {
          final user = UserModel.fromMap(item);
          final map = user.toMap();
          map['is_synced'] = 1;
          await txn.insert(
            'users',
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          count++;
        }
      });
      debugPrint('[SyncRepository] Users: ↓ PULL $count dòng.');
      return count;
    } catch (error) {
      const message = 'Không thể tải danh sách tài khoản của công ty.';
      debugPrint('[SyncRepository] ✗ $message $error');
      errors.add(message);
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
      const msg = 'Không thể tải giao dịch từ máy chủ.';
      debugPrint('[SyncRepository] ✗ $msg $e');
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
      const msg = 'Không thể tải hóa đơn từ máy chủ.';
      debugPrint('[SyncRepository] ✗ $msg $e');
      errors.add(msg);
      return 0;
    }
  }

  Future<int> _pushPendingDeletions({
    required String companyId,
    required String userId,
    required List<String> errors,
  }) async {
    final pending = await _invoiceRepo.getPendingDeletions(
      companyId: companyId,
      createdBy: userId,
    );
    var deleted = 0;

    for (final item in pending) {
      final tableName = item['table_name'] as String;
      final recordId = item['record_id'] as String;
      if (tableName != 'invoices') {
        errors.add('Bảng xóa không được hỗ trợ: $tableName');
        continue;
      }

      try {
        await _supabase.from(tableName).delete().eq('invoice_id', recordId);
        await _invoiceRepo.removePendingDeletion(tableName, recordId);
        deleted++;
      } catch (e) {
        errors.add('Lỗi DELETE $tableName/$recordId: $e');
      }
    }

    return deleted;
  }
}
