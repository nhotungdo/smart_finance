import 'package:flutter/foundation.dart';
import 'package:smart_finance/data/database/local_database.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/ocr_result_model.dart';
import 'package:smart_finance/data/models/pdf_export_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PendingImageSyncResult {
  final int uploaded;
  final List<String> errors;

  const PendingImageSyncResult({this.uploaded = 0, this.errors = const []});
}

class InvoiceRepository {
  final LocalDatabase _localDb = LocalDatabase.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // ─────────────────────────────────────────────
  // INVOICE CRUD
  // ─────────────────────────────────────────────

  Future<List<InvoiceModel>> getInvoices(
    String companyId, {
    String? createdBy,
  }) async {
    final db = await _localDb.database;
    final where = createdBy == null
        ? 'company_id = ?'
        : 'company_id = ? AND created_by = ?';
    final whereArgs = <Object?>[companyId];
    if (createdBy != null) {
      whereArgs.add(createdBy);
    }
    final maps = await db.query(
      'invoices',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => InvoiceModel.fromMap(m)).toList();
  }

  Future<InvoiceModel?> getInvoiceById(String invoiceId) async {
    final db = await _localDb.database;
    final maps = await db.query(
      'invoices',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return InvoiceModel.fromMap(maps.first);
  }

  Future<List<InvoiceModel>> getInvoicesByDateRange(
    DateTime start,
    DateTime end, {
    required String companyId,
    String? createdBy,
  }) async {
    final db = await _localDb.database;
    final where = StringBuffer(
      'company_id = ? AND invoice_date >= ? AND invoice_date <= ?',
    );
    final whereArgs = <Object?>[
      companyId,
      start.toIso8601String(),
      end.toIso8601String(),
    ];
    if (createdBy != null) {
      where.write(' AND created_by = ?');
      whereArgs.add(createdBy);
    }
    final maps = await db.query(
      'invoices',
      where: where.toString(),
      whereArgs: whereArgs,
      orderBy: 'invoice_date DESC',
    );
    return maps.map(InvoiceModel.fromMap).toList();
  }

  Future<String> addInvoice(InvoiceModel invoice) async {
    final db = await _localDb.database;
    final localInvoice = invoice.copyWith(isSynced: false);
    await db.insert(
      'invoices',
      localInvoice.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return invoice.id;
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    final db = await _localDb.database;
    final updated = invoice.copyWith(
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await db.update(
      'invoices',
      updated.toMap(),
      where: 'invoice_id = ?',
      whereArgs: [invoice.id],
    );
  }

  Future<void> deleteInvoice(String invoiceId) async {
    final db = await _localDb.database;
    await db.transaction((txn) async {
      final invoices = await txn.query(
        'invoices',
        columns: ['company_id', 'created_by'],
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
        limit: 1,
      );
      if (invoices.isEmpty) return;
      final owner = invoices.first;
      final linkedTransactions = await txn.query(
        'transactions',
        columns: ['transaction_id'],
        where: 'invoice_id = ? AND status = ?',
        whereArgs: [invoiceId, 'ACTIVE'],
        limit: 1,
      );
      if (linkedTransactions.isNotEmpty) {
        throw StateError(
          'Hóa đơn đang liên kết với giao dịch nên không thể xóa.',
        );
      }
      await txn.delete(
        'pending_invoice_images',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
      await txn.delete(
        'ocr_results',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
      await txn.delete(
        'pdf_exports',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
      await txn.insert('sync_deletions', {
        'table_name': 'invoices',
        'record_id': invoiceId,
        'company_id': owner['company_id'],
        'created_by': owner['created_by'],
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete(
        'invoices',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
    });
  }

  // ─────────────────────────────────────────────
  // SUPABASE STORAGE - Upload ảnh hóa đơn
  // ─────────────────────────────────────────────

  Future<void> cacheInvoiceImage({
    required String invoiceId,
    required String companyId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final db = await _localDb.database;
    await db.insert('pending_invoice_images', {
      'invoice_id': invoiceId,
      'company_id': companyId,
      'file_name': fileName,
      'image_bytes': bytes,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<PendingImageSyncResult> uploadPendingInvoiceImages({
    required String companyId,
    required String createdBy,
  }) async {
    final db = await _localDb.database;
    final pending = await db.rawQuery(
      '''
      SELECT p.*
      FROM pending_invoice_images p
      JOIN invoices i ON i.invoice_id = p.invoice_id
      WHERE p.company_id = ? AND i.created_by = ?
      ORDER BY p.created_at ASC
      ''',
      [companyId, createdBy],
    );
    var uploaded = 0;
    final errors = <String>[];

    for (final item in pending) {
      final invoiceId = item['invoice_id'] as String;
      final companyId = item['company_id'] as String;
      final fileName = item['file_name'] as String;
      final rawBytes = item['image_bytes'];
      final bytes = rawBytes is Uint8List
          ? rawBytes
          : Uint8List.fromList((rawBytes as List).cast<int>());
      final storagePath = await uploadInvoiceImage(
        invoiceId: invoiceId,
        companyId: companyId,
        bytes: bytes,
        fileName: fileName,
      );

      if (storagePath == null) {
        errors.add('Không thể tải ảnh của hóa đơn $invoiceId.');
        continue;
      }

      await db.transaction((txn) async {
        await txn.update(
          'invoices',
          {
            'image_path': storagePath,
            'updated_at': DateTime.now().toIso8601String(),
            'is_synced': 0,
          },
          where: 'invoice_id = ?',
          whereArgs: [invoiceId],
        );
        await txn.delete(
          'pending_invoice_images',
          where: 'invoice_id = ?',
          whereArgs: [invoiceId],
        );
      });
      uploaded++;
    }

    return PendingImageSyncResult(uploaded: uploaded, errors: errors);
  }

  /// Upload ảnh lên Supabase Storage bucket "invoices"
  /// Trả về public URL của ảnh đã upload
  Future<String?> uploadInvoiceImage({
    required String invoiceId,
    required String companyId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final lowerName = fileName.toLowerCase();
      final extension = lowerName.endsWith('.png')
          ? '.png'
          : lowerName.endsWith('.webp')
          ? '.webp'
          : '.jpg';
      final contentType = extension == '.png'
          ? 'image/png'
          : extension == '.webp'
          ? 'image/webp'
          : 'image/jpeg';
      final storagePath = '$companyId/$invoiceId$extension';

      await _supabase.storage
          .from('invoices')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      debugPrint('InvoiceRepository: Uploaded image → $storagePath');
      return storagePath;
    } catch (e) {
      debugPrint('InvoiceRepository.uploadInvoiceImage failed: $e');
      return null; // Return null on failure, caller handles gracefully
    }
  }

  // ─────────────────────────────────────────────
  // OCR RESULTS
  // ─────────────────────────────────────────────

  /// Lưu kết quả OCR vào local SQLite, chờ người dùng đồng bộ thủ công.
  Future<void> saveOcrResult(OcrResultModel result) async {
    final db = await _localDb.database;
    await db.insert(
      'ocr_results',
      result.copyWith(isSynced: false).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lấy kết quả OCR theo invoice_id
  Future<OcrResultModel?> getOcrResult(String invoiceId) async {
    final db = await _localDb.database;
    final maps = await db.query(
      'ocr_results',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return OcrResultModel.fromMap(maps.first);
  }

  // ─────────────────────────────────────────────
  // PDF EXPORT
  // ─────────────────────────────────────────────

  /// Lưu bản ghi lịch sử xuất PDF
  Future<PdfExportModel> savePdfExport({
    required String companyId,
    required String exportedBy,
    required String invoiceId,
    required String exportType,
    required String filePath,
  }) async {
    final db = await _localDb.database;
    final export = PdfExportModel(
      pdfExportId: _uuid.v4(),
      companyId: companyId,
      exportedBy: exportedBy,
      invoiceId: invoiceId,
      exportType: exportType,
      filePath: filePath,
      exportedAt: DateTime.now(),
      isSynced: false,
    );

    await db.insert(
      'pdf_exports',
      export.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return export;
  }

  /// Lấy danh sách PDF đã xuất theo công ty
  Future<List<PdfExportModel>> getPdfExports(String companyId) async {
    final db = await _localDb.database;
    final maps = await db.query(
      'pdf_exports',
      where: 'company_id = ?',
      whereArgs: [companyId],
      orderBy: 'exported_at DESC',
    );
    return maps.map((m) => PdfExportModel.fromMap(m)).toList();
  }

  // ─────────────────────────────────────────────
  // SYNC SUPPORT (chỉ dùng bởi SyncRepository khi người dùng bấm đồng bộ)
  // ─────────────────────────────────────────────

  Future<List<InvoiceModel>> getUnsyncedInvoices({
    required String companyId,
    required String createdBy,
  }) async {
    final db = await _localDb.database;
    final maps = await db.query(
      'invoices',
      where: 'is_synced = 0 AND company_id = ? AND created_by = ?',
      whereArgs: [companyId, createdBy],
    );
    return maps.map((m) => InvoiceModel.fromMap(m)).toList();
  }

  Future<List<OcrResultModel>> getUnsyncedOcrResults({
    required String companyId,
    required String createdBy,
  }) async {
    final db = await _localDb.database;
    final maps = await db.rawQuery(
      '''
      SELECT o.*
      FROM ocr_results o
      JOIN invoices i ON i.invoice_id = o.invoice_id
      WHERE o.is_synced = 0
        AND i.company_id = ?
        AND i.created_by = ?
      ''',
      [companyId, createdBy],
    );
    return maps.map(OcrResultModel.fromMap).toList();
  }

  Future<void> markOcrResultsAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _localDb.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'ocr_results',
      {'is_synced': 1},
      where: 'ocr_result_id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<List<PdfExportModel>> getUnsyncedPdfExports({
    required String companyId,
    required String exportedBy,
  }) async {
    final db = await _localDb.database;
    final maps = await db.query(
      'pdf_exports',
      where: 'is_synced = 0 AND company_id = ? AND exported_by = ?',
      whereArgs: [companyId, exportedBy],
    );
    return maps.map(PdfExportModel.fromMap).toList();
  }

  Future<void> markPdfExportsAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _localDb.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'pdf_exports',
      {'is_synced': 1},
      where: 'pdf_export_id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<List<Map<String, Object?>>> getPendingDeletions({
    required String companyId,
    required String createdBy,
  }) async {
    final db = await _localDb.database;
    return db.query(
      'sync_deletions',
      where: 'company_id = ? AND created_by = ?',
      whereArgs: [companyId, createdBy],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> removePendingDeletion(String tableName, String recordId) async {
    final db = await _localDb.database;
    await db.delete(
      'sync_deletions',
      where: 'table_name = ? AND record_id = ?',
      whereArgs: [tableName, recordId],
    );
  }

  Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _localDb.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'invoices',
      {'is_synced': 1},
      where: 'invoice_id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> upsertInvoiceFromCloud(InvoiceModel cloudInvoice) async {
    final db = await _localDb.database;

    // Conflict resolution
    final localMaps = await db.query(
      'invoices',
      where: 'invoice_id = ?',
      whereArgs: [cloudInvoice.id],
      limit: 1,
    );

    if (localMaps.isNotEmpty) {
      final localInvoice = InvoiceModel.fromMap(localMaps.first);
      if (!localInvoice.isSynced &&
          localInvoice.updatedAt.isAfter(cloudInvoice.updatedAt)) {
        return; // Bỏ qua, không ghi đè bản ghi local mới hơn
      }
    }

    final map = cloudInvoice.toMap();
    map['is_synced'] = 1;
    await db.insert(
      'invoices',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
