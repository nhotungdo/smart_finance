import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/models/ocr_result_model.dart';
import 'package:smart_finance/data/services/ocr_service.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/providers/invoices_provider.dart';

final ocrServiceProvider = Provider<OcrService>((ref) {
  final invoiceRepo = ref.read(invoiceRepositoryProvider);
  return OcrService(invoiceRepo);
});

final ocrProvider = AsyncNotifierProvider<OcrNotifier, OcrResultModel?>(() {
  return OcrNotifier();
});

class OcrNotifier extends AsyncNotifier<OcrResultModel?> {
  late final OcrService _service;

  @override
  FutureOr<OcrResultModel?> build() {
    _service = ref.read(ocrServiceProvider);
    return null; // Initial state: not scanned
  }

  /// Toàn bộ luồng Smart Scan:
  /// Upload ảnh → OCR Extract → Lưu kết quả → Cập nhật invoice
  Future<void> scanInvoice({
    required InvoiceModel invoice,
    required String localImagePath,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _service.scanAndProcess(
        invoice: invoice,
        localImagePath: localImagePath,
      );
      // Refresh invoice list to show updated scan status
      ref.invalidate(invoicesProvider);
      return result;
    });
  }

  /// Scan đơn giản - chỉ mock extract (dùng cho test/demo)
  Future<void> scanImage(String imagePath, String tempInvoiceId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _service.extractInvoiceData(imagePath, tempInvoiceId);
    });
  }

  void reset() {
    state = const AsyncData(null);
  }
}
