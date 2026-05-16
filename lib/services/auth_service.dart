import 'package:dio/dio.dart';

class AuthLoginResult {
  final String token;
  final String name;
  final String email;
  final String role;

  AuthLoginResult({
    required this.token,
    required this.name,
    required this.email,
    required this.role,
  });

  String get firstName {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return '';
    }

    return trimmedName.split(' ').first;
  }
}

class AuthService {
  AuthService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<AuthLoginResult> login({
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
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    final data = response.data;

    if (data is Map && data['token'] is String) {
      return AuthLoginResult(
        token: data['token'] as String,
        name: data['name'] is String ? data['name'] as String : '',
        email: data['email'] is String ? data['email'] as String : email,
        role: data['role'] is String ? data['role'] as String : 'CLIENT',
      );
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
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Erro ao cadastrar usuario. Status: ${response.statusCode}',
      );
    }
  }
}