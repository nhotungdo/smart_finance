import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/ocr_result_model.dart';

void main() {
  test('reads transaction type and category from mock OCR data', () {
    final result = OcrResultModel(
      id: 'ocr-1',
      invoiceId: 'invoice-1',
      rawMockData: jsonEncode({
        'transaction_type': 'INCOME',
        'category_name': 'Doanh thu bán hàng',
      }),
      scannedAt: DateTime(2026, 7, 22),
    );

    expect(result.extractedTransactionType, TransactionType.income);
    expect(result.extractedCategoryName, 'Doanh thu bán hàng');
  });

  test('ignores malformed mock OCR classification', () {
    final result = OcrResultModel(
      id: 'ocr-2',
      invoiceId: 'invoice-2',
      rawMockData: '{invalid-json',
      scannedAt: DateTime(2026, 7, 22),
    );

    expect(result.mockData, isEmpty);
    expect(result.extractedTransactionType, isNull);
    expect(result.extractedCategoryName, isNull);
  });
}
