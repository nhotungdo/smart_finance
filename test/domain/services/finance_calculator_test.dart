import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/domain/services/finance_calculator.dart';

void main() {
  group('FinanceCalculator Logic Tests', () {
    // 1. Test tính Tổng Thu
    test('totalIncome should calculate the sum of active income transactions', () {
      final transactions = [
        TransactionModel(
          transactionId: '1',
          companyId: 'comp1',
          amount: 1500000,
          transactionType: TransactionType.income,
          status: RecordStatus.active,
          transactionDate: DateTime.now(),
        ),
        TransactionModel(
          transactionId: '2',
          companyId: 'comp1',
          amount: 500000,
          transactionType: TransactionType.income,
          status: RecordStatus.deleted, // Giao dịch đã xóa, không được tính
          transactionDate: DateTime.now(),
        ),
        TransactionModel(
          transactionId: '3',
          companyId: 'comp1',
          amount: 2000000,
          transactionType: TransactionType.expense, // Giao dịch chi, không được tính vào Thu
          status: RecordStatus.active,
          transactionDate: DateTime.now(),
        ),
        TransactionModel(
          transactionId: '4',
          companyId: 'comp1',
          amount: 3000000,
          transactionType: TransactionType.income,
          status: RecordStatus.active,
          transactionDate: DateTime.now(),
        ),
      ];

      final totalIncome = FinanceCalculator.totalIncome(transactions);

      // Kết quả mong muốn: 1.500.000 + 3.000.000 = 4.500.000
      expect(totalIncome, 4500000);
    });

    // 2. Test tính Tổng Chi
    test('totalExpense should calculate the sum of active expense transactions', () {
      final transactions = [
        TransactionModel(
          transactionId: '1',
          amount: 500000,
          transactionType: TransactionType.expense,
          status: RecordStatus.active,
          transactionDate: DateTime.now(),
        ),
        TransactionModel(
          transactionId: '2',
          amount: 250000,
          transactionType: TransactionType.expense,
          status: RecordStatus.active,
          transactionDate: DateTime.now(),
        ),
        TransactionModel(
          transactionId: '3',
          amount: 100000,
          transactionType: TransactionType.expense,
          status: RecordStatus.deleted, // Giao dịch đã xóa, bỏ qua
          transactionDate: DateTime.now(),
        ),
      ];

      final totalExpense = FinanceCalculator.totalExpense(transactions);

      // Kết quả mong muốn: 500.000 + 250.000 = 750.000
      expect(totalExpense, 750000);
    });

    // 3. Test tính Thuế VAT từ Subtotal
    test('calculateVat should calculate correct VAT amount and total amount', () {
      // Test case 1: VAT 10%
      final vat10 = FinanceCalculator.calculateVat(subtotal: 1000000, vatRate: 10);
      expect(vat10.vatAmount, 100000); // 10% của 1tr = 100k
      expect(vat10.total, 1100000); // Tổng = 1tr1

      // Test case 2: VAT 8% (Làm tròn số)
      final vat8 = FinanceCalculator.calculateVat(subtotal: 50000, vatRate: 8);
      expect(vat8.vatAmount, 4000); // 8% của 50k = 4k
      expect(vat8.total, 54000); // Tổng = 54k

      // Test case 3: Ném ra lỗi ArgumentError nếu VAT rate không hợp lệ (không phải 8 hoặc 10)
      expect(
        () => FinanceCalculator.calculateVat(subtotal: 100000, vatRate: 5),
        throwsArgumentError,
      );

      // Test case 4: Ném ra lỗi ArgumentError nếu Subtotal âm
      expect(
        () => FinanceCalculator.calculateVat(subtotal: -50000, vatRate: 10),
        throwsArgumentError,
      );
    });

    // 4. Test tính ngược Thuế VAT từ Tổng Tiền
    test('calculateVatFromTotal should extract correct Subtotal and VAT amount', () {
      // Nếu Tổng tiền là 1.100.000 và VAT 10% thì Subtotal phải là 1.000.000 và VAT là 100.000
      final extractedVat = FinanceCalculator.calculateVatFromTotal(total: 1100000, vatRate: 10);
      
      expect(extractedVat.subtotal, 1000000);
      expect(extractedVat.vatAmount, 100000);
      expect(extractedVat.total, 1100000);
    });
  });
}
