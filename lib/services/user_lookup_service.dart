import 'package:dio/dio.dart';
import 'package:app_front_mobile/config/api_client.dart';

class UserLookupService {
  UserLookupService({Dio? dio, required this.baseUrl})
    : _dio = dio ?? ApiClient.dio;

  final Dio _dio;
  final String baseUrl;

  Future<UserLookupPage> findUsers({
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
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return UserLookupPage.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

class UserLookupPage {
  final List<UserLookupOption> content;

  final int number;
  final int totalPages;

  final bool first;
  final bool last;

  UserLookupPage({
    required this.content,
    required this.number,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  factory UserLookupPage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];

    return UserLookupPage(
      content: rawContent is List
          ? rawContent
                .whereType<Map>()
                .map(
                  (item) =>
                      UserLookupOption.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : [],
      number: _toInt(json['number']),
      totalPages: _toInt(json['totalPages']),
      first: json['first'] == true,
      last: json['last'] == true,
    );
  }
}

class UserLookupOption {
  final String id;
  final String name;
  final String email;
  final String role;

  UserLookupOption({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserLookupOption.fromJson(Map<String, dynamic> json) {
    return UserLookupOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
