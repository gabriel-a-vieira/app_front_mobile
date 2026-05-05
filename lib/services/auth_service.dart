import 'package:dio/dio.dart';

class AuthService {
  AuthService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final url = '$baseUrl/auth/login';

    final response = await _dio.post(
      url,
      data: {'email': email, 'password': password},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    final data = response.data;

    if (data is Map && data['token'] is String) {
      return data['token'] as String;
    }

    throw Exception('Invalid login response');
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '$baseUrl/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Erro ao cadastrar usuario. Status: ${response.statusCode}',
      );
    }
  }
}
