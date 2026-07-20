import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/ocr_result_model.dart';
import 'package:smart_finance/data/repositories/invoice_repository.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository();
});

final invoicesProvider =
    AsyncNotifierProvider<InvoicesNotifier, List<InvoiceModel>>(() {
      return InvoicesNotifier();
    });

class InvoiceSummary {
  const InvoiceSummary({
    required this.totalValue,
    required this.pendingValue,
    required this.invoiceCount,
    required this.pendingCount,
  });

  final int totalValue;
  final int pendingValue;
  final int invoiceCount;
  final int pendingCount;

  factory InvoiceSummary.fromInvoices(List<InvoiceModel> invoices) {
    var totalValue = 0;
    var pendingValue = 0;
    var pendingCount = 0;

    for (final invoice in invoices) {
      final amount = invoice.totalAmount ?? 0;
      final safeAmount = amount > 0 ? amount : 0;
      totalValue += safeAmount;

      if (invoice.scanStatus != InvoiceScanStatus.scanned) {
        pendingValue += safeAmount;
        pendingCount++;
      }
    }

    return InvoiceSummary(
      totalValue: totalValue,
      pendingValue: pendingValue,
      invoiceCount: invoices.length,
      pendingCount: pendingCount,
    );
  }
}

final invoiceSummaryProvider = Provider<InvoiceSummary>((ref) {
  final invoices = ref.watch(invoicesProvider).value ?? const <InvoiceModel>[];
  return InvoiceSummary.fromInvoices(invoices);
});

class InvoicesNotifier extends AsyncNotifier<List<InvoiceModel>> {
  InvoiceRepository get _repository => ref.read(invoiceRepositoryProvider);

  @override
  FutureOr<List<InvoiceModel>> build() async {
    return _fetchInvoices();
  }

  Future<List<InvoiceModel>> _fetchInvoices() async {
    final profile = await ref.read(currentUserProfileProvider.future);
    final companyId = profile?.companyId;
    if (companyId == null) return [];
    return _repository.getInvoices(companyId);
  }

  /// Tạo hóa đơn mới và lưu lên cả local + Supabase
  Future<String> createInvoice({
    TransactionType invoiceType = TransactionType.expense,
    String? supplierName,
    String? supplierTaxCode,
    String? invoiceNumber,
    DateTime? invoiceDate,
    int? subtotal,
    int? vatRate,
    int? vatAmount,
    int? totalAmount,
    String? imagePath,
  }) async {
    final user = ref.read(currentUserProvider);
    final profile = await ref.read(currentUserProfileProvider.future);
    final companyId = profile?.companyId;
    if (user == null || companyId == null) {
      throw StateError('Tài khoản chưa có hồ sơ doanh nghiệp.');
    }
    final now = DateTime.now();

    final invoice = InvoiceModel(
      id: const Uuid().v4(),
      companyId: companyId,
      uploadedBy: user.id,
      invoiceType: invoiceType,
      supplierName: supplierName,
      supplierTaxCode: supplierTaxCode,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      subtotal: subtotal,
      vatRate: vatRate,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      imagePath: imagePath,
      scanStatus: InvoiceScanStatus.notScanned,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    state = const AsyncValue.loading();
    String invoiceId = '';
    state = await AsyncValue.guard(() async {
      invoiceId = await _repository.addInvoice(invoice);
      return _fetchInvoices();
    });
    return invoiceId;
  }

  Future<void> addInvoice(InvoiceModel invoice) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.addInvoice(invoice);
      return _fetchInvoices();
    });
  }

  Future<void> saveReviewedInvoice({
    required InvoiceModel invoice,
    Uint8List? imageBytes,
    String? imageFileName,
    String? localImagePath,
    OcrResultModel? ocrResult,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.addInvoice(invoice);

      var savedInvoice = invoice;
      if (imageBytes != null && imageFileName != null) {
        final imageUrl = await _repository.uploadInvoiceImage(
          invoiceId: invoice.id,
          companyId: invoice.companyId,
          bytes: imageBytes,
          fileName: imageFileName,
        );
        savedInvoice = invoice.copyWith(
          imagePath: imageUrl ?? localImagePath,
          updatedAt: DateTime.now(),
        );
        await _repository.updateInvoice(savedInvoice);
      }

      if (ocrResult != null) {
        await _repository.saveOcrResult(
          ocrResult.copyWith(invoiceId: savedInvoice.id),
        );
      }

      return _fetchInvoices();
    });

    if (state.hasError) {
      Error.throwWithStackTrace(state.error!, state.stackTrace!);
    }
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateInvoice(invoice);
      return _fetchInvoices();
    });
  }

  Future<void> deleteInvoice(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteInvoice(id);
      return _fetchInvoices();
    });
  }

  void refresh() {
    ref.invalidateSelf();
  }
}
