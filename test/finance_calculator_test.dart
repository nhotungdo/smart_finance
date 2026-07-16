import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/domain/services/finance_calculator.dart';

void main() {
  TransactionModel transaction({
    required String id,
    required int amount,
    required TransactionType type,
    RecordStatus status = RecordStatus.active,
  }) {
    return TransactionModel(
      transactionId: id,
      amount: amount,
      transactionType: type,
      transactionDate: DateTime(2026, 7, 16),
      status: status,
    );
  }

  test('total income sums only active income transactions', () {
    final transactions = [
      transaction(
        id: 'income-1',
        amount: 1200000,
        type: TransactionType.income,
      ),
      transaction(id: 'income-2', amount: 800000, type: TransactionType.income),
      transaction(
        id: 'expense-1',
        amount: 300000,
        type: TransactionType.expense,
      ),
      transaction(
        id: 'deleted-income',
        amount: 5000000,
        type: TransactionType.income,
        status: RecordStatus.deleted,
      ),
    ];

    expect(FinanceCalculator.totalIncome(transactions), 2000000);
  });

  test('total expense sums only active expense transactions', () {
    final transactions = [
      transaction(
        id: 'expense-1',
        amount: 450000,
        type: TransactionType.expense,
      ),
      transaction(
        id: 'expense-2',
        amount: 550000,
        type: TransactionType.expense,
      ),
      transaction(
        id: 'income-1',
        amount: 9000000,
        type: TransactionType.income,
      ),
      transaction(
        id: 'deleted-expense',
        amount: 700000,
        type: TransactionType.expense,
        status: RecordStatus.deleted,
      ),
    ];

    expect(FinanceCalculator.totalExpense(transactions), 1000000);
  });

  test('VAT total uses integer VND for supported rates', () {
    final vat8 = FinanceCalculator.calculateVat(subtotal: 1000000, vatRate: 8);
    final vat10 = FinanceCalculator.calculateVat(
      subtotal: 1000000,
      vatRate: 10,
    );

    expect(vat8.vatAmount, 80000);
    expect(vat8.total, 1080000);
    expect(vat10.vatAmount, 100000);
    expect(vat10.total, 1100000);
  });
}
