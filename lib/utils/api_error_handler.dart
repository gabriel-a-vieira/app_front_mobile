import 'package:dio/dio.dart';

class ApiErrorHandler {
  ApiErrorHandler._();

  static String getMessage(
    Object error, {
    String fallback = 'Ocorreu um erro. Tente novamente.',
  }) {
    if (error is DioException) {
      final response = error.response;
      final data = response?.data;

      if (data is Map) {
        final message = data['message'];

        if (message != null &&
            message.toString().trim().isNotEmpty) {
          return message.toString().trim();
        }

        final errorMessage = data['error'];

        if (errorMessage != null &&
            errorMessage.toString().trim().isNotEmpty) {
          return errorMessage.toString().trim();
        }
      }

      if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }

      switch (response?.statusCode) {
        case 400:
          return 'Dados invalidos. Verifique as informacoes e tente novamente.';

        case 401:
          return 'Sua sessao expirou. Realize o login novamente.';

        case 403:
          return 'Voce nao possui permissao para realizar esta operacao.';

        case 404:
          return 'Registro nao encontrado.';

        case 409:
          return 'Nao foi possivel concluir a operacao devido a um conflito.';

        case 500:
          return 'Ocorreu um erro interno no servidor. Tente novamente.';

        default:
          return fallback;
      }
    }

    return fallback;
  }
}