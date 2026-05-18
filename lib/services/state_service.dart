import 'package:dio/dio.dart';

class StateService {
  StateService({
    Dio? dio,
    required this.baseUrl,
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<List<StateOption>> findStates() async {
    final response = await _dio.get(baseUrl);

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid states response');
    }

    return data
        .whereType<Map>()
        .map((item) => StateOption.fromJson(item))
        .toList();
  }
}

class StateOption {
  final String id;
  final String name;
  final String uf;

  StateOption({
    required this.id,
    required this.name,
    required this.uf,
  });

  factory StateOption.fromJson(Map json) {
    return StateOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      uf: json['uf']?.toString() ??
          json['acronym']?.toString() ??
          json['code']?.toString() ??
          '',
    );
  }

  String get label {
    if (name.isEmpty) {
      return uf;
    }

    return '$uf - $name';
  }
}