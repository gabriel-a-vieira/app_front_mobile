import 'package:dio/dio.dart';

class ServiceOfferingService {
  ServiceOfferingService({Dio? dio, required this.baseUrl})
    : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<ServiceOfferingPage> findAll({
    required String token,
    required int page,
    required int size,
    ServiceOfferingSearchFilters filters = const ServiceOfferingSearchFilters(),
  }) async {
    final response = await _dio.get(
      baseUrl,
      queryParameters: {
        'page': page,
        'size': size,
        if (filters.search.isNotEmpty) 'search': filters.search,
        if (filters.status.isNotEmpty) 'status': filters.status,
        if (filters.companyId.isNotEmpty) 'companyId': filters.companyId,
        if (filters.minDuration != null) 'minDuration': filters.minDuration,
        if (filters.maxDuration != null) 'maxDuration': filters.maxDuration,
        if (filters.minPrice != null) 'minPrice': filters.minPrice,
        if (filters.maxPrice != null) 'maxPrice': filters.maxPrice,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ServiceOfferingPage.fromJson(response.data);
  }

  Future<ServiceOfferingSummary> findById({
    required String token,
    required String id,
  }) async {
    final response = await _dio.get(
      '$baseUrl/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ServiceOfferingSummary.fromJson(response.data);
  }

  Future<void> createService({
    required String token,
    required ServiceOfferingRequest request,
  }) async {
    await _dio.post(
      baseUrl,
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> updateService({
    required String token,
    required String id,
    required ServiceOfferingRequest request,
  }) async {
    await _dio.put(
      '$baseUrl/$id',
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> deleteServices({
    required String token,
    required List<String> ids,
  }) async {
    await _dio.delete(
      baseUrl,
      data: ids,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}

class ServiceOfferingSearchFilters {
  final String search;
  final String status;
  final String companyId;

  final int? minDuration;
  final int? maxDuration;

  final double? minPrice;
  final double? maxPrice;

  const ServiceOfferingSearchFilters({
    this.search = '',
    this.status = 'ACTIVE',
    this.companyId = '',
    this.minDuration,
    this.maxDuration,
    this.minPrice,
    this.maxPrice,
  });

  bool get hasAdvancedFilters {
    return status != 'ACTIVE' ||
        companyId.isNotEmpty ||
        minDuration != null ||
        maxDuration != null ||
        minPrice != null ||
        maxPrice != null;
  }

  ServiceOfferingSearchFilters copyWith({
    String? search,
    String? status,
    String? companyId,
    int? minDuration,
    int? maxDuration,
    double? minPrice,
    double? maxPrice,
    bool clearMinDuration = false,
    bool clearMaxDuration = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return ServiceOfferingSearchFilters(
      search: search ?? this.search,
      status: status ?? this.status,
      companyId: companyId ?? this.companyId,

      minDuration: clearMinDuration ? null : minDuration ?? this.minDuration,

      maxDuration: clearMaxDuration ? null : maxDuration ?? this.maxDuration,

      minPrice: clearMinPrice ? null : minPrice ?? this.minPrice,

      maxPrice: clearMaxPrice ? null : maxPrice ?? this.maxPrice,
    );
  }
}

class ServiceOfferingPage {
  final List<ServiceOfferingSummary> content;

  final int number;
  final int totalPages;

  final bool first;
  final bool last;

  ServiceOfferingPage({
    required this.content,
    required this.number,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  factory ServiceOfferingPage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];

    return ServiceOfferingPage(
      content: rawContent is List
          ? rawContent
                .whereType<Map>()
                .map((item) => ServiceOfferingSummary.fromJson(item))
                .toList()
          : [],
      number: _toInt(json['number']) ?? 0,
      totalPages: _toInt(json['totalPages']) ?? 0,
      first: json['first'] == true,
      last: json['last'] == true,
    );
  }
}

class ServiceOfferingSummary {
  final String id;
  final String name;
  final String description;

  final int durationMinutes;
  final double price;

  final String status;
  final String companyId;

  ServiceOfferingSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
    required this.status,
    required this.companyId,
  });

  factory ServiceOfferingSummary.fromJson(Map json) {
    return ServiceOfferingSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      durationMinutes: _toInt(json['durationMinutes']) ?? 0,
      price: _toDouble(json['price']) ?? 0,
      status: json['status']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
    );
  }
}

class ServiceOfferingRequest {
  final String name;
  final String description;

  final int durationMinutes;
  final double price;

  final String status;
  final String? companyId;

  ServiceOfferingRequest({
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
    required this.status,
    this.companyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'durationMinutes': durationMinutes,
      'price': price,
      'status': status,

      if (companyId != null && companyId!.isNotEmpty) 'companyId': companyId,
    };
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;

  if (value is int) return value;

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;

  if (value is double) return value;

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString().replaceAll(',', '.'));
}
