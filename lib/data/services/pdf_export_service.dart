import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/pdf_export_model.dart';
import 'package:smart_finance/data/repositories/invoice_repository.dart';

/// Service xử lý xuất báo cáo hóa đơn ra file PDF.
/// Hiện tại tạo file văn bản (.txt) để mô phỏng PDF (không cần thư viện ngoài).
/// TODO: Thay thế bằng package `pdf` + `printing` khi muốn PDF thực sự.
class PdfExportService {
  final InvoiceRepository _invoiceRepo;

  PdfExportService(this._invoiceRepo);

  /// Xuất hóa đơn ra file và lưu log vào bảng pdf_exports
  Future<PdfExportModel?> exportInvoice({
    required InvoiceModel invoice,
    required String companyId,
    required String exportedBy,
    String exportType = 'invoice_pdf',
  }) async {
    try {
      // ── Bước 1: Tạo nội dung "PDF" (dạng text mô phỏng) ──
      final content = _buildInvoiceContent(invoice);

      // ── Bước 2: Lưu vào file hệ thống ──
      final filePath = await _saveToFile(invoice.id, content);
      debugPrint('PdfExportService: Saved export to $filePath');

      // ── Bước 3: Ghi log vào bảng pdf_exports (local + Supabase) ──
      final exportRecord = await _invoiceRepo.savePdfExport(
        companyId: companyId,
        exportedBy: exportedBy,
        invoiceId: invoice.id,
        exportType: exportType,
        filePath: filePath,
      );

      return exportRecord;
    } catch (e) {
      debugPrint('PdfExportService.exportInvoice failed: $e');
      return null;
    }
  }

  /// Tạo nội dung hóa đơn dạng văn bản (mô phỏng PDF layout)
  String _buildInvoiceContent(InvoiceModel invoice) {
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFmt = DateFormat('dd/MM/yyyy');
    final now = dateFmt.format(DateTime.now());

    final buffer = StringBuffer();
    buffer.writeln('=' * 60);
    buffer.writeln('                   HÓA ĐƠN ĐIỆN TỬ');
    buffer.writeln('=' * 60);
    buffer.writeln('');
    buffer.writeln('Ngày xuất báo cáo  : $now');
    buffer.writeln('Mã hóa đơn         : ${invoice.invoiceNumber ?? invoice.id.substring(0, 8).toUpperCase()}');
    buffer.writeln('');
    buffer.writeln('─' * 60);
    buffer.writeln('THÔNG TIN NHÀ CUNG CẤP');
    buffer.writeln('─' * 60);
    buffer.writeln('Tên đơn vị         : ${invoice.supplierName ?? 'Chưa cập nhật'}');
    buffer.writeln('Mã số thuế         : ${invoice.supplierTaxCode ?? 'Chưa cập nhật'}');
    buffer.writeln('Ngày hóa đơn       : ${invoice.invoiceDate != null ? dateFmt.format(invoice.invoiceDate!) : 'Chưa cập nhật'}');
    buffer.writeln('');
    buffer.writeln('─' * 60);
    buffer.writeln('CHI TIẾT THANH TOÁN');
    buffer.writeln('─' * 60);
    buffer.writeln('Tiền trước thuế    : ${invoice.subtotal != null ? currencyFmt.format(invoice.subtotal) : 'Chưa cập nhật'}');
    buffer.writeln('Thuế suất VAT      : ${invoice.vatRate != null ? '${invoice.vatRate}%' : 'Chưa cập nhật'}');
    buffer.writeln('Tiền thuế VAT      : ${invoice.vatAmount != null ? currencyFmt.format(invoice.vatAmount) : 'Chưa cập nhật'}');
    buffer.writeln('─' * 30);
    buffer.writeln('TỔNG CỘNG          : ${invoice.totalAmount != null ? currencyFmt.format(invoice.totalAmount) : 'Chưa cập nhật'}');
    buffer.writeln('');
    buffer.writeln('─' * 60);
    buffer.writeln('Trạng thái quét    : ${_translateStatus(invoice.scanStatus)}');
    buffer.writeln('Tạo lúc            : ${DateFormat('dd/MM/yyyy HH:mm').format(invoice.createdAt)}');
    buffer.writeln('');
    buffer.writeln('=' * 60);
    buffer.writeln('   Được tạo bởi SmartFinance SME - Phần mềm kế toán SME');
    buffer.writeln('=' * 60);

    return buffer.toString();
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'scanning':
        return 'Đang quét';
      case 'processed':
        return 'Đã xử lý';
      case 'failed':
        return 'Thất bại';
      default:
        return status;
    }
  }

  /// Lưu nội dung file vào thư mục tài liệu của app
  Future<String> _saveToFile(String invoiceId, String content) async {
    Directory dir;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      dir = await getApplicationDocumentsDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final exportDir = Directory('${dir.path}/SmartFinance/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'invoice_${invoiceId.substring(0, 8)}_$timestamp.txt';
    final file = File('${exportDir.path}/$filename');

    await file.writeAsString(content, encoding: utf8);
    return file.path;
  }
}
