import 'package:app_front_mobile/services/service_offering_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Covers deleteServices' request shape: a bulk delete sends a
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

  group('deleteServices', () {
    late MockDio dio;
    late ServiceOfferingService service;

    const baseUrl = 'http://api.test/service-offering';

    setUp(() {
      dio = MockDio();
      service = ServiceOfferingService(dio: dio, baseUrl: baseUrl);
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

      await service.deleteServices(token: 't', ids: ['service-1']);

      final captured = verify(
        () => dio.delete(baseUrl, data: any(named: 'data'), options: captureAny(named: 'options')),
      ).captured;

      final options = captured.single as Options;
      expect(options.headers?['Content-Type'], 'application/json');
    });
  });
}
