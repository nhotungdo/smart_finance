import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:smart_finance/data/repositories/transaction_repository.dart';
import 'package:smart_finance/providers/auth_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

class TransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    final profile = await ref.watch(currentUserProfileProvider.future);
    return _fetchTransactionsFor(profile);
  }

  Future<List<TransactionModel>> _fetchTransactionsFor(
    UserModel? profile,
  ) async {
    final repo = ref.read(transactionRepositoryProvider);
    final companyId = profile?.companyId;
    if (profile == null || companyId == null) return [];
    return repo.getRecentTransactions(
      companyId: companyId,
      createdBy: profile.isAccountant ? profile.userId : null,
    );
  }

  void _invalidateTransactionViews({String? transactionId, String? invoiceId}) {
    ref.invalidateSelf();
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(managerTransactionsProvider);
    if (transactionId != null) {
      ref.invalidate(transactionDetailProvider(transactionId));
    }
    if (invoiceId != null) {
      ref.invalidate(linkedTransactionForInvoiceProvider(invoiceId));
    }
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
    _invalidateTransactionViews(invoiceId: invoiceId);
  }

  Future<void> deleteTransaction(String transactionId) async {
    await ref
        .read(transactionRepositoryProvider)
        .deleteTransaction(transactionId);
    _invalidateTransactionViews(transactionId: transactionId);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await ref
        .read(transactionRepositoryProvider)
        .updateTransaction(transaction);
    _invalidateTransactionViews(transactionId: transaction.transactionId);
  }

  Future<void> linkInvoiceToTransaction({
    required String transactionId,
    required String invoiceId,
  }) async {
    await ref
        .read(transactionRepositoryProvider)
        .linkInvoiceToTransaction(
          transactionId: transactionId,
          invoiceId: invoiceId,
        );
    _invalidateTransactionViews(
      transactionId: transactionId,
      invoiceId: invoiceId,
    );
  }

  Future<void> createTransactionFromInvoice({
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
      transactionType: invoice.invoiceType,
      transactionDate: invoice.invoiceDate ?? DateTime.now(),
      categoryId: categoryId,
      description:
          '${invoice.invoiceType == TransactionType.income ? 'Thu' : 'Chi'} hóa đơn ${invoice.invoiceNumber ?? invoice.id}',
      invoiceId: invoice.id,
    );
  }

  Future<void> reviewTransaction({
    required String transactionId,
    required ApprovalStatus decision,
    String? rejectionReason,
  }) async {
    final profile = await ref.read(currentUserProfileProvider.future);
    if (profile == null || !profile.isManager) {
      throw StateError('Chỉ quản lý mới được duyệt giao dịch.');
    }
    await ref
        .read(transactionRepositoryProvider)
        .reviewTransaction(
          transactionId: transactionId,
          managerId: profile.userId,
          decision: decision,
          rejectionReason: rejectionReason,
        );
    _invalidateTransactionViews(transactionId: transactionId);
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<TransactionModel>>(
      TransactionsNotifier.new,
    );

final allTransactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final profile = await ref.watch(currentUserProfileProvider.future);
  final companyId = profile?.companyId;
  if (companyId == null) return [];
  return ref
      .read(transactionRepositoryProvider)
      .getRecentTransactions(
        companyId: companyId,
        createdBy: profile!.isAccountant ? profile.userId : null,
        limit: null,
      );
});

final managerTransactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final profile = await ref.watch(currentUserProfileProvider.future);
  if (profile == null || !profile.isManager || profile.companyId == null) {
    return [];
  }
  return ref
      .read(transactionRepositoryProvider)
      .getRecentTransactions(companyId: profile.companyId, limit: null);
});

final pendingTransactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final transactions = await ref.watch(managerTransactionsProvider.future);
  return transactions
      .where((item) => item.approvalStatus == ApprovalStatus.pending)
      .toList();
});

final transactionDetailProvider = FutureProvider.autoDispose
    .family<TransactionModel?, String>((ref, transactionId) async {
      final profile = await ref.watch(currentUserProfileProvider.future);
      final companyId = profile?.companyId;
      if (companyId == null) return null;
      return ref
          .read(transactionRepositoryProvider)
          .getTransactionById(
            transactionId,
            companyId: companyId,
            createdBy: profile!.isAccountant ? profile.userId : null,
          );
    });

final linkedTransactionForInvoiceProvider = FutureProvider.autoDispose
    .family<TransactionModel?, String>((ref, invoiceId) async {
      return ref
          .read(transactionRepositoryProvider)
          .getActiveTransactionForInvoice(invoiceId);
    });
