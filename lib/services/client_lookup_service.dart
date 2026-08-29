import 'package:dio/dio.dart';

class ClientLookupService {
  ClientLookupService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<ClientLookupPage> findClients({
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

    return ClientLookupPage.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

class ClientLookupPage {
  final List<ClientLookupOption> content;
  final int number;
  final int totalPages;
  final bool first;
  final bool last;

  ClientLookupPage({
    required this.content,
    required this.number,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  factory ClientLookupPage.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];

    return ClientLookupPage(
      content: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) => ClientLookupOption.fromJson(
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

class ClientLookupOption {
  final String id;
  final String name;
  final String cpfCnpj;
  final String companyId;

  ClientLookupOption({
    required this.id,
    required this.name,
    required this.cpfCnpj,
    required this.companyId,
  });

  factory ClientLookupOption.fromJson(Map<String, dynamic> json) {
    return ClientLookupOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      cpfCnpj: json['cpfCnpj']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
