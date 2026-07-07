import 'package:dio/dio.dart';

class ClientService {
  ClientService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<ClientPage> findAll({
    required String token,
    required int page,
    required int size,
    ClientSearchFilters filters = const ClientSearchFilters(),
  }) async {
    final response = await _dio.get(
      baseUrl,
      queryParameters: {
        'page': page,
        'size': size,
        if (filters.search.isNotEmpty) 'search': filters.search,
        if (filters.name.isNotEmpty) 'name': filters.name,
        if (filters.cpfCnpj.isNotEmpty) 'cpfCnpj': filters.cpfCnpj,
        if (filters.phone.isNotEmpty) 'phone': filters.phone,
        if (filters.city.isNotEmpty) 'city': filters.city,
        if (filters.state.isNotEmpty) 'state': filters.state,
        if (filters.status.isNotEmpty) 'status': filters.status,
        if (filters.preferredPaymentMethod.isNotEmpty)
          'preferredPaymentMethod': filters.preferredPaymentMethod,
        if (filters.companyId.isNotEmpty) 'companyId': filters.companyId,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ClientPage.fromJson(response.data);
  }

  Future<ClientSummary> findById({
    required String token,
    required String id,
  }) async {
    final response = await _dio.get(
      '$baseUrl/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ClientSummary.fromJson(response.data);
  }

  Future<void> createClient({
    required String token,
    required ClientRequest request,
  }) async {
    await _dio.post(
      baseUrl,
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> updateClient({
    required String token,
    required String id,
    required ClientRequest request,
  }) async {
    await _dio.put(
      '$baseUrl/$id',
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> deleteClients({
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
      throw Exception('Erro ao excluir clientes');
    }
  }

  Future<List<String>> findPaymentMethods({required String token}) async {
    final response = await _dio.get(
      '$baseUrl/payment-methods',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data.map((item) => item.toString()).toList();
  }
}

class ClientSearchFilters {
  final String search;
  final String name;
  final String cpfCnpj;
  final String phone;
  final String city;
  final String state;
  final String status;
  final String preferredPaymentMethod;
  final String companyId;

  const ClientSearchFilters({
    this.search = '',
    this.name = '',
    this.cpfCnpj = '',
    this.phone = '',
    this.city = '',
    this.state = '',
    this.status = 'ACTIVE',
    this.preferredPaymentMethod = '',
    this.companyId = '',
  });

  bool get hasAdvancedFilters {
    return name.isNotEmpty ||
        cpfCnpj.isNotEmpty ||
        phone.isNotEmpty ||
        city.isNotEmpty ||
        state.isNotEmpty ||
        status != 'ACTIVE' ||
        preferredPaymentMethod.isNotEmpty ||
        companyId.isNotEmpty;
  }

  ClientSearchFilters copyWith({
    String? search,
    String? name,
    String? cpfCnpj,
    String? phone,
    String? city,
    String? state,
    String? status,
    String? preferredPaymentMethod,
    String? companyId,
  }) {
    return ClientSearchFilters(
      search: search ?? this.search,
      name: name ?? this.name,
      cpfCnpj: cpfCnpj ?? this.cpfCnpj,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      state: state ?? this.state,
      status: status ?? this.status,
      preferredPaymentMethod:
          preferredPaymentMethod ?? this.preferredPaymentMethod,
      companyId: companyId ?? this.companyId,
    );
  }
}

class ClientPage {
  final List<ClientSummary> content;
  final int number;
  final bool last;

  ClientPage({required this.content, required this.number, required this.last});

  factory ClientPage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];

    return ClientPage(
      content: rawContent is List
          ? rawContent
                .whereType<Map>()
                .map((item) => ClientSummary.fromJson(item))
                .toList()
          : [],
      number: json['number'] is int ? json['number'] : 0,
      last: json['last'] == true,
    );
  }
}

class ClientSummary {
  final String id;
  final String personId;
  final String name;
  final String cpfCnpj;
  final String phone;
  final String birthDate;
  final String gender;
  final String preferredPaymentMethod;
  final String additionalNotes;
  final String status;
  final String companyId;
  final String street;
  final String number;
  final String postalCode;
  final String complement;
  final String neighborhood;
  final String cityId;
  final String city;
  final String state;

  ClientSummary({
    required this.id,
    required this.personId,
    required this.name,
    required this.cpfCnpj,
    required this.phone,
    required this.birthDate,
    required this.gender,
    required this.preferredPaymentMethod,
    required this.additionalNotes,
    required this.status,
    required this.companyId,
    required this.street,
    required this.number,
    required this.postalCode,
    required this.complement,
    required this.neighborhood,
    required this.cityId,
    required this.city,
    required this.state,
  });

  factory ClientSummary.fromJson(Map json) {
    return ClientSummary(
      id: json['id']?.toString() ?? '',
      personId: json['personId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      cpfCnpj: json['cpfCnpj']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      birthDate: json['birthDate']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      preferredPaymentMethod: json['preferredPaymentMethod']?.toString() ?? '',
      additionalNotes: json['additionalNotes']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
      complement: json['complement']?.toString() ?? '',
      neighborhood: json['neighborhood']?.toString() ?? '',
      cityId: json['cityId']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }
}

class ClientRequest {
  final String name;
  final String cpfCnpj;
  final String phone;
  final String birthDate;
  final String gender;
  final String preferredPaymentMethod;
  final String additionalNotes;
  final String status;
  final String cityId;
  final String city;
  final String state;
  final String street;
  final String number;
  final String postalCode;
  final String complement;
  final String neighborhood;
  final String companyId;

  ClientRequest({
    required this.name,
    required this.cpfCnpj,
    required this.phone,
    required this.birthDate,
    required this.gender,
    required this.preferredPaymentMethod,
    required this.additionalNotes,
    required this.status,
    required this.cityId,
    required this.city,
    required this.state,
    required this.street,
    required this.number,
    required this.postalCode,
    required this.complement,
    required this.neighborhood,
    required this.companyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cpfCnpj': cpfCnpj,
      'phone': phone,
      if (birthDate.isNotEmpty) 'birthDate': birthDate,
      'gender': gender,
      if (preferredPaymentMethod.isNotEmpty)
        'preferredPaymentMethod': preferredPaymentMethod,
      'additionalNotes': additionalNotes,
      'status': status,
      if (companyId.isNotEmpty) 'companyId': companyId,
      'address': {
        'street': street,
        'number': number,
        'postalCode': postalCode,
        'complement': complement,
        'neighborhood': neighborhood,
        'idCity': cityId,
        'city': city,
        'state': state,
      },
    };
  }
}
