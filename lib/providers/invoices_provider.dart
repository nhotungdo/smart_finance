import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/ocr_result_model.dart';
import 'package:smart_finance/data/models/user_model.dart';
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
    final profile = await ref.watch(currentUserProfileProvider.future);
    return _fetchInvoicesFor(profile);
  }

  Future<List<InvoiceModel>> _fetchInvoices() async {
    final profile = await ref.read(currentUserProfileProvider.future);
    return _fetchInvoicesFor(profile);
  }

  Future<List<InvoiceModel>> _fetchInvoicesFor(UserModel? profile) async {
    final companyId = profile?.companyId;
    if (companyId == null) return [];
    return _repository.getInvoices(
      companyId,
      createdBy: profile!.isAccountant ? profile.userId : null,
    );
  }

  Future<T> _runMutation<T>(Future<T> Function() mutation) async {
    try {
      final result = await mutation();
      state = AsyncData(await _fetchInvoices());
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
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
      createdBy: user.id,
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

    return _runMutation(() => _repository.addInvoice(invoice));
  }

  Future<void> addInvoice(InvoiceModel invoice) async {
    await _runMutation(() async {
      await _repository.addInvoice(invoice);
    });
  }

  Future<void> saveReviewedInvoice({
    required InvoiceModel invoice,
    Uint8List? imageBytes,
    String? imageFileName,
    String? localImagePath,
    OcrResultModel? ocrResult,
  }) async {
    await _runMutation(() async {
      var inserted = false;
      try {
        await _repository.addInvoice(invoice);
        inserted = true;

        var savedInvoice = invoice;
        if (imageBytes != null && imageFileName != null) {
          await _repository.cacheInvoiceImage(
            invoiceId: invoice.id,
            companyId: invoice.companyId,
            bytes: imageBytes,
            fileName: imageFileName,
          );
          savedInvoice = invoice.copyWith(
            imagePath: localImagePath ?? invoice.imagePath,
            updatedAt: DateTime.now(),
          );
          await _repository.updateInvoice(savedInvoice);
        }

        if (ocrResult != null) {
          await _repository.saveOcrResult(
            ocrResult.copyWith(invoiceId: savedInvoice.id),
          );
        }
      } catch (_) {
        if (inserted) {
          try {
            await _repository.deleteInvoice(invoice.id);
          } catch (_) {
            // Preserve the original save error.
          }
        }
        rethrow;
      }
    });
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    await _runMutation(() async {
      await _repository.updateInvoice(invoice);
    });
  }

  Future<void> deleteInvoice(String id) async {
    await _runMutation(() async {
      await _repository.deleteInvoice(id);
    });
  }

  void refresh() {
    ref.invalidateSelf();
  }
}
