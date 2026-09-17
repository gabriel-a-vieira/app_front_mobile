import 'package:app_front_mobile/widgets/service_booking_modal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the pure date/payload/filter helpers extracted from
/// ServiceBookingModal's private State methods: the API date/slot payload
/// formatting used when booking an appointment, and the AM/PM slot filter
/// that backs the "Todos/Manhã/Tarde" chips. The modal widget itself isn't
/// tested here -- its initState fires a real network call with no seam to
/// fake it yet.
void main() {
  group('formatApiDate', () {
    test('zero-pads month and day', () {
      expect(formatApiDate(DateTime(2026, 3, 5)), '2026-03-05');
    });

    test('does not pad already two-digit values', () {
      expect(formatApiDate(DateTime(2026, 12, 25)), '2026-12-25');
    });
  });

  group('buildAppointmentStartAt', () {
    test('combines the formatted date and slot into an ISO-like string', () {
      expect(
        buildAppointmentStartAt(DateTime(2026, 3, 5), '9:5'),
        '2026-03-05T09:05:00',
      );
    });

    test('keeps already two-digit hour/minute as-is', () {
      expect(
        buildAppointmentStartAt(DateTime(2026, 3, 5), '14:30'),
        '2026-03-05T14:30:00',
      );
    });
  });

  group('weekDayAbbreviation', () {
    test('maps each ISO weekday to its PT-BR abbreviation', () {
      // 2026-03-02 is a Monday.
      expect(weekDayAbbreviation(DateTime(2026, 3, 2)), 'Seg');
      expect(weekDayAbbreviation(DateTime(2026, 3, 3)), 'Ter');
      expect(weekDayAbbreviation(DateTime(2026, 3, 4)), 'Qua');
      expect(weekDayAbbreviation(DateTime(2026, 3, 5)), 'Qui');
      expect(weekDayAbbreviation(DateTime(2026, 3, 6)), 'Sex');
      expect(weekDayAbbreviation(DateTime(2026, 3, 7)), 'Sab');
      expect(weekDayAbbreviation(DateTime(2026, 3, 8)), 'Dom');
    });
  });

  group('filterSlotsByPeriod', () {
    const slots = ['08:00', '09:30', '11:59', '12:00', '14:00', '18:30'];

    test('ALL returns every slot unchanged', () {
      expect(filterSlotsByPeriod(slots, 'ALL'), slots);
    });

    test('MORNING keeps only slots before 12:00', () {
      expect(
        filterSlotsByPeriod(slots, 'MORNING'),
        ['08:00', '09:30', '11:59'],
      );
    });

    test('AFTERNOON keeps slots from 12:00 onward', () {
      expect(
        filterSlotsByPeriod(slots, 'AFTERNOON'),
        ['12:00', '14:00', '18:30'],
      );
    });

    test('returns an empty list when there are no slots', () {
      expect(filterSlotsByPeriod([], 'MORNING'), isEmpty);
    });
  });
}
