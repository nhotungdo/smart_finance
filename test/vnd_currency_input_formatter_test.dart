import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/ui/formatters/vnd_currency_input_formatter.dart';

void main() {
  final formatter = VndCurrencyInputFormatter();

  test('formats VND input with a separator every three digits', () {
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '1200000'),
    );

    expect(result.text, '1.200.000');
    expect(result.selection.baseOffset, result.text.length);
  });

  test('parses formatted VND text back to an integer', () {
    expect(VndCurrencyInputFormatter.tryParse('1.200.000'), 1200000);
    expect(VndCurrencyInputFormatter.tryParse(''), isNull);
  });
}
