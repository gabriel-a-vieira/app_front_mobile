import 'package:dio/dio.dart';
import 'package:app_front_mobile/config/api_client.dart';

class CityService {
  CityService({Dio? dio, required this.baseUrl}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;
  final String baseUrl;

  /// Mantém o nome já utilizado nas telas existentes do projeto,
  /// como professional_form_page.dart e client_form_page.dart.
  Future<List<CityOption>> findByState({required String state}) async {
    final response = await _dio.get(baseUrl, queryParameters: {'state': state});

    final data = response.data;

    List<dynamic> items;

    if (data is List) {
      items = data;
    } else if (data is Map && data['content'] is List) {
      items = data['content'] as List;
    } else if (data is Map && data['items'] is List) {
      items = data['items'] as List;
    } else {
      items = const [];
    }

    final cities = items
        .whereType<Map>()
        .map((item) => CityOption.fromJson(Map<String, dynamic>.from(item)))
        .where((city) => city.name.trim().isNotEmpty)
        .toList();

    cities.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return cities;
  }

  /// Alias mantido para o novo modal de cidades.
  /// Assim não quebramos nenhuma tela antiga nem a nova ProfilePage.
  Future<List<CityOption>> findCitiesByState({required String state}) {
    return findByState(state: state);
  }
}

class CityOption {
  final String id;
  final String name;
  final String stateAbbreviation;

  const CityOption({
    required this.id,
    required this.name,
    required this.stateAbbreviation,
  });

  factory CityOption.fromJson(Map<String, dynamic> json) {
    String stateAbbreviation = '';

    final rawState = json['state'];

    if (rawState is Map) {
      stateAbbreviation =
          rawState['abbreviation']?.toString() ??
          rawState['uf']?.toString() ??
          '';
    } else if (rawState is String) {
      stateAbbreviation = rawState;
    }

    if (stateAbbreviation.isEmpty) {
      stateAbbreviation =
          json['stateAbbreviation']?.toString() ??
          json['state_abbreviation']?.toString() ??
          json['uf']?.toString() ??
          '';
    }

    return CityOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      stateAbbreviation: stateAbbreviation,
    );
  }

  String get label {
    if (stateAbbreviation.trim().isEmpty) {
      return name;
    }

    return '$name - $stateAbbreviation';
  }
}
