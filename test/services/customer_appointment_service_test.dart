import 'package:app_front_mobile/services/customer_appointment_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Covers the calendar part of CustomerAppointmentService: the request to
/// GET /appointment/mine/{id}/calendar and the response mapping used by the
/// "Adicionar ao calendário" buttons.
class MockDio extends Mock implements Dio {}

class FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOptions());
  });

  group('findMineCalendar', () {
    late MockDio dio;
    late CustomerAppointmentService service;

    const baseUrl = 'http://api.test/appointment';

    setUp(() {
      dio = MockDio();
      service = CustomerAppointmentService(dio: dio, baseUrl: baseUrl);
    });

    test('calls the calendar endpoint with the token and maps the response', () async {
      when(
        () => dio.get('$baseUrl/mine/appt-1/calendar', options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '$baseUrl/mine/appt-1/calendar'),
          statusCode: 200,
          data: {
            'googleCalendarUrl': 'https://calendar.google.com/calendar/render?action=TEMPLATE&text=X',
            'ics': 'BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n',
            'fileName': 'agendamento.ics',
          },
        ),
      );

      final calendar = await service.findMineCalendar(token: 'tok', id: 'appt-1');

      expect(calendar.googleCalendarUrl, startsWith('https://calendar.google.com/'));
      expect(calendar.ics, startsWith('BEGIN:VCALENDAR'));
      expect(calendar.fileName, 'agendamento.ics');

      final options = verify(
        () => dio.get('$baseUrl/mine/appt-1/calendar', options: captureAny(named: 'options')),
      ).captured.single as Options;

      expect(options.headers?['Authorization'], 'Bearer tok');
    });
  });

  group('CustomerAppointmentCalendar.fromJson', () {
    test('falls back to a default file name and empty strings', () {
      final calendar = CustomerAppointmentCalendar.fromJson({});

      expect(calendar.googleCalendarUrl, '');
      expect(calendar.ics, '');
      expect(calendar.fileName, 'agendamento.ics');
    });
  });
}
