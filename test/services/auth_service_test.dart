import 'package:app_front_mobile/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Covers AuthService.login/externalLogin: how the backend's login response
/// is parsed into an AuthLoginResult (including the field defaults used when
/// the backend omits name/email/role), and that a bad response body or a
/// non-2xx DioException propagate as-is instead of being swallowed -- both
/// GoogleAuthService (externalLogin) and login_page.dart's error handling
/// depend on that propagation to work correctly.
class MockDio extends Mock implements Dio {}

class FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOptions());
  });

  late MockDio dio;
  late AuthService authService;

  const baseUrl = 'http://api.test';

  setUp(() {
    dio = MockDio();
    authService = AuthService(dio: dio, baseUrl: baseUrl);
  });

  Response<dynamic> okResponse(dynamic data) {
    return Response(
      requestOptions: RequestOptions(path: '/test'),
      statusCode: 200,
      data: data,
    );
  }

  void stubPost(Response<dynamic> response) {
    when(
      () => dio.post(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => response);
  }

  group('login', () {
    test('parses token, name, email and role on success', () async {
      stubPost(okResponse({
        'token': 'jwt-token',
        'name': 'Cliente Teste',
        'email': 'cliente@teste.com',
        'role': 'CLIENT',
      }));

      final result = await authService.login(
        email: 'cliente@teste.com',
        password: '123456',
      );

      expect(result.token, 'jwt-token');
      expect(result.name, 'Cliente Teste');
      expect(result.email, 'cliente@teste.com');
      expect(result.role, 'CLIENT');

      verify(
        () => dio.post(
          '$baseUrl/auth/login',
          data: {'email': 'cliente@teste.com', 'password': '123456'},
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('defaults name to empty, role to CLIENT and email to the input email', () async {
      stubPost(okResponse({'token': 'jwt-token'}));

      final result = await authService.login(
        email: 'cliente@teste.com',
        password: '123456',
      );

      expect(result.name, '');
      expect(result.role, 'CLIENT');
      expect(result.email, 'cliente@teste.com');
    });

    test('throws when the response body is not a map', () async {
      stubPost(okResponse('not-a-map'));

      expect(
        () => authService.login(email: 'a@a.com', password: '123'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when the token field is missing', () async {
      stubPost(okResponse({'name': 'Cliente'}));

      expect(
        () => authService.login(email: 'a@a.com', password: '123'),
        throwsA(isA<Exception>()),
      );
    });

    test('propagates a DioException from a non-2xx response unchanged', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
          data: {'message': 'Usuario ou senha invalidos, tente novamente.'},
        ),
      );

      when(
        () => dio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(dioException);

      expect(
        () => authService.login(email: 'a@a.com', password: 'wrong'),
        throwsA(same(dioException)),
      );
    });
  });

  group('externalLogin', () {
    test('posts the credential to /auth/external/{provider} and parses the result', () async {
      stubPost(okResponse({
        'token': 'jwt-token',
        'name': 'Cliente Google',
        'email': 'cliente@gmail.com',
        'role': 'CLIENT',
      }));

      final result = await authService.externalLogin(
        provider: 'GOOGLE',
        credential: 'id-token-value',
      );

      expect(result.token, 'jwt-token');
      expect(result.name, 'Cliente Google');
      expect(result.email, 'cliente@gmail.com');

      verify(
        () => dio.post(
          '$baseUrl/auth/external/GOOGLE',
          data: {'credential': 'id-token-value'},
          options: any(named: 'options'),
        ),
      ).called(1);
    });
  });

  group('AuthLoginResult.firstName', () {
    test('returns the first word of a trimmed name', () {
      final result = AuthLoginResult(
        token: 't',
        name: '  Maria Clara Souza  ',
        email: 'e',
        role: 'CLIENT',
      );

      expect(result.firstName, 'Maria');
    });

    test('returns an empty string when the name is blank', () {
      final result = AuthLoginResult(token: 't', name: '   ', email: 'e', role: 'CLIENT');

      expect(result.firstName, '');
    });
  });
}
