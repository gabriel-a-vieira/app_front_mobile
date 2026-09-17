import 'package:app_front_mobile/models/system_module.dart';
import 'package:app_front_mobile/services/permission_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Covers PermissionService's parsing of the matrix (GET/PUT /permission)
/// and the effective-permissions map (GET /permission/me), including how it
/// tolerates an unknown module string in the response instead of throwing.
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

  group('findMatrix', () {
    test('parses each row into a RolePermissionEntry', () async {
      when(() => dio.get(baseUrl, options: any(named: 'options'))).thenAnswer(
        (_) async => okResponse([
          {
            'role': 'COMPANY_ADMIN',
            'module': 'CLIENT',
            'canCreate': true,
            'canUpdate': false,
            'canList': true,
            'canDelete': false,
          },
        ]),
      );

      final matrix = await service.findMatrix(token: 't');

      expect(matrix, hasLength(1));
      expect(matrix.first.role, 'COMPANY_ADMIN');
      expect(matrix.first.module, SystemModule.client);
      expect(matrix.first.canCreate, isTrue);
      expect(matrix.first.canUpdate, isFalse);
    });

    test('returns an empty list when the body is not a list', () async {
      when(
        () => dio.get(baseUrl, options: any(named: 'options')),
      ).thenAnswer((_) async => okResponse('unexpected'));

      final matrix = await service.findMatrix(token: 't');

      expect(matrix, isEmpty);
    });
  });

  group('updateMatrix', () {
    test('PUTs the entries serialized back to their API shape', () async {
      when(
        () => dio.put(baseUrl, data: any(named: 'data'), options: any(named: 'options')),
      ).thenAnswer((_) async => okResponse(null));

      const entry = RolePermissionEntry(
        role: 'PROFESSIONAL',
        module: SystemModule.appointment,
        canCreate: true,
        canUpdate: true,
        canList: true,
        canDelete: false,
      );

      await service.updateMatrix(token: 't', entries: [entry]);

      verify(
        () => dio.put(
          baseUrl,
          data: [
            {
              'role': 'PROFESSIONAL',
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
