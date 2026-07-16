import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/ocr_result_model.dart';
import 'package:smart_finance/data/repositories/invoice_repository.dart';
import 'package:smart_finance/domain/services/finance_calculator.dart';

class OcrService {
  final InvoiceRepository _invoiceRepo;

  OcrService(this._invoiceRepo);

  /// Toàn bộ luồng Smart Scan:
  /// 1. Upload ảnh lên Supabase Storage
  /// 2. Cập nhật invoice với đường dẫn ảnh & trạng thái "scanning"
  /// 3. Mock OCR processing (thay bằng AI API thực tế sau)
  /// 4. Lưu kết quả OCR vào bảng ocr_results (local + Supabase)
  /// 5. Cập nhật invoice với dữ liệu bóc tách & trạng thái "processed"
  Future<OcrResultModel> scanAndProcess({
    required InvoiceModel invoice,
    required Uint8List imageBytes,
    required String imageFileName,
    String? localImagePath,
  }) async {
    // ── Bước 1: Upload ảnh lên Supabase Storage ──
    debugPrint('OcrService: [1/4] Uploading image to Supabase Storage...');
    final imageUrl = await _invoiceRepo.uploadInvoiceImage(
      invoiceId: invoice.id,
      companyId: invoice.companyId,
      bytes: imageBytes,
      fileName: imageFileName,
    );

    // ── Bước 2: Cập nhật invoice với ảnh và trạng thái scanning ──
    final updatedInvoice = invoice.copyWith(
      imagePath: imageUrl ?? localImagePath,
      scanStatus: InvoiceScanStatus.scanning,
    );
    await _invoiceRepo.updateInvoice(updatedInvoice);
    debugPrint('OcrService: [2/4] Invoice updated with image path.');

    // ── Bước 3: Gọi OCR Engine (Mock với AI-like delay) ──
    debugPrint('OcrService: [3/4] Processing image with OCR engine...');
    final ocrResult = await _mockOcrExtract(invoice.id);

    // ── Bước 4: Lưu kết quả OCR ──
    await _invoiceRepo.saveOcrResult(ocrResult);
    debugPrint('OcrService: [4/4] OCR result saved.');

    // ── Bước 5: Cập nhật invoice với dữ liệu bóc tách được ──
    final processedInvoice = updatedInvoice.copyWith(
      supplierName: ocrResult.extractedSupplierName,
      supplierTaxCode: ocrResult.extractedTaxCode,
      totalAmount: ocrResult.extractedAmount,
      scanStatus: InvoiceScanStatus.scanned,
    );
    await _invoiceRepo.updateInvoice(processedInvoice);

    return ocrResult;
  }

  /// Mock OCR - Giả lập AI bóc tách dữ liệu từ ảnh hóa đơn
  /// TODO: Thay thế bằng API thực tế (Google Vision, Gemini, Azure OCR...)
  Future<OcrResultModel> _mockOcrExtract(String invoiceId) async {
    // Giữ đúng thời lượng demo trong yêu cầu đề bài.
    await Future.delayed(const Duration(seconds: 2));

    // Dữ liệu mẫu giả lập OCR cho nhiều nhà cung cấp
    final mockVendors = [
      {
        'name': 'Công ty TNHH Giải Pháp Số Việt Nam',
        'tax': '0100111222',
        'subtotal': 3500000,
      },
      {
        'name': 'Tổng Công ty Cổ phần FPT',
        'tax': '0101248141',
        'subtotal': 12000000,
      },
      {
        'name': 'Công ty CP Dịch Vụ Thương Mại Hà Nội',
        'tax': '0312456789',
        'subtotal': 7000000,
      },
      {
        'name': 'Công ty TNHH SmartFinance AI',
        'tax': '0123456789',
        'subtotal': 2500000,
      },
    ];

    final mock = mockVendors[Random().nextInt(mockVendors.length)];
    const vatRate = 10;
    final vat = FinanceCalculator.calculateVat(
      subtotal: mock['subtotal'] as int,
      vatRate: vatRate,
    );

    return OcrResultModel(
      id: const Uuid().v4(),
      invoiceId: invoiceId,
      extractedSupplierName: mock['name'] as String,
      extractedTaxCode: mock['tax'] as String,
      extractedAmount: vat.total,
      rawMockData: jsonEncode({
        'supplier': mock['name'],
        'tax_code': mock['tax'],
        'subtotal': vat.subtotal,
        'vat_rate': vat.vatRate,
        'vat_amount': vat.vatAmount,
        'total_amount': vat.total,
        'items': [
          {
            'description': 'Dịch vụ theo hợp đồng',
            'quantity': 1,
            'unit_price': vat.subtotal,
          },
        ],
        'ocr_confidence': '${90 + Random().nextInt(10)}%',
        'processed_at': DateTime.now().toIso8601String(),
      }),
      status: InvoiceScanStatus.scanned,
      scannedAt: DateTime.now(),
    );
  }

  /// Hàm OCR đơn giản - Không upload ảnh, chỉ mock extract (dùng cho testing)
  Future<OcrResultModel> extractInvoiceData(
    String imagePath,
    String tempInvoiceId,
  ) async {
    return _mockOcrExtract(tempInvoiceId);
  }
}
