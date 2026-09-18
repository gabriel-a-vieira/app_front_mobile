import 'package:app_front_mobile/services/availability_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Covers the pure JSON-mapping logic in availability_service.dart
/// (AvailabilitySummary/AvailabilityPage.fromJson) plus
/// AvailabilitySearchFilters' pure helpers. Availability windows feed
/// directly into the booking slot calculation on the backend, so a
/// mapping regression here would silently show wrong working hours.
///
/// Also covers deleteAvailabilities' request shape: a bulk delete sends
/// a `List<String>` body, which Dio's ImplyContentTypeInterceptor does not
/// auto-detect as JSON (it only recognizes `Map`/`List<Map>`/`String`), so
/// the request must set Content-Type explicitly or the backend rejects it
/// with "Required request body is missing".
class MockDio extends Mock implements Dio {}

class FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOptions());
  });

  group('deleteAvailabilities', () {
    late MockDio dio;
    late AvailabilityService service;

    const baseUrl = 'http://api.test/availability';

    setUp(() {
      dio = MockDio();
      service = AvailabilityService(dio: dio, baseUrl: baseUrl);
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

      await service.deleteAvailabilities(token: 't', ids: ['avail-1']);

      final captured = verify(
        () => dio.delete(baseUrl, data: any(named: 'data'), options: captureAny(named: 'options')),
      ).captured;

      final options = captured.single as Options;
      expect(options.headers?['Content-Type'], 'application/json');
    });
  });

  group('AvailabilitySummary.fromJson', () {
    test('maps every field', () {
      final summary = AvailabilitySummary.fromJson({
        'id': 'avail-1',
        'professionalId': 'prof-1',
        'name': 'Carlos',
        'dayWeek': 'MONDAY',
        'startTime': '09:00',
        'endTime': '17:00',
        'companyId': 'company-1',
      });

      expect(summary.id, 'avail-1');
      expect(summary.professionalId, 'prof-1');
      // NB: professionalName is read from the "name" key, not
      // "professionalName" - this documents the current (mismatched)
      // backend contract rather than the ideal one.
      expect(summary.professionalName, 'Carlos');
      expect(summary.dayWeek, 'MONDAY');
      expect(summary.startTime, '09:00');
      expect(summary.endTime, '17:00');
      expect(summary.companyId, 'company-1');
    });

    test('defaults every missing field to an empty string', () {
      final summary = AvailabilitySummary.fromJson({});

      expect(summary.id, '');
      expect(summary.professionalName, '');
      expect(summary.dayWeek, '');
      expect(summary.startTime, '');
      expect(summary.endTime, '');
    });
  });

  group('AvailabilityPage.fromJson', () {
    test('maps pagination metadata and content', () {
      final page = AvailabilityPage.fromJson({
        'content': [
          {'id': 'avail-1'},
        ],
        'number': 1,
        'totalPages': 2,
        'first': false,
        'last': true,
      });

      expect(page.content, hasLength(1));
      expect(page.content.first.id, 'avail-1');
      expect(page.number, 1);
      expect(page.totalPages, 2);
      expect(page.first, isFalse);
      expect(page.last, isTrue);
    });

    test('ignores non-map entries inside "content" instead of throwing', () {
      final page = AvailabilityPage.fromJson({
        'content': [
          {'id': 'avail-1'},
          'not-a-map',
          42,
        ],
      });

      expect(page.content, hasLength(1));
    });

    test('defaults to an empty page when "content" is missing', () {
      final page = AvailabilityPage.fromJson({});

      expect(page.content, isEmpty);
      expect(page.number, 0);
      expect(page.totalPages, 0);
    });
  });

  group('AvailabilitySearchFilters', () {
    test('hasAdvancedFilters is true when dayWeek is set', () {
      const filters = AvailabilitySearchFilters(dayWeek: 'MONDAY');

      expect(filters.hasAdvancedFilters, isTrue);
    });

    test('hasAdvancedFilters is false with only free-text search', () {
      const filters = AvailabilitySearchFilters(search: 'carlos');

      expect(filters.hasAdvancedFilters, isFalse);
    });

    test('copyWith overrides only the given fields', () {
      const original = AvailabilitySearchFilters(professionalId: 'prof-1', dayWeek: 'MONDAY');

      final updated = original.copyWith(dayWeek: 'TUESDAY');

      expect(updated.professionalId, 'prof-1');
      expect(updated.dayWeek, 'TUESDAY');
    });
  });
}
