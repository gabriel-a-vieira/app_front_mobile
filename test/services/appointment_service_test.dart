import 'package:app_front_mobile/services/appointment_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Covers the pure JSON-mapping logic in appointment_service.dart
/// (AppointmentSummary/AppointmentPage/AppointmentServiceSummary.fromJson)
/// plus AppointmentSearchFilters' pure helpers. These guard against
/// backend response-shape drift (missing fields, numeric fields sent as
/// strings) without needing a widget or a real HTTP call.
///
/// Also covers cancelAppointments' request shape: a bulk cancel sends a
/// `List<String>` body, which Dio's ImplyContentTypeInterceptor does not
/// auto-detect as JSON (it only recognizes `Map`/`List<Map>`/`String`), so
/// the request must set Content-Type explicitly or the backend rejects it
/// with "Required request body is missing".
class MockDio extends Mock implements Dio {}

class FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOptions());
  });

  group('cancelAppointments', () {
    late MockDio dio;
    late AppointmentService service;

    const baseUrl = 'http://api.test/appointment';

    setUp(() {
      dio = MockDio();
      service = AppointmentService(dio: dio, baseUrl: baseUrl);
    });

    test('sets Content-Type: application/json explicitly on the request', () async {
      when(
        () => dio.delete(baseUrl, data: any(named: 'data'), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: baseUrl),
          statusCode: 204,
        ),
      );

      await service.cancelAppointments(token: 't', ids: ['appt-1']);

      final captured = verify(
        () => dio.delete(baseUrl, data: any(named: 'data'), options: captureAny(named: 'options')),
      ).captured;

      final options = captured.single as Options;
      expect(options.headers?['Content-Type'], 'application/json');
    });
  });

  group('AppointmentSummary.fromJson', () {
    test('maps every field, including nested services', () {
      final summary = AppointmentSummary.fromJson({
        'id': 'appt-1',
        'clientId': 'client-1',
        'clientName': 'Joana',
        'professionalId': 'prof-1',
        'professionalName': 'Carlos',
        'startAt': '2026-10-01T10:00:00',
        'endAt': '2026-10-01T10:30:00',
        'status': 'SCHEDULED',
        'companyId': 'company-1',
        'services': [
          {
            'serviceOfferingId': 'svc-1',
            'name': 'Corte',
            'durationMinutes': 30,
            'price': 50.0,
            'executionOrder': 1,
          },
        ],
      });

      expect(summary.id, 'appt-1');
      expect(summary.clientName, 'Joana');
      expect(summary.status, 'SCHEDULED');
      expect(summary.services, hasLength(1));
      expect(summary.services.first.name, 'Corte');
      expect(summary.services.first.durationMinutes, 30);
      expect(summary.services.first.price, 50.0);
    });

    test('defaults missing fields to empty strings and an empty service list', () {
      final summary = AppointmentSummary.fromJson({});

      expect(summary.id, '');
      expect(summary.clientName, '');
      expect(summary.status, '');
      expect(summary.services, isEmpty);
    });

    test('ignores a non-list "services" value instead of throwing', () {
      final summary = AppointmentSummary.fromJson({'services': 'not-a-list'});

      expect(summary.services, isEmpty);
    });
  });

  group('AppointmentServiceSummary.fromJson numeric coercion', () {
    test('accepts numbers sent as strings', () {
      final item = AppointmentServiceSummary.fromJson({
        'serviceOfferingId': 'svc-1',
        'name': 'Corte',
        'durationMinutes': '30',
        'price': '49.9',
        'executionOrder': '2',
      });

      expect(item.durationMinutes, 30);
      expect(item.price, 49.9);
      expect(item.executionOrder, 2);
    });

    test('defaults unparsable numeric fields to zero', () {
      final item = AppointmentServiceSummary.fromJson({
        'durationMinutes': 'not-a-number',
        'price': null,
      });

      expect(item.durationMinutes, 0);
      expect(item.price, 0);
    });
  });

  group('AppointmentPage.fromJson', () {
    test('maps pagination metadata and content', () {
      final page = AppointmentPage.fromJson({
        'content': [
          {'id': 'appt-1'},
          {'id': 'appt-2'},
        ],
        'number': 0,
        'totalPages': 3,
        'first': true,
        'last': false,
      });

      expect(page.content, hasLength(2));
      expect(page.content.map((a) => a.id), ['appt-1', 'appt-2']);
      expect(page.number, 0);
      expect(page.totalPages, 3);
      expect(page.first, isTrue);
      expect(page.last, isFalse);
    });

    test('defaults to an empty page when "content" is missing', () {
      final page = AppointmentPage.fromJson({});

      expect(page.content, isEmpty);
      expect(page.number, 0);
      expect(page.totalPages, 0);
      expect(page.first, isFalse);
      expect(page.last, isFalse);
    });
  });

  group('AppointmentSearchFilters', () {
    test('hasAdvancedFilters is false when only free-text search is set', () {
      const filters = AppointmentSearchFilters(search: 'joana');

      expect(filters.hasAdvancedFilters, isFalse);
    });

    test('hasAdvancedFilters is true when any advanced field is set', () {
      const filters = AppointmentSearchFilters(status: 'CONFIRMED');

      expect(filters.hasAdvancedFilters, isTrue);
    });

    test('copyWith overrides only the given fields', () {
      const original = AppointmentSearchFilters(search: 'joana', status: 'SCHEDULED');

      final updated = original.copyWith(status: 'CANCELLED');

      expect(updated.search, 'joana');
      expect(updated.status, 'CANCELLED');
    });
  });
}
