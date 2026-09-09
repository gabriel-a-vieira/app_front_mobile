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
    final response = await _dio.post(
      '$baseUrl/auth/login',
      data: {'email': email, 'password': password},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    return _parseLoginResult(response.data, fallbackEmail: email);
  }

  Future<AuthLoginResult> externalLogin({
    required String provider,
    required String credential,
  }) async {
    final response = await _dio.post(
      '$baseUrl/auth/external/$provider',
      data: {'credential': credential},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    return _parseLoginResult(response.data);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '$baseUrl/auth/register',
      data: {'name': name, 'email': email, 'password': password},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Erro ao cadastrar usuario. Status: ${response.statusCode}',
      );
    }
  }

  AuthLoginResult _parseLoginResult(dynamic data, {String fallbackEmail = ''}) {
    if (data is! Map || data['token'] is! String) {
      throw Exception('Invalid login response');
    }

    return AuthLoginResult(
      token: data['token'].toString(),

      name: data['name']?.toString() ?? '',

      email: data['email']?.toString() ?? fallbackEmail,

      role: data['role']?.toString() ?? 'CLIENT',
    );
  }
}
