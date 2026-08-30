import 'package:dio/dio.dart';

class PublicCompanyService {
  PublicCompanyService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<List<PublicCompanyServiceOption>> findServices({
    required String companyId,
  }) async {
    final response = await _dio.get('$baseUrl/$companyId/services');

    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => PublicCompanyServiceOption.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<List<PublicCompanyProfessional>> findProfessionals({
    required String companyId,
  }) async {
    final response = await _dio.get('$baseUrl/$companyId/professionals');

    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => PublicCompanyProfessional.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}

class PublicCompanyServiceOption {
  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final double price;

  const PublicCompanyServiceOption({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
  });

  factory PublicCompanyServiceOption.fromJson(Map<String, dynamic> json) {
    return PublicCompanyServiceOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      durationMinutes: _toInt(json['durationMinutes']),
      price: _toDouble(json['price']),
    );
  }
}

class PublicCompanyProfessional {
  final String id;
  final String name;

  const PublicCompanyProfessional({required this.id, required this.name});

  factory PublicCompanyProfessional.fromJson(Map<String, dynamic> json) {
    return PublicCompanyProfessional(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
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

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}
