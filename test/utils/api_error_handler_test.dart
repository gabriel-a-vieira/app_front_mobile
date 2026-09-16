import 'package:app_front_mobile/utils/api_error_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers ApiErrorHandler.getMessage, the single function that decides what
/// the user sees whenever a request to the backend fails. It backs the
/// login-error-handling fix (login_page.dart) and is reused across the app,
/// so a regression here silently changes error messages everywhere.
void main() {
  RequestOptions options() => RequestOptions(path: '/test');

  DioException dioError({int? statusCode, dynamic data}) {
    return DioException(
      requestOptions: options(),
      response: statusCode == null
          ? null
          : Response(
              requestOptions: options(),
              statusCode: statusCode,
              data: data,
            ),
    );
  }

  group('response body takes priority over the status code', () {
    test('uses the "message" field when present', () {
      final error = dioError(statusCode: 400, data: {'message': 'Cliente ja possui um agendamento neste horario'});

      expect(
        ApiErrorHandler.getMessage(error),
        'Cliente ja possui um agendamento neste horario',
      );
    });

    test('falls back to the "error" field when "message" is absent', () {
      final error = dioError(statusCode: 400, data: {'error': 'Bad Request'});

      expect(ApiErrorHandler.getMessage(error), 'Bad Request');
    });

    test('ignores a blank "message" and falls back to "error"', () {
      final error = dioError(statusCode: 400, data: {'message': '   ', 'error': 'Bad Request'});

      expect(ApiErrorHandler.getMessage(error), 'Bad Request');
    });

    test('uses a raw string body directly', () {
      final error = dioError(statusCode: 500, data: 'Erro inesperado no servidor');

      expect(ApiErrorHandler.getMessage(error), 'Erro inesperado no servidor');
    });
  });

  group('falls back to a PT-BR message per status code when the body has none', () {
    final cases = <int, String>{
      400: 'Dados invalidos. Verifique as informacoes e tente novamente.',
      401: 'Sua sessao expirou. Realize o login novamente.',
      403: 'Voce nao possui permissao para realizar esta operacao.',
      404: 'Registro nao encontrado.',
      409: 'Nao foi possivel concluir a operacao devido a um conflito.',
      500: 'Ocorreu um erro interno no servidor. Tente novamente.',
    };

    cases.forEach((statusCode, expectedMessage) {
      test('status $statusCode', () {
        final error = dioError(statusCode: statusCode, data: null);

        expect(ApiErrorHandler.getMessage(error), expectedMessage);
      });
    });
  });

  test('uses the caller-provided fallback for an unmapped status code', () {
    final error = dioError(statusCode: 418, data: null);

    expect(
      ApiErrorHandler.getMessage(error, fallback: 'Falha ao carregar agenda'),
      'Falha ao carregar agenda',
    );
  });

  test('uses the default fallback when there is no response at all', () {
    final error = dioError();

    expect(
      ApiErrorHandler.getMessage(error),
      'Ocorreu um erro. Tente novamente.',
    );
  });

  test('uses the caller-provided fallback for a non-DioException error', () {
    expect(
      ApiErrorHandler.getMessage(Exception('boom'), fallback: 'Falha ao entrar'),
      'Falha ao entrar',
    );
  });
}
