import 'package:app_front_mobile/pages/availability_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

/// Covers the pure time/day helpers extracted from AvailabilityFormPage's
/// private State methods, plus the one submit-validation path reachable
/// without mocking the page's network dependencies: submitting the form
/// empty. Note the professional/start-time/end-time null checks inside
/// _submit() are effectively unreachable today -- the form's own field
/// validators (exercised below) already fail validate() first and stop
/// submission before those checks ever run.
void main() {
  group('parseApiTime', () {
    test('parses a valid HH:mm value', () {
      expect(parseApiTime('08:30'), const TimeOfDay(hour: 8, minute: 30));
    });

    test('parses a HH:mm:ss value, ignoring seconds', () {
      expect(parseApiTime('18:00:00'), const TimeOfDay(hour: 18, minute: 0));
    });

    test('returns null when there is no colon', () {
      expect(parseApiTime('0830'), isNull);
    });

    test('returns null when hour or minute is not numeric', () {
      expect(parseApiTime('ab:cd'), isNull);
    });
  });

  group('formatTime', () {
    test('zero-pads hour and minute', () {
      expect(formatTime(const TimeOfDay(hour: 8, minute: 5)), '08:05');
    });

    test('does not pad already two-digit values', () {
      expect(formatTime(const TimeOfDay(hour: 18, minute: 30)), '18:30');
    });
  });

  group('timeToApi', () {
    test('appends ":00" seconds to the formatted time', () {
      expect(timeToApi(const TimeOfDay(hour: 9, minute: 0)), '09:00:00');
    });
  });

  group('dayLabel', () {
    test('maps every known day code to its PT-BR label', () {
      expect(dayLabel('MONDAY'), 'Segunda-feira');
      expect(dayLabel('TUESDAY'), 'Terca-feira');
      expect(dayLabel('WEDNESDAY'), 'Quarta-feira');
      expect(dayLabel('THURSDAY'), 'Quinta-feira');
      expect(dayLabel('FRIDAY'), 'Sexta-feira');
      expect(dayLabel('SATURDAY'), 'Sabado');
      expect(dayLabel('SUNDAY'), 'Domingo');
    });

    test('returns the raw value for an unknown day code', () {
      expect(dayLabel('HOLIDAY'), 'HOLIDAY');
    });
  });

  group('isEndAfterStart', () {
    test('true when end is strictly after start', () {
      expect(
        isEndAfterStart(
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 18, minute: 0),
        ),
        isTrue,
      );
    });

    test('false when end equals start', () {
      const time = TimeOfDay(hour: 8, minute: 0);
      expect(isEndAfterStart(time, time), isFalse);
    });

    test('false when end is before start', () {
      expect(
        isEndAfterStart(
          const TimeOfDay(hour: 18, minute: 0),
          const TimeOfDay(hour: 8, minute: 0),
        ),
        isFalse,
      );
    });

    test('false when either value is missing', () {
      expect(isEndAfterStart(null, const TimeOfDay(hour: 8, minute: 0)), isFalse);
      expect(isEndAfterStart(const TimeOfDay(hour: 8, minute: 0), null), isFalse);
    });
  });

  group('AvailabilityFormPage form validation', () {
    testWidgets('submitting an empty form shows the required-field errors', (
      tester,
    ) async {
      await useDesktopTestSurface(tester);

      await tester.pumpWidget(testApp(const AvailabilityFormPage()));

      // The page's own heading and the submit button share the same label in
      // create mode, so target the button by type instead of by text.
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Profissional e obrigatorio'), findsOneWidget);
      expect(find.text('Horario inicial e obrigatorio'), findsOneWidget);
      expect(find.text('Horario final e obrigatorio'), findsOneWidget);
    });
  });
}
