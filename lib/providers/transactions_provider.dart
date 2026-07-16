import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/data/repositories/transaction_repository.dart';
import 'package:smart_finance/providers/auth_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

class TransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    return _fetchTransactions();
  }

  Future<List<TransactionModel>> _fetchTransactions() async {
    final repo = ref.read(transactionRepositoryProvider);
    final profile = await ref.read(currentUserProfileProvider.future);
    final companyId = profile?.companyId;
    if (companyId == null) return [];
    return repo.getRecentTransactions(companyId: companyId);
  }

  Future<void> addTransaction({
    required int amount,
    required TransactionType transactionType,
    required DateTime transactionDate,
    String? categoryId,
    String? description,
    String? receiptImagePath,
    String? invoiceId,
  }) async {
    final profile = await ref.read(currentUserProfileProvider.future);
    final companyId = profile?.companyId;
    if (profile == null || companyId == null) {
      throw StateError('Tài khoản chưa có hồ sơ doanh nghiệp.');
    }
    await ref
        .read(transactionRepositoryProvider)
        .addTransaction(
          amount: amount,
          transactionType: transactionType,
          transactionDate: transactionDate,
          categoryId: categoryId,
          description: description,
          receiptImagePath: receiptImagePath,
          invoiceId: invoiceId,
          companyId: companyId,
          createdBy: profile.userId,
        );
    // Refresh list
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchTransactions);
  }

  Future<void> deleteTransaction(String transactionId) async {
    await ref
        .read(transactionRepositoryProvider)
        .deleteTransaction(transactionId);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchTransactions);
  }

  Future<void> createExpenseFromInvoice({
    required InvoiceModel invoice,
    required String categoryId,
  }) async {
    final amount = invoice.totalAmount;
    if (amount == null || amount <= 0) {
      throw StateError('Hóa đơn chưa có tổng tiền hợp lệ.');
    }

    final repo = ref.read(transactionRepositoryProvider);
    if (await repo.hasActiveTransactionForInvoice(invoice.id)) {
      throw StateError('Hóa đơn này đã được tạo thành giao dịch.');
    }

    await addTransaction(
      amount: amount,
      transactionType: TransactionType.expense,
      transactionDate: invoice.invoiceDate ?? DateTime.now(),
      categoryId: categoryId,
      description: 'Chi phí hóa đơn ${invoice.invoiceNumber ?? invoice.id}',
      invoiceId: invoice.id,
    );
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<TransactionModel>>(
      TransactionsNotifier.new,
    );
