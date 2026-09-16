import 'package:app_front_mobile/utils/input_formatters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the CNPJ/CEP/phone input masks. These are exactly the kind of
/// string-slicing logic that's easy to get subtly wrong (an off-by-one in a
/// substring cut point), and they had no test coverage at all.
void main() {
  TextEditingValue valueOf(String text) {
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }

  String format(TextInputFormatter formatter, String typed) {
    return formatter.formatEditUpdate(valueOf(''), valueOf(typed)).text;
  }

  group('CnpjAlphanumericInputFormatter', () {
    final formatter = CnpjAlphanumericInputFormatter();

    test('inserts dots, slash and dash as digits are typed', () {
      expect(format(formatter, '12345678000199'), '12.345.678/0001-99');
    });

    test('uppercases letters and strips characters outside [A-Z0-9]', () {
      expect(format(formatter, '12.abc-45!!'), '12.ABC.45');
    });

    test('truncates input beyond 14 characters', () {
      expect(format(formatter, '123456780001999999'), '12.345.678/0001-99');
    });
  });

  group('CepInputFormatter', () {
    final formatter = CepInputFormatter();

    test('keeps digits only up to the hyphen position', () {
      expect(format(formatter, '12345'), '12345');
    });

    test('inserts the hyphen after the 5th digit', () {
      expect(format(formatter, '12345678'), '12345-678');
    });

    test('strips non-digits and truncates beyond 8 digits', () {
      expect(format(formatter, '12.345-678999'), '12345-678');
    });
  });

  group('PhoneInputFormatter', () {
    final formatter = PhoneInputFormatter();

    test('opens the area code parenthesis', () {
      expect(format(formatter, '1'), '(1');
    });

    test('formats a partial number', () {
      expect(format(formatter, '119876'), '(11) 9876');
    });

    test('formats a full landline (10 digits)', () {
      expect(format(formatter, '1133334444'), '(11) 3333-4444');
    });

    test('formats a full mobile number (11 digits)', () {
      expect(format(formatter, '11987654321'), '(11) 98765-4321');
    });

    test('truncates beyond 11 digits', () {
      expect(format(formatter, '119876543219999'), '(11) 98765-4321');
    });
  });

  group('onlyAlphanumeric / onlyNumbers', () {
    test('onlyAlphanumeric uppercases and strips punctuation', () {
      expect(onlyAlphanumeric('ab-12.cd'), 'AB12CD');
    });

    test('onlyNumbers strips every non-digit', () {
      expect(onlyNumbers('(11) 98765-4321'), '11987654321');
    });
  });
}
