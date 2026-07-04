import 'package:flutter/services.dart';

class DigitsMaskTextInputFormatter extends TextInputFormatter {
  DigitsMaskTextInputFormatter(this.mask);

  final String mask;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    var digitIndex = 0;

    for (final char in mask.split('')) {
      if (digitIndex >= digits.length) {
        break;
      }

      if (char == '#') {
        buffer.write(digits[digitIndex]);
        digitIndex++;
      } else {
        buffer.write(char);
      }
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
