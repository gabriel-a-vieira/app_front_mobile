import 'package:dio/dio.dart';
import 'package:app_front_mobile/config/api_client.dart';

class UserAdminService {
  UserAdminService({Dio? dio, required this.baseUrl})
    : _dio = dio ?? ApiClient.dio;

  final Dio _dio;
  final String baseUrl;

  Options _auth(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<UserPage> findAll({
    required String token,
    required int page,
    required int size,
    String search = '',
  }) async {
    final response = await _dio.get(
      baseUrl,
      queryParameters: {
        'page': page,
        'size': size,
        if (search.isNotEmpty) 'search': search,
      },
      options: _auth(token),
    );

    return UserPage.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<UserSummary> findById({required String token, required String id}) async {
    final response = await _dio.get('$baseUrl/$id', options: _auth(token));

    return UserSummary.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> createUser({
    required String token,
    required CreateUserRequest request,
  }) async {
    await _dio.post(baseUrl, data: request.toJson(), options: _auth(token));
  }

  Future<void> update({
    required String token,
    required String id,
    required UpdateUserRequest request,
  }) async {
    await _dio.put('$baseUrl/$id', data: request.toJson(), options: _auth(token));
  }

  Future<void> deleteUsers({
    required String token,
    required List<String> ids,
  }) async {
    await _dio.delete(baseUrl, data: ids, options: _auth(token));
  }
}

class UserPage {
  final List<UserSummary> content;
  final int number;
  final bool last;

  UserPage({required this.content, required this.number, required this.last});

  factory UserPage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];

    return UserPage(
      content: rawContent is List
          ? rawContent
                .whereType<Map>()
                .map(
                  (item) => UserSummary.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : [],
      number: json['number'] is int ? json['number'] : 0,
      last: json['last'] == true,
    );
  }
}

class UserSummary {
  final String id;
  final String name;
  final String email;
  final String role;

  UserSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
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

class UpdateUserRequest {
  final String name;
  final String email;
  final String role;
  final String? password;

  UpdateUserRequest({
    required this.name,
    required this.email,
    required this.role,
    this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      if (password != null && password!.isNotEmpty) 'password': password,
    };
  }
}
