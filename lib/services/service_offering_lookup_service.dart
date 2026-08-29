import 'package:dio/dio.dart';

class ServiceOfferingLookupService {
  ServiceOfferingLookupService({Dio? dio, required this.baseUrl})
    : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<ServiceOfferingLookupPage> findServices({
    required String token,
    required int page,
    required int size,
    String search = '',
    String companyId = '',
  }) async {
    final response = await _dio.get(
      baseUrl,
      queryParameters: {
        'page': page,
        'size': size,
        'status': 'ACTIVE',

        if (search.isNotEmpty) 'search': search,

        if (companyId.isNotEmpty) 'companyId': companyId,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ServiceOfferingLookupPage.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

class ServiceOfferingLookupPage {
  final List<ServiceOfferingLookupOption> content;

  final int number;
  final int totalPages;
  final bool first;
  final bool last;

  ServiceOfferingLookupPage({
    required this.content,
    required this.number,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  factory ServiceOfferingLookupPage.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];

    return ServiceOfferingLookupPage(
      content: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) => ServiceOfferingLookupOption.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : [],
      number: _int(json['number']),
      totalPages: _int(json['totalPages']),
      first: json['first'] == true,
      last: json['last'] == true,
    );
  }
}

class ServiceOfferingLookupOption {
  final String id;
  final String name;
  final int durationMinutes;
  final double price;
  final String companyId;

  ServiceOfferingLookupOption({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.companyId,
  });

  factory ServiceOfferingLookupOption.fromJson(Map<String, dynamic> json) {
    return ServiceOfferingLookupOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      durationMinutes: _int(json['durationMinutes']),
      price: _double(json['price']),
      companyId: json['companyId']?.toString() ?? '',
    );
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}
