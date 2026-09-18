import 'package:app_front_mobile/models/system_module.dart';
import 'package:app_front_mobile/services/permission_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Covers PermissionService's per-user API: parsing the paged list of
/// configured profiles, a single user's matrix (GET/PUT /permission/{id}),
/// bulk delete, and the effective-permissions map (GET /permission/me) --
/// including how it tolerates an unknown module string in the response
/// instead of throwing.
class MockDio extends Mock implements Dio {}

class FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOptions());
  });

  late MockDio dio;
  late PermissionService service;

  const baseUrl = 'http://api.test/permission';

  setUp(() {
    dio = MockDio();
    service = PermissionService(dio: dio, baseUrl: baseUrl);
  });

  Response<dynamic> okResponse(dynamic data) {
    return Response(
      requestOptions: RequestOptions(path: '/test'),
      statusCode: 200,
      data: data,
    );
  }

  group('findProfiles', () {
    test('parses each row into a PermissionProfile', () async {
      when(
        () => dio.get(
          baseUrl,
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => okResponse({
          'content': [
            {
              'userId': 'user-1',
              'name': 'Ana Souza',
              'email': 'ana@softix.com',
              'role': 'PROFESSIONAL',
            },
          ],
          'number': 0,
          'last': true,
        }),
      );

      final page = await service.findProfiles(token: 't', page: 0, size: 10);

      expect(page.content, hasLength(1));
      expect(page.content.first.userId, 'user-1');
      expect(page.content.first.role, 'PROFESSIONAL');
      expect(page.last, isTrue);
    });

    test('returns an empty content list when the body has no content field', () async {
      when(
        () => dio.get(
          baseUrl,
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => okResponse({'number': 0, 'last': true}));

      final page = await service.findProfiles(token: 't', page: 0, size: 10);

      expect(page.content, isEmpty);
    });
  });

  group('findUserMatrix', () {
    test('parses each row into a ModulePermissionEntry', () async {
      when(
        () => dio.get('$baseUrl/user-1', options: any(named: 'options')),
      ).thenAnswer(
        (_) async => okResponse([
          {
            'module': 'CLIENT',
            'canCreate': true,
            'canUpdate': false,
            'canList': true,
            'canDelete': false,
          },
        ]),
      );

      final matrix = await service.findUserMatrix(token: 't', userId: 'user-1');

      expect(matrix, hasLength(1));
      expect(matrix.first.module, SystemModule.client);
      expect(matrix.first.canCreate, isTrue);
      expect(matrix.first.canUpdate, isFalse);
    });

    test('returns an empty list when the body is not a list', () async {
      when(
        () => dio.get('$baseUrl/user-1', options: any(named: 'options')),
      ).thenAnswer((_) async => okResponse('unexpected'));

      final matrix = await service.findUserMatrix(token: 't', userId: 'user-1');

      expect(matrix, isEmpty);
    });
  });

  group('updateUserMatrix', () {
    test('PUTs the entries serialized back to their API shape', () async {
      when(
        () => dio.put(
          '$baseUrl/user-1',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => okResponse(null));

      const entry = ModulePermissionEntry(
        module: SystemModule.appointment,
        canCreate: true,
        canUpdate: true,
        canList: true,
        canDelete: false,
      );

      await service.updateUserMatrix(token: 't', userId: 'user-1', entries: [entry]);

      verify(
        () => dio.put(
          '$baseUrl/user-1',
          data: [
            {
              'module': 'APPOINTMENT',
              'canCreate': true,
              'canUpdate': true,
              'canList': true,
              'canDelete': false,
            },
          ],
          options: any(named: 'options'),
        ),
      ).called(1);
    });
  });

  group('deleteProfiles', () {
    test('DELETEs with the user ids as the body', () async {
      when(
        () => dio.delete(baseUrl, data: any(named: 'data'), options: any(named: 'options')),
      ).thenAnswer((_) async => okResponse(null));

      await service.deleteProfiles(token: 't', userIds: ['user-1', 'user-2']);

      verify(
        () => dio.delete(
          baseUrl,
          data: ['user-1', 'user-2'],
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('sets Content-Type: application/json explicitly on the request', () async {
      // Regression test: a List<String> body isn't recognized by Dio's
      // ImplyContentTypeInterceptor (it only auto-detects Map/List<Map>/
      // String), so without an explicit header the interceptor leaves
      // Content-Type unset, Dio falls back to `data.toString()` instead of
      // JSON-encoding the list, and the backend rejects the request with
      // "Required request body is missing" because no HttpMessageConverter
      // can read a body with no matching content type.
      when(
        () => dio.delete(baseUrl, data: any(named: 'data'), options: any(named: 'options')),
      ).thenAnswer((_) async => okResponse(null));

      await service.deleteProfiles(token: 't', userIds: ['user-1']);

      final captured = verify(
        () => dio.delete(baseUrl, data: any(named: 'data'), options: captureAny(named: 'options')),
      ).captured;

      final options = captured.single as Options;
      expect(options.headers?['Content-Type'], 'application/json');
    });
  });

  group('findMyPermissions', () {
    test('parses the module map keyed by the API module name', () async {
      when(
        () => dio.get('$baseUrl/me', options: any(named: 'options')),
      ).thenAnswer(
        (_) async => okResponse({
          'CLIENT': {
            'canCreate': true,
            'canUpdate': true,
            'canList': true,
            'canDelete': true,
          },
        }),
      );

      final permissions = await service.findMyPermissions(token: 't');

      expect(permissions[SystemModule.client]?.canCreate, isTrue);
    });

    test('ignores an unrecognized module key instead of throwing', () async {
      when(
        () => dio.get('$baseUrl/me', options: any(named: 'options')),
      ).thenAnswer(
        (_) async => okResponse({
          'SOME_FUTURE_MODULE': {
            'canCreate': true,
            'canUpdate': true,
            'canList': true,
            'canDelete': true,
          },
        }),
      );

      final permissions = await service.findMyPermissions(token: 't');

      expect(permissions, isEmpty);
    });

    test('returns an empty map when the body is not a map', () async {
      when(
        () => dio.get('$baseUrl/me', options: any(named: 'options')),
      ).thenAnswer((_) async => okResponse([]));

      final permissions = await service.findMyPermissions(token: 't');

      expect(permissions, isEmpty);
    });
  });
}
