import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/category_model.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/report_model.dart';

class TransactionTotals {
  const TransactionTotals({required this.income, required this.expense});

  final int income;
  final int expense;

  int get cashFlow => income - expense;
}

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

class InvoiceTotals {
  const InvoiceTotals({
    required this.subtotal,
    required this.vat,
    required this.total,
    required this.count,
  });

  final int subtotal;
  final int vat;
  final int total;
  final int count;
}

class FinanceCalculator {
  const FinanceCalculator._();

  static const _expenseColors = [
    '#3B82F6',
    '#10B981',
    '#F59E0B',
    '#EF4444',
    '#8B5CF6',
    '#6B7280',
    '#F97316',
    '#06B6D4',
  ];

  static TransactionTotals transactionTotals(
    Iterable<TransactionModel> transactions,
  ) {
    var income = 0;
    var expense = 0;
    for (final transaction in transactions) {
      if (transaction.status != RecordStatus.active ||
          transaction.approvalStatus != ApprovalStatus.approved) {
        continue;
      }
      switch (transaction.transactionType) {
        case TransactionType.income:
          income += transaction.amount;
          break;
        case TransactionType.expense:
          expense += transaction.amount;
          break;
      }
    }
    return TransactionTotals(income: income, expense: expense);
  }

  static int totalIncome(Iterable<TransactionModel> transactions) {
    return transactionTotals(transactions).income;
  }

  static int totalExpense(Iterable<TransactionModel> transactions) {
    return transactionTotals(transactions).expense;
  }

  static List<ExpenseAnalysisModel> expenseAnalysis({
    required Iterable<TransactionModel> transactions,
    required Iterable<CategoryModel> categories,
  }) {
    final categoriesById = <String, CategoryModel>{
      for (final category in categories)
        if (category.categoryType == TransactionType.expense)
          category.categoryId: category,
    };
    final buckets = <String, _ExpenseBucket>{};
    var totalExpense = 0;

    for (final transaction in transactions) {
      if (transaction.status != RecordStatus.active ||
          transaction.approvalStatus != ApprovalStatus.approved ||
          transaction.transactionType != TransactionType.expense) {
        continue;
      }

      totalExpense += transaction.amount;
      final category = categoriesById[transaction.categoryId];
      final rawName = category?.categoryName.trim();
      final categoryName = rawName == null || rawName.isEmpty
          ? 'Khác'
          : rawName;
      final key = categoryName.toLowerCase();
      final bucket = buckets.putIfAbsent(
        key,
        () => _ExpenseBucket(
          categoryId: category?.categoryId ?? 'uncategorized',
          categoryName: categoryName,
          colorCode: category?.colorCode,
        ),
      );
      bucket.amount += transaction.amount;
    }

    var colorIndex = 0;
    final result = buckets.values.map((bucket) {
      final color =
          bucket.colorCode ??
          (bucket.categoryId == 'uncategorized'
              ? '#6B7280'
              : _expenseColors[colorIndex % _expenseColors.length]);
      colorIndex++;
      return ExpenseAnalysisModel(
        categoryId: bucket.categoryId,
        categoryName: bucket.categoryName,
        colorCode: color,
        amount: bucket.amount,
        percentage: totalExpense == 0
            ? 0
            : (bucket.amount / totalExpense) * 100,
      );
    }).toList();

    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  static VatBreakdown calculateVat({
    required int subtotal,
    required int vatRate,
  }) {
    _validateVatInput(
      amount: subtotal,
      amountName: 'subtotal',
      vatRate: vatRate,
    );

    final vatAmount = _divideAndRound(subtotal * vatRate, 100);
    return VatBreakdown(
      subtotal: subtotal,
      vatRate: vatRate,
      vatAmount: vatAmount,
      total: subtotal + vatAmount,
    );
  }

  static VatBreakdown calculateVatFromTotal({
    required int total,
    required int vatRate,
  }) {
    _validateVatInput(amount: total, amountName: 'total', vatRate: vatRate);

    final subtotal = _divideAndRound(total * 100, 100 + vatRate);
    return VatBreakdown(
      subtotal: subtotal,
      vatRate: vatRate,
      vatAmount: total - subtotal,
      total: total,
    );
  }

  static InvoiceTotals invoiceTotals(
    Iterable<InvoiceModel> invoices,
    TransactionType type,
  ) {
    var subtotal = 0;
    var vat = 0;
    var total = 0;
    var count = 0;
    for (final invoice in invoices) {
      if (invoice.invoiceType != type) continue;
      subtotal += invoice.subtotal ?? 0;
      vat += invoice.vatAmount ?? 0;
      total += invoice.totalAmount ?? 0;
      count++;
    }
    return InvoiceTotals(
      subtotal: subtotal,
      vat: vat,
      total: total,
      count: count,
    );
  }

  static void _validateVatInput({
    required int amount,
    required String amountName,
    required int vatRate,
  }) {
    if (amount < 0) {
      throw ArgumentError.value(amount, amountName, 'Không được âm');
    }
    if (vatRate != 8 && vatRate != 10) {
      throw ArgumentError.value(vatRate, 'vatRate', 'Chỉ chấp nhận 8 hoặc 10');
    }
  }

  static int _divideAndRound(int numerator, int denominator) {
    return (numerator + denominator ~/ 2) ~/ denominator;
  }
}

class _ExpenseBucket {
  _ExpenseBucket({
    required this.categoryId,
    required this.categoryName,
    required this.colorCode,
  });

  final String categoryId;
  final String categoryName;
  final String? colorCode;
  int amount = 0;
}
