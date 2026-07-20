import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/pdf_export_model.dart';
import 'package:smart_finance/data/repositories/invoice_repository.dart';
import 'package:smart_finance/data/services/pdf_file_saver.dart';

class PdfExportService {
  PdfExportService(this._invoiceRepo);

  final InvoiceRepository _invoiceRepo;

  Future<PdfExportModel?> exportInvoice({
    required InvoiceModel invoice,
    required String companyId,
    required String exportedBy,
    String exportType = 'invoice_pdf',
  }) async {
    final bytes = await buildInvoicePdf(invoice);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final shortId = invoice.id.length <= 8
        ? invoice.id
        : invoice.id.substring(0, 8);
    final fileName = 'invoice_${shortId}_$timestamp.pdf';

    final accepted = await Printing.layoutPdf(
      name: fileName,
      onLayout: (_) async => bytes,
    );
    if (!accepted) return null;

    final filePath = await savePdfBytes(bytes, fileName);
    debugPrint('PdfExportService: Saved PDF to $filePath');

    return _invoiceRepo.savePdfExport(
      companyId: companyId,
      exportedBy: exportedBy,
      invoiceId: invoice.id,
      exportType: exportType,
      filePath: filePath,
    );
  }

  Future<Uint8List> buildInvoicePdf(InvoiceModel invoice) async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );

    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final date = DateFormat('dd/MM/yyyy');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'SmartFinance SME | ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (_) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SMARTFINANCE SME',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Quản lý dòng tiền doanh nghiệp'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'HÓA ĐƠN',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    invoice.invoiceNumber ??
                        invoice.id.substring(
                          0,
                          invoice.id.length < 8 ? invoice.id.length : 8,
                        ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 28),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _labelValue(
                  'Nhà cung cấp',
                  invoice.supplierName ?? 'Chưa cập nhật',
                ),
                _labelValue(
                  'Mã số thuế',
                  invoice.supplierTaxCode ?? 'Chưa cập nhật',
                ),
                _labelValue(
                  'Ngày hóa đơn',
                  invoice.invoiceDate == null
                      ? 'Chưa cập nhật'
                      : date.format(invoice.invoiceDate!),
                ),
                _labelValue(
                  'Trạng thái quét',
                  _translateStatus(invoice.scanStatus),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 28),
          pw.Text(
            'CHI TIẾT THANH TOÁN',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo700,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              _amountRow(
                'Tiền trước thuế',
                currency.format(invoice.subtotal ?? 0),
              ),
              _amountRow('Thuế suất VAT', '${invoice.vatRate ?? 0}%'),
              _amountRow(
                'Tiền thuế VAT',
                currency.format(invoice.vatAmount ?? 0),
              ),
              _amountRow(
                'TỔNG CỘNG',
                currency.format(invoice.totalAmount ?? 0),
                emphasized: true,
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _labelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.TableRow _amountRow(
    String label,
    String value, {
    bool emphasized = false,
  }) {
    final style = pw.TextStyle(
      fontWeight: emphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: emphasized ? 13 : 11,
    );
    return pw.TableRow(
      decoration: emphasized
          ? const pw.BoxDecoration(color: PdfColors.indigo50)
          : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(label, style: style),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(value, style: style),
          ),
        ),
      ],
    );
  }

  static String _translateStatus(InvoiceScanStatus status) {
    switch (status) {
      case InvoiceScanStatus.notScanned:
        return 'Chưa quét';
      case InvoiceScanStatus.scanning:
        return 'Đang quét';
      case InvoiceScanStatus.scanned:
        return 'Đã quét';
      case InvoiceScanStatus.error:
        return 'Lỗi';
    }
  }
}
