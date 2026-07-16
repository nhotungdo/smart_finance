import 'package:flutter/foundation.dart';
import 'package:smart_finance/data/database/local_database.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/ocr_result_model.dart';
import 'package:smart_finance/data/models/pdf_export_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class InvoiceRepository {
  final LocalDatabase _localDb = LocalDatabase.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // ─────────────────────────────────────────────
  // INVOICE CRUD
  // ─────────────────────────────────────────────

  Future<List<InvoiceModel>> getInvoices(String companyId) async {
    final db = await _localDb.database;
    final maps = await db.query(
      'invoices',
      where: 'company_id = ?',
      whereArgs: [companyId],
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

  Future<String> addInvoice(InvoiceModel invoice) async {
    final db = await _localDb.database;
    // 1. Save locally first (offline-first)
    await db.insert(
      'invoices',
      invoice.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 2. Try to push to Supabase
    try {
      final map = invoice.toMap()..remove('is_synced');
      await _supabase.from('invoices').upsert(map);
      // Mark as synced
      await db.update(
        'invoices',
        {'is_synced': 1},
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );
    } catch (e) {
      debugPrint('InvoiceRepository.addInvoice Supabase sync failed: $e');
    }
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

    try {
      final map = updated.toMap()..remove('is_synced');
      await _supabase.from('invoices').upsert(map);
      await db.update(
        'invoices',
        {'is_synced': 1},
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );
    } catch (e) {
      debugPrint('InvoiceRepository.updateInvoice Supabase sync failed: $e');
    }
  }

  Future<void> deleteInvoice(String invoiceId) async {
    final db = await _localDb.database;
    await db.delete(
      'invoices',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    try {
      await _supabase.from('invoices').delete().eq('invoice_id', invoiceId);
    } catch (e) {
      debugPrint('InvoiceRepository.deleteInvoice Supabase sync failed: $e');
    }
  }

  // ─────────────────────────────────────────────
  // SUPABASE STORAGE - Upload ảnh hóa đơn
  // ─────────────────────────────────────────────

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

  /// Lưu kết quả OCR vào local SQLite và đồng bộ lên Supabase
  Future<void> saveOcrResult(OcrResultModel result) async {
    final db = await _localDb.database;
    await db.insert(
      'ocr_results',
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Sync to Supabase
    try {
      await _supabase.from('ocr_results').upsert(result.toMap());
    } catch (e) {
      debugPrint('InvoiceRepository.saveOcrResult Supabase sync failed: $e');
    }
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

    // Sync to Supabase
    try {
      final map = export.toMap()..remove('is_synced');
      await _supabase.from('pdf_exports').insert(map);
      await db.update(
        'pdf_exports',
        {'is_synced': 1},
        where: 'pdf_export_id = ?',
        whereArgs: [export.pdfExportId],
      );
    } catch (e) {
      debugPrint('InvoiceRepository.savePdfExport Supabase sync failed: $e');
    }
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
  // SYNC SUPPORT (dùng bởi SyncService)
  // ─────────────────────────────────────────────

  Future<List<InvoiceModel>> getUnsyncedInvoices() async {
    final db = await _localDb.database;
    final maps = await db.query('invoices', where: 'is_synced = 0');
    return maps.map((m) => InvoiceModel.fromMap(m)).toList();
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
