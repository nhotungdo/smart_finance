import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/data/repositories/transaction_repository.dart';

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
    return repo.getRecentTransactions();
  }

  Future<void> addTransaction({
    required double amount,
    required String transactionType,
    required DateTime transactionDate,
    String? categoryId,
    String? description,
  }) async {
    await ref.read(transactionRepositoryProvider).addTransaction(
      amount: amount,
      transactionType: transactionType,
      transactionDate: transactionDate,
      categoryId: categoryId,
      description: description,
    );
    // Refresh list
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchTransactions);
  }

  Future<void> deleteTransaction(String transactionId) async {
    await ref.read(transactionRepositoryProvider).deleteTransaction(transactionId);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchTransactions);
  }
}

final transactionsProvider = AsyncNotifierProvider<TransactionsNotifier, List<TransactionModel>>(TransactionsNotifier.new);
