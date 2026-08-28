import 'package:dio/dio.dart';

class AvailabilityService {
  AvailabilityService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<AvailabilityPage> findAll({
    required String token,
    required int page,
    required int size,
    AvailabilitySearchFilters filters = const AvailabilitySearchFilters(),
  }) async {
    final response = await _dio.get(
      baseUrl,
      queryParameters: {
        'page': page,
        'size': size,
        if (filters.search.isNotEmpty) 'search': filters.search,
        if (filters.professionalId.isNotEmpty)
          'professionalId': filters.professionalId,
        if (filters.dayWeek.isNotEmpty) 'dayWeek': filters.dayWeek,
        if (filters.companyId.isNotEmpty) 'companyId': filters.companyId,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return AvailabilityPage.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AvailabilitySummary> findById({
    required String token,
    required String id,
  }) async {
    final response = await _dio.get(
      '$baseUrl/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return AvailabilitySummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> createAvailability({
    required String token,
    required AvailabilityRequest request,
  }) async {
    await _dio.post(
      baseUrl,
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> updateAvailability({
    required String token,
    required String id,
    required AvailabilityRequest request,
  }) async {
    await _dio.put(
      '$baseUrl/$id',
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> deleteAvailabilities({
    required String token,
    required List<String> ids,
  }) async {
    await _dio.delete(
      baseUrl,
      data: ids,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<List<AvailabilitySummary>> findByDay({
    required String token,
    required String professionalId,
    required String day,
  }) async {
    final response = await _dio.get(
      '$baseUrl/by-day',
      queryParameters: {'professionalId': professionalId, 'day': day},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final raw = response.data;

    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map(
          (item) =>
              AvailabilitySummary.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}

class AvailabilitySearchFilters {
  final String search;
  final String professionalId;
  final String dayWeek;
  final String companyId;

  const AvailabilitySearchFilters({
    this.search = '',
    this.professionalId = '',
    this.dayWeek = '',
    this.companyId = '',
  });

  bool get hasAdvancedFilters {
    return professionalId.isNotEmpty ||
        dayWeek.isNotEmpty ||
        companyId.isNotEmpty;
  }

  AvailabilitySearchFilters copyWith({
    String? search,
    String? professionalId,
    String? dayWeek,
    String? companyId,
  }) {
    return AvailabilitySearchFilters(
      search: search ?? this.search,
      professionalId: professionalId ?? this.professionalId,
      dayWeek: dayWeek ?? this.dayWeek,
      companyId: companyId ?? this.companyId,
    );
  }
}

class AvailabilityPage {
  final List<AvailabilitySummary> content;

  final int number;
  final int totalPages;

  final bool first;
  final bool last;

  AvailabilityPage({
    required this.content,
    required this.number,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  factory AvailabilityPage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];

    return AvailabilityPage(
      content: rawContent is List
          ? rawContent
                .whereType<Map>()
                .map(
                  (item) => AvailabilitySummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
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

class AvailabilitySummary {
  final String id;
  final String professionalId;
  final String professionalName;
  final String dayWeek;
  final String startTime;
  final String endTime;
  final String companyId;

  AvailabilitySummary({
    required this.id,
    required this.professionalId,
    required this.professionalName,
    required this.dayWeek,
    required this.startTime,
    required this.endTime,
    required this.companyId,
  });

  factory AvailabilitySummary.fromJson(Map<String, dynamic> json) {
    return AvailabilitySummary(
      id: json['id']?.toString() ?? '',
      professionalId: json['professionalId']?.toString() ?? '',
      professionalName: json['name']?.toString() ?? '',
      dayWeek: json['dayWeek']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
    );
  }
}

class AvailabilityRequest {
  final String professionalId;
  final String dayWeek;
  final String startTime;
  final String endTime;
  final String companyId;

  AvailabilityRequest({
    required this.professionalId,
    required this.dayWeek,
    required this.startTime,
    required this.endTime,
    required this.companyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'professionalId': professionalId,
      'dayWeek': dayWeek,
      'startTime': startTime,
      'endTime': endTime,
      if (companyId.isNotEmpty) 'companyId': companyId,
    };
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
