import 'package:dio/dio.dart';

class AuthService {
  AuthService({
    Dio? dio,
    required this.baseUrl,
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final url = '$baseUrl/auth/login';

    final response = await _dio.post(
      url,
      data: {
        'email': email,
        'password': password,
      },
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final data = response.data;

    if (data is Map && data['accessToken'] is String) {
      return data['accessToken'] as String;
    }

    throw Exception('Invalid login response');
  }
}