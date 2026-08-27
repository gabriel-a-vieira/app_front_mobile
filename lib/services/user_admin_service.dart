import 'package:dio/dio.dart';

class UserAdminService {
  UserAdminService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<void> createUser({
    required String token,
    required CreateUserRequest request,
  }) async {
    await _dio.post(
      baseUrl,
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}

class CreateUserRequest {
  final String name;
  final String email;
  final String password;
  final String role;
  final String? companyId;

  CreateUserRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.companyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      if (companyId != null && companyId!.isNotEmpty) 'companyId': companyId,
    };
  }
}
