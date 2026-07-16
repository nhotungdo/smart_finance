import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/repositories/invoice_repository.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository();
});

final invoicesProvider = AsyncNotifierProvider<InvoicesNotifier, List<InvoiceModel>>(() {
  return InvoicesNotifier();
});

class InvoicesNotifier extends AsyncNotifier<List<InvoiceModel>> {
  late final InvoiceRepository _repository;

  @override
  FutureOr<List<InvoiceModel>> build() async {
    _repository = ref.read(invoiceRepositoryProvider);
    return _fetchInvoices();
  }

  Future<List<InvoiceModel>> _fetchInvoices() async {
    final user = ref.read(currentUserProvider);
    // Dùng user.id tạm thời làm company_id (sẽ cập nhật sau khi có profile đầy đủ)
    final companyId = user?.id ?? '';
    if (companyId.isEmpty) return [];
    return await _repository.getInvoices(companyId);
  }

  /// Tạo hóa đơn mới và lưu lên cả local + Supabase
  Future<String> createInvoice({
    String? supplierName,
    String? supplierTaxCode,
    String? invoiceNumber,
    DateTime? invoiceDate,
    double? subtotal,
    double? vatRate,
    double? vatAmount,
    double? totalAmount,
    String? imagePath,
  }) async {
    final user = ref.read(currentUserProvider);
    final companyId = user?.id ?? '';
    final now = DateTime.now();

    final invoice = InvoiceModel(
      id: const Uuid().v4(),
      companyId: companyId,
      uploadedBy: user?.id ?? '',
      supplierName: supplierName,
      supplierTaxCode: supplierTaxCode,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      subtotal: subtotal,
      vatRate: vatRate,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      imagePath: imagePath,
      scanStatus: 'pending',
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
