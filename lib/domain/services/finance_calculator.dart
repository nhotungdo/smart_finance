import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/transaction_model.dart';

class VatBreakdown {
  const VatBreakdown({
    required this.subtotal,
    required this.vatRate,
    required this.vatAmount,
    required this.total,
  });

  final int subtotal;
  final int vatRate;
  final int vatAmount;
  final int total;
}

class FinanceCalculator {
  const FinanceCalculator._();

  static int totalIncome(Iterable<TransactionModel> transactions) {
    return transactions
        .where(
          (transaction) =>
              transaction.status == RecordStatus.active &&
              transaction.transactionType == TransactionType.income,
        )
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  static int totalExpense(Iterable<TransactionModel> transactions) {
    return transactions
        .where(
          (transaction) =>
              transaction.status == RecordStatus.active &&
              transaction.transactionType == TransactionType.expense,
        )
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  static VatBreakdown calculateVat({
    required int subtotal,
    required int vatRate,
  }) {
    if (subtotal < 0) {
      throw ArgumentError.value(subtotal, 'subtotal', 'Không được âm');
    }
    if (vatRate != 8 && vatRate != 10) {
      throw ArgumentError.value(vatRate, 'vatRate', 'Chỉ chấp nhận 8 hoặc 10');
    }

    final vatAmount = (subtotal * vatRate / 100).round();
    return VatBreakdown(
      subtotal: subtotal,
      vatRate: vatRate,
      vatAmount: vatAmount,
      total: subtotal + vatAmount,
    );
  }
}
