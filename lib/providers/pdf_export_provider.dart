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

final pdfExportProvider =
    AsyncNotifierProvider<PdfExportNotifier, PdfExportModel?>(() {
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
  Future<PdfExportModel?> exportInvoice(InvoiceModel invoice) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      final profile = await ref.read(currentUserProfileProvider.future);
      if (user == null || profile?.companyId == null) {
        throw StateError('Tài khoản chưa có hồ sơ doanh nghiệp.');
      }
      if (profile!.companyId != invoice.companyId) {
        throw StateError('Không thể xuất hóa đơn của doanh nghiệp khác.');
      }
      return _service.exportInvoice(
        invoice: invoice,
        companyId: invoice.companyId,
        exportedBy: user.id,
        exportType: 'invoice_pdf',
      );
    });

    if (state.hasError) {
      Error.throwWithStackTrace(state.error!, state.stackTrace!);
    }
    return state.value;
  }

  void reset() {
    state = const AsyncData(null);
  }
}
