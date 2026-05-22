import 'package:dio/dio.dart';

class ProfessionalService {
  ProfessionalService({
    Dio? dio,
    required this.baseUrl,
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<ProfessionalPage> findProfessionals({
    required String token,
    int page = 0,
    int size = 10,
    String? search,
  }) async {
    final response = await _dio.get(
      baseUrl,
      queryParameters: {
        'page': page,
        'size': size,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return ProfessionalPage.fromJson(response.data);
  }

  Future<ProfessionalSummary> findById({
    required String token,
    required String id,
  }) async {
    final response = await _dio.get(
      '$baseUrl/$id',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return ProfessionalSummary.fromJson(response.data);
  }

  Future<void> createProfessional({
    required String token,
    required ProfessionalRequest request,
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
      throw Exception('Erro ao cadastrar profissional');
    }
  }

  Future<void> updateProfessional({
    required String token,
    required String id,
    required ProfessionalRequest request,
  }) async {
    final response = await _dio.put(
      '$baseUrl/$id',
      data: request.toJson(),
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar profissional');
    }
  }

  Future<void> deleteProfessionals({
    required String token,
    required List<String> ids,
  }) async {
    final response = await _dio.delete(
      baseUrl,
      data: ids,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Erro ao excluir profissionais');
    }
  }
}

class ProfessionalPage {
  final List<ProfessionalSummary> content;
  final int number;
  final int totalPages;
  final bool last;

  ProfessionalPage({
    required this.content,
    required this.number,
    required this.totalPages,
    required this.last,
  });

  factory ProfessionalPage.fromJson(Map json) {
    final contentData = json['content'];

    return ProfessionalPage(
      content: contentData is List
          ? contentData
              .whereType<Map>()
              .map((item) => ProfessionalSummary.fromJson(item))
              .toList()
          : [],
      number: json['number'] is int ? json['number'] as int : 0,
      totalPages: json['totalPages'] is int ? json['totalPages'] as int : 0,
      last: json['last'] is bool ? json['last'] as bool : true,
    );
  }
}

class ProfessionalSummary {
  final String id;
  final String personId;
  final String name;
  final String cpfCnpj;
  final String phone;
  final String birthDate;
  final String gender;
  final String status;
  final String street;
  final String number;
  final String postalCode;
  final String complement;
  final String neighborhood;
  final String city;
  final String state;

  ProfessionalSummary({
    required this.id,
    required this.personId,
    required this.name,
    required this.cpfCnpj,
    required this.phone,
    required this.birthDate,
    required this.gender,
    required this.status,
    required this.street,
    required this.number,
    required this.postalCode,
    required this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  factory ProfessionalSummary.fromJson(Map json) {
    return ProfessionalSummary(
      id: json['id']?.toString() ?? '',
      personId: json['personId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      cpfCnpj: json['cpfCnpj']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      birthDate: json['birthDate']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
      complement: json['complement']?.toString() ?? '',
      neighborhood: json['neighborhood']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }
}

class ProfessionalRequest {
  final String name;
  final String cpfCnpj;
  final String phone;
  final String birthDate;
  final String gender;
  final String status;

  final String street;
  final String number;
  final String postalCode;
  final String complement;
  final String neighborhood;
  final String city;
  final String state;

  ProfessionalRequest({
    required this.name,
    required this.cpfCnpj,
    required this.phone,
    required this.birthDate,
    required this.gender,
    required this.status,
    required this.street,
    required this.number,
    required this.postalCode,
    required this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cpfCnpj': cpfCnpj,
      'phone': phone,
      'birthDate': birthDate.isEmpty ? null : birthDate,
      'gender': gender,
      'status': status,
      'address': {
        'street': street,
        'number': number,
        'postalCode': postalCode,
        'complement': complement,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
      },
    };
  }
}