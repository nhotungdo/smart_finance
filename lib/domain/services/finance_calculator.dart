import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/data/models/invoice_model.dart';

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

  static VatBreakdown calculateVatFromTotal({
    required int total,
    required int vatRate,
  }) {
    if (total < 0) {
      throw ArgumentError.value(total, 'total', 'Không được âm');
    }
    if (vatRate != 8 && vatRate != 10) {
      throw ArgumentError.value(vatRate, 'vatRate', 'Chỉ chấp nhận 8 hoặc 10');
    }

    final subtotal = (total * 100 / (100 + vatRate)).round();
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
    for (final invoice in invoices.where((item) => item.invoiceType == type)) {
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
}
