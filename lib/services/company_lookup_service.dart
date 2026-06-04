import 'package:dio/dio.dart';

class CompanyLookupService {
  CompanyLookupService({
    Dio? dio,
    required this.baseUrl,
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<CompanyLookupPage> findCompanies({
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
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return CompanyLookupPage.fromJson(response.data);
  }
}

class CompanyLookupPage {
  final List<CompanyLookupOption> content;
  final int number;
  final int totalPages;
  final bool first;
  final bool last;

  CompanyLookupPage({
    required this.content,
    required this.number,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  factory CompanyLookupPage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];

    return CompanyLookupPage(
      content: rawContent is List
          ? rawContent
              .whereType<Map>()
              .map((item) => CompanyLookupOption.fromJson(item))
              .toList()
          : [],
      number: json['number'] is int ? json['number'] : 0,
      totalPages: json['totalPages'] is int ? json['totalPages'] : 1,
      first: json['first'] == true,
      last: json['last'] == true,
    );
  }
}

class CompanyLookupOption {
  final String id;
  final String tradeName;
  final String legalName;
  final String cnpj;
  final String type;
  final String status;

  CompanyLookupOption({
    required this.id,
    required this.tradeName,
    required this.legalName,
    required this.cnpj,
    required this.type,
    required this.status,
  });

  factory CompanyLookupOption.fromJson(Map json) {
    return CompanyLookupOption(
      id: json['id']?.toString() ?? '',
      tradeName: json['tradeName']?.toString() ?? '',
      legalName: json['legalName']?.toString() ?? '',
      cnpj: json['cnpj']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  String get displayName {
    if (tradeName.isNotEmpty) return tradeName;
    if (legalName.isNotEmpty) return legalName;

    return 'Empresa sem nome';
  }
}