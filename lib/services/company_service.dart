import 'package:dio/dio.dart';

class CompanyService {
  CompanyService({
    Dio? dio,
    required this.baseUrl,
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<CompanyPage> findCompanies({
    int page = 0,
    int size = 8,
    String? type,
    String? search,
  }) async {
    final response = await _dio.get(
      '$baseUrl/companies/home-page',
      queryParameters: {
        'page': page,
        'size': size,
        if (type != null && type.isNotEmpty) 'type': type,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid companies response');
    }

    return CompanyPage.fromJson(data);
  }

  Future<List<CompanyTypeOption>> findCompanyTypes() async {
    final response = await _dio.get('$baseUrl/companies/types');

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid company types response');
    }

    return data
        .whereType<Map>()
        .map((item) => CompanyTypeOption.fromJson(item))
        .toList();
  }
}

class CompanyPage {
  final List<CompanySummary> content;
  final int number;
  final int totalPages;
  final bool last;

  CompanyPage({
    required this.content,
    required this.number,
    required this.totalPages,
    required this.last,
  });

  factory CompanyPage.fromJson(Map json) {
    final contentData = json['content'];

    return CompanyPage(
      content: contentData is List
          ? contentData
              .whereType<Map>()
              .map((item) => CompanySummary.fromJson(item))
              .toList()
          : [],
      number: json['number'] is int ? json['number'] as int : 0,
      totalPages: json['totalPages'] is int ? json['totalPages'] as int : 0,
      last: json['last'] is bool ? json['last'] as bool : true,
    );
  }
}

class CompanySummary {
  final int id;
  final String legalName;
  final String tradeName;
  final String type;
  final String typeLabel;
  final String status;

  CompanySummary({
    required this.id,
    required this.legalName,
    required this.tradeName,
    required this.type,
    required this.typeLabel,
    required this.status,
  });

  factory CompanySummary.fromJson(Map json) {
    return CompanySummary(
      id: json['id'] is int ? json['id'] as int : 0,
      legalName: json['legalName']?.toString() ?? '',
      tradeName: json['tradeName']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      typeLabel: json['typeLabel']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class CompanyTypeOption {
  final String code;
  final String label;

  CompanyTypeOption({
    required this.code,
    required this.label,
  });

  factory CompanyTypeOption.fromJson(Map json) {
    return CompanyTypeOption(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}