import 'package:flutter/services.dart';

class CnpjAlphanumericInputFormatter extends TextInputFormatter {
  static final RegExp _allowedCharacters = RegExp(r'[A-Z0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleanValue = newValue.text
        .toUpperCase()
        .split('')
        .where((character) => _allowedCharacters.hasMatch(character))
        .join();

    final limitedValue = cleanValue.length > 14
        ? cleanValue.substring(0, 14)
        : cleanValue;

    final formattedValue = _formatCnpj(limitedValue);

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }

  String _formatCnpj(String value) {
    final buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      if (i == 2 || i == 5) {
        buffer.write('.');
      }

      if (i == 8) {
        buffer.write('/');
      }

      if (i == 12) {
        buffer.write('-');
      }

      buffer.write(value[i]);
    }

    return buffer.toString();
  }
}

class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleanValue = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    final limitedValue = cleanValue.length > 8
        ? cleanValue.substring(0, 8)
        : cleanValue;

    final formattedValue = _formatCep(limitedValue);

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }

  String _formatCep(String value) {
    if (value.length <= 5) {
      return value;
    }

    return '${value.substring(0, 5)}-${value.substring(5)}';
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = onlyNumbers(newValue.text);
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;

    final formatted = _formatPhone(limited);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatPhone(String value) {
    if (value.isEmpty) return value;

    if (value.length <= 2) {
      return '($value';
    }

    if (value.length <= 6) {
      return '(${value.substring(0, 2)}) ${value.substring(2)}';
    }

    if (value.length <= 10) {
      return '(${value.substring(0, 2)}) ${value.substring(2, 6)}-${value.substring(6)}';
    }

    return '(${value.substring(0, 2)}) ${value.substring(2, 7)}-${value.substring(7)}';
  }
}

String onlyAlphanumeric(String value) {
  return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

String onlyNumbers(String value) {
  return value.replaceAll(RegExp(r'[^0-9]'), '');
}
