import 'package:app_front_mobile/config/api_config.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:dio/dio.dart';

/// Shared, authenticated [Dio] client.
///
/// Every service used to build its own bare `Dio()` and repeat
/// `Options(headers: {'Authorization': 'Bearer $token'})` by hand on each
/// request. Services that don't receive an explicit [Dio] override now get
/// this one instead, which attaches the stored access token automatically.
class ApiClient {
  ApiClient._();

  static final TokenStorage _tokenStorage = TokenStorage();

  static final Dio dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
      ),
    );
}
