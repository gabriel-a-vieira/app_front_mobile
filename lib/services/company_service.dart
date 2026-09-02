import 'package:dio/dio.dart';

class CompanyService {
  CompanyService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Options _authOptions(String token) {
    return Options(
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  /*
   * HOME PUBLICA
   */

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

    if (response.data is! Map) {
      throw Exception('Invalid companies response');
    }

    return CompanyPage.fromJson(response.data);
  }

  /*
   * ADMIN
   */

  Future<CompanyAdminPage> findAdminCompanies({
    required String token,
    int page = 0,
    int size = 10,
    String search = '',
    String type = '',
    String status = '',
  }) async {
    final response = await _dio.get(
      '$baseUrl/admin',
      queryParameters: {
        'page': page,
        'size': size,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (type.isNotEmpty) 'type': type,
        if (status.isNotEmpty) 'status': status,
      },
      options: _authOptions(token),
    );

    return CompanyAdminPage.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<CompanyDetail> findAdminById({
    required String token,
    required String id,
  }) async {
    final response = await _dio.get(
      '$baseUrl/admin/$id',
      options: _authOptions(token),
    );

    return CompanyDetail.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> createCompany({
    required String token,
    required CompanySaveRequest request,
  }) async {
    await _dio.post(
      baseUrl,
      data: request.toJson(),
      options: _authOptions(token),
    );
  }

  Future<void> updateCompany({
    required String token,
    required String id,
    required CompanySaveRequest request,
  }) async {
    await _dio.put(
      '$baseUrl/$id',
      data: request.toJson(),
      options: _authOptions(token),
    );
  }

  Future<void> deactivateCompanies({
    required String token,
    required List<String> ids,
  }) async {
    await _dio.delete(baseUrl, data: ids, options: _authOptions(token));
  }

  /*
   * OPCOES
   */

  Future<List<CompanyTypeOption>> findCompanyTypes() async {
    final response = await _dio.get('$baseUrl/companies/types');

    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((item) => CompanyTypeOption.fromJson(item))
        .toList();
  }

  Future<List<String>> findCompanyStatuses({required String token}) async {
    return _findStringList('$baseUrl/companies/statuses', token);
  }

  Future<List<String>> findPaymentMethods({required String token}) async {
    return _findStringList('$baseUrl/companies/payment-methods', token);
  }

  Future<List<String>> findAmenities({required String token}) async {
    return _findStringList('$baseUrl/companies/amenities', token);
  }

  Future<List<String>> _findStringList(String url, String token) async {
    final response = await _dio.get(url, options: _authOptions(token));

    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data.map((item) => item.toString()).toList();
  }
}

/*
 * HOME
 */

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
          ? contentData.whereType<Map>().map(CompanySummary.fromJson).toList()
          : [],
      number: _toInt(json['number']),
      totalPages: _toInt(json['totalPages']),
      last: json['last'] == true,
    );
  }
}

class CompanySummary {
  final String id;

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
      id: json['id']?.toString() ?? '',
      legalName: json['legalName']?.toString() ?? '',
      tradeName: json['tradeName']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      typeLabel: json['typeLabel']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

/*
 * ADMIN LIST
 */

class CompanyAdminPage {
  final List<CompanyAdminSummary> content;

  final int number;
  final int totalPages;
  final bool first;
  final bool last;

  const CompanyAdminPage({
    required this.content,
    required this.number,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  factory CompanyAdminPage.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];

    return CompanyAdminPage(
      content: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) => CompanyAdminSummary.fromJson(
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

class CompanyAdminSummary {
  final String id;
  final String legalName;
  final String tradeName;
  final String cnpj;
  final String type;
  final String typeLabel;
  final String status;
  final String city;
  final String state;

  const CompanyAdminSummary({
    required this.id,
    required this.legalName,
    required this.tradeName,
    required this.cnpj,
    required this.type,
    required this.typeLabel,
    required this.status,
    required this.city,
    required this.state,
  });

  factory CompanyAdminSummary.fromJson(Map<String, dynamic> json) {
    return CompanyAdminSummary(
      id: json['id']?.toString() ?? '',
      legalName: json['legalName']?.toString() ?? '',
      tradeName: json['tradeName']?.toString() ?? '',
      cnpj: json['cnpj']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      typeLabel: json['typeLabel']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }
}

/*
 * DETAIL
 */

class CompanyDetail {
  final String id;

  final String legalName;
  final String tradeName;
  final String cnpj;

  final String type;
  final String status;

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

  final List<String> paymentMethods;

  final List<String> amenities;

  final List<CompanyOpeningHourInput> openingHours;

  const CompanyDetail({
    required this.id,
    required this.legalName,
    required this.tradeName,
    required this.cnpj,
    required this.type,
    required this.status,
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
    required this.paymentMethods,
    required this.amenities,
    required this.openingHours,
  });

  factory CompanyDetail.fromJson(Map<String, dynamic> json) {
    return CompanyDetail(
      id: json['id']?.toString() ?? '',
      legalName: json['legalName']?.toString() ?? '',
      tradeName: json['tradeName']?.toString() ?? '',
      cnpj: json['cnpj']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      complement: json['complement']?.toString() ?? '',
      instagramUrl: json['instagramUrl']?.toString() ?? '',
      facebookUrl: json['facebookUrl']?.toString() ?? '',
      websiteUrl: json['websiteUrl']?.toString() ?? '',
      tiktokUrl: json['tiktokUrl']?.toString() ?? '',
      paymentMethods: _stringList(json['paymentMethods']),
      amenities: _stringList(json['amenities']),
      openingHours: json['openingHours'] is List
          ? (json['openingHours'] as List)
                .whereType<Map>()
                .map(
                  (item) => CompanyOpeningHourInput.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : [],
    );
  }
}

/*
 * REQUEST
 */

class CompanySaveRequest {
  final String legalName;
  final String tradeName;
  final String cnpj;

  final String type;
  final String status;

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

  final List<String> paymentMethods;

  final List<String> amenities;

  final List<CompanyOpeningHourInput> openingHours;

  const CompanySaveRequest({
    required this.legalName,
    required this.tradeName,
    required this.cnpj,
    required this.type,
    required this.status,
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
    required this.paymentMethods,
    required this.amenities,
    required this.openingHours,
  });

  Map<String, dynamic> toJson() {
    return {
      'legalName': legalName,
      'tradeName': tradeName,
      'cnpj': cnpj,
      'type': type,
      'status': status,
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
      'paymentMethods': paymentMethods,
      'amenities': amenities,
      'openingHours': openingHours.map((item) => item.toJson()).toList(),
    };
  }
}

class CompanyOpeningHourInput {
  final String dayWeek;
  final String startTime;
  final String endTime;

  const CompanyOpeningHourInput({
    required this.dayWeek,
    required this.startTime,
    required this.endTime,
  });

  factory CompanyOpeningHourInput.fromJson(Map<String, dynamic> json) {
    return CompanyOpeningHourInput(
      dayWeek: json['dayWeek']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'dayWeek': dayWeek, 'startTime': startTime, 'endTime': endTime};
  }
}

class CompanyTypeOption {
  final String code;
  final String label;

  const CompanyTypeOption({required this.code, required this.label});

  factory CompanyTypeOption.fromJson(Map json) {
    return CompanyTypeOption(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is! List) {
    return [];
  }

  return value.map((item) => item.toString()).toList();
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
