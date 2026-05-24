import 'package:dio/dio.dart';

class CityService {
  CityService({
    Dio? dio,
    required this.baseUrl,
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<List<CityOption>> findByState({
    required String state,
  }) async {
    final response = await _dio.get(
      baseUrl,
      queryParameters: {
        'state': state,
      },
    );

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid cities response');
    }

    return data
        .whereType<Map>()
        .map((item) => CityOption.fromJson(item))
        .toList();
  }
}

class CityOption {
  final String id;
  final String name;
  final String ibgeCode;
  final String tomCode;
  final String state;

  CityOption({
    required this.id,
    required this.name,
    required this.ibgeCode,
    required this.tomCode,
    required this.state,
  });

  factory CityOption.fromJson(Map json) {
    return CityOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      ibgeCode: json['ibgeCode']?.toString() ?? '',
      tomCode: json['tomCode']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }
}