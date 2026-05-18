import 'package:dio/dio.dart';

class CompanyService {
  CompanyService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

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
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid companies response');
    }

    return CompanyPage.fromJson(data);
  }

  Future<void> createCompany({
    required String token,
    required CreateCompanyRequest request,
  }) async {
    final response = await _dio.post(
      baseUrl,
      data: request.toJson(),
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Erro ao cadastrar empresa. Status: ${response.statusCode}',
      );
    }
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

class CreateCompanyRequest {
  final String legalName;
  final String tradeName;
  final String cnpj;
  final String type;

  final String imageUrl;

  final String zipCode;
  final String street;
  final String number;
  final String district;
  final String city;
  final String state;
  final String complement;

  final String instagramUrl;
  final String facebookUrl;
  final String websiteUrl;
  final String tiktokUrl;

  CreateCompanyRequest({
    required this.legalName,
    required this.tradeName,
    required this.cnpj,
    required this.type,
    required this.imageUrl,
    required this.zipCode,
    required this.street,
    required this.number,
    required this.district,
    required this.city,
    required this.state,
    required this.complement,
    required this.instagramUrl,
    required this.facebookUrl,
    required this.websiteUrl,
    required this.tiktokUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'legalName': legalName,
      'tradeName': tradeName,
      'cnpj': cnpj,
      'type': type,
      'imageUrl': imageUrl,
      'zipCode': zipCode,
      'street': street,
      'number': number,
      'district': district,
      'city': city,
      'state': state,
      'complement': complement,
      'instagramUrl': instagramUrl,
      'facebookUrl': facebookUrl,
      'websiteUrl': websiteUrl,
      'tiktokUrl': tiktokUrl,
    };
  }
}

class CompanyTypeOption {
  final String code;
  final String label;

  CompanyTypeOption({required this.code, required this.label});

  factory CompanyTypeOption.fromJson(Map json) {
    return CompanyTypeOption(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}
