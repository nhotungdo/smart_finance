import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/models/pdf_export_model.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/services/pdf_export_service.dart';
import 'package:smart_finance/providers/invoices_provider.dart';
import 'package:smart_finance/providers/auth_provider.dart';

final pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  final invoiceRepo = ref.read(invoiceRepositoryProvider);
  return PdfExportService(invoiceRepo);
});

final pdfExportProvider = AsyncNotifierProvider<PdfExportNotifier, PdfExportModel?>(() {
  return PdfExportNotifier();
});

class PdfExportNotifier extends AsyncNotifier<PdfExportModel?> {
  late final PdfExportService _service;

  @override
  FutureOr<PdfExportModel?> build() {
    _service = ref.read(pdfExportServiceProvider);
    return null;
  }

  /// Xuất hóa đơn ra file và ghi log vào bảng pdf_exports
  Future<void> exportInvoice(InvoiceModel invoice) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      return await _service.exportInvoice(
        invoice: invoice,
        companyId: invoice.companyId,
        exportedBy: user?.id ?? 'unknown',
        exportType: 'invoice_pdf',
      );
    });
  }

  void reset() {
    state = const AsyncData(null);
  }
}
