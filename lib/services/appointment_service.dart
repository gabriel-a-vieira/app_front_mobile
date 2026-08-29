import 'package:dio/dio.dart';

class AppointmentService {
  AppointmentService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<AppointmentPage> findAll({
    required String token,
    required int page,
    required int size,
    AppointmentSearchFilters filters = const AppointmentSearchFilters(),
  }) async {
    final response = await _dio.get(
      baseUrl,
      queryParameters: {
        'page': page,
        'size': size,
        if (filters.search.isNotEmpty) 'search': filters.search,
        if (filters.status.isNotEmpty) 'status': filters.status,
        if (filters.clientId.isNotEmpty) 'clientId': filters.clientId,
        if (filters.professionalId.isNotEmpty)
          'professionalId': filters.professionalId,
        if (filters.companyId.isNotEmpty) 'companyId': filters.companyId,
        if (filters.dateFrom.isNotEmpty) 'dateFrom': filters.dateFrom,
        if (filters.dateTo.isNotEmpty) 'dateTo': filters.dateTo,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return AppointmentPage.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AppointmentSummary> findById({
    required String token,
    required String id,
  }) async {
    final response = await _dio.get(
      '$baseUrl/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return AppointmentSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> createAppointment({
    required String token,
    required AppointmentRequest request,
  }) async {
    await _dio.post(
      baseUrl,
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> updateAppointment({
    required String token,
    required String id,
    required AppointmentRequest request,
  }) async {
    await _dio.put(
      '$baseUrl/$id',
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> cancelAppointments({
    required String token,
    required List<String> ids,
  }) async {
    await _dio.delete(
      baseUrl,
      data: ids,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<List<String>> findAvailableSlots({
    required String token,
    required String professionalId,
    required String date,
    required List<String> serviceIds,
    String companyId = '',
    String ignoreAppointmentId = '',
  }) async {
    final response = await _dio.get(
      '$baseUrl/available-slots',
      queryParameters: {
        'professionalId': professionalId,
        'date': date,

        // Spring converte o valor separado
        // por virgula para List<String>.
        'serviceIds': serviceIds.join(','),

        if (companyId.isNotEmpty) 'companyId': companyId,

        if (ignoreAppointmentId.isNotEmpty)
          'ignoreAppointmentId': ignoreAppointmentId,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final raw = response.data;

    if (raw is! List) {
      return [];
    }

    return raw.map((value) => value.toString()).toList();
  }
}

class AppointmentSearchFilters {
  final String search;
  final String status;
  final String clientId;
  final String professionalId;
  final String companyId;
  final String dateFrom;
  final String dateTo;

  const AppointmentSearchFilters({
    this.search = '',
    this.status = '',
    this.clientId = '',
    this.professionalId = '',
    this.companyId = '',
    this.dateFrom = '',
    this.dateTo = '',
  });

  bool get hasAdvancedFilters {
    return status.isNotEmpty ||
        clientId.isNotEmpty ||
        professionalId.isNotEmpty ||
        companyId.isNotEmpty ||
        dateFrom.isNotEmpty ||
        dateTo.isNotEmpty;
  }

  AppointmentSearchFilters copyWith({
    String? search,
    String? status,
    String? clientId,
    String? professionalId,
    String? companyId,
    String? dateFrom,
    String? dateTo,
  }) {
    return AppointmentSearchFilters(
      search: search ?? this.search,
      status: status ?? this.status,
      clientId: clientId ?? this.clientId,
      professionalId: professionalId ?? this.professionalId,
      companyId: companyId ?? this.companyId,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }
}

class AppointmentPage {
  final List<AppointmentSummary> content;
  final int number;
  final int totalPages;
  final bool first;
  final bool last;

  AppointmentPage({
    required this.content,
    required this.number,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  factory AppointmentPage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];

    return AppointmentPage(
      content: rawContent is List
          ? rawContent
                .whereType<Map>()
                .map(
                  (item) => AppointmentSummary.fromJson(
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

class AppointmentSummary {
  final String id;

  final String clientId;
  final String clientName;

  final String professionalId;
  final String professionalName;

  final String startAt;
  final String endAt;

  final String status;
  final String companyId;

  final List<AppointmentServiceSummary> services;

  AppointmentSummary({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.professionalId,
    required this.professionalName,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.companyId,
    required this.services,
  });

  factory AppointmentSummary.fromJson(Map<String, dynamic> json) {
    final rawServices = json['services'];

    return AppointmentSummary(
      id: json['id']?.toString() ?? '',
      clientId: json['clientId']?.toString() ?? '',
      clientName: json['clientName']?.toString() ?? '',
      professionalId: json['professionalId']?.toString() ?? '',
      professionalName: json['professionalName']?.toString() ?? '',
      startAt: json['startAt']?.toString() ?? '',
      endAt: json['endAt']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      services: rawServices is List
          ? rawServices
                .whereType<Map>()
                .map(
                  (item) => AppointmentServiceSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : [],
    );
  }
}

class AppointmentServiceSummary {
  final String serviceOfferingId;
  final String name;
  final int durationMinutes;
  final double price;
  final int executionOrder;

  AppointmentServiceSummary({
    required this.serviceOfferingId,
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.executionOrder,
  });

  factory AppointmentServiceSummary.fromJson(Map<String, dynamic> json) {
    return AppointmentServiceSummary(
      serviceOfferingId: json['serviceOfferingId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      durationMinutes: _toInt(json['durationMinutes']),
      price: _toDouble(json['price']),
      executionOrder: _toInt(json['executionOrder']),
    );
  }
}

class AppointmentRequest {
  final String clientId;
  final String professionalId;
  final String startAt;
  final List<String> serviceIds;
  final String companyId;
  final String? status;

  AppointmentRequest({
    required this.clientId,
    required this.professionalId,
    required this.startAt,
    required this.serviceIds,
    required this.companyId,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'professionalId': professionalId,
      'startAt': startAt,
      'serviceIds': serviceIds,

      if (companyId.isNotEmpty) 'companyId': companyId,

      if (status != null && status!.isNotEmpty) 'status': status,
    };
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}
