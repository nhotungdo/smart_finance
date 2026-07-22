import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class VndCurrencyInputFormatter extends TextInputFormatter {
  VndCurrencyInputFormatter();

  static final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');

  static String format(int value) => _formatter.format(value);

  static int? tryParse(String? value) {
    final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    return digits.isEmpty ? null : int.tryParse(digits);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final value = tryParse(newValue.text);
    if (value == null) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
