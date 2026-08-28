import 'package:dio/dio.dart';

class ProfessionalLookupService {
  ProfessionalLookupService({Dio? dio, required this.baseUrl})
    : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<ProfessionalLookupPage> findProfessionals({
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
        if (search.isNotEmpty) 'search': search,
        if (companyId.isNotEmpty) 'companyId': companyId,

        // se o endpoint aceitar status,
        // deixa o lookup somente com ativos
        'status': 'ACTIVE',
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ProfessionalLookupPage.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

class ProfessionalLookupPage {
  final List<ProfessionalLookupOption> content;

  final int number;
  final int totalPages;

  final bool first;
  final bool last;

  ProfessionalLookupPage({
    required this.content,
    required this.number,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  factory ProfessionalLookupPage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];

    return ProfessionalLookupPage(
      content: rawContent is List
          ? rawContent
                .whereType<Map>()
                .map(
                  (item) => ProfessionalLookupOption.fromJson(
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

class ProfessionalLookupOption {
  final String id;
  final String name;
  final String cpfCnpj;
  final String companyId;

  ProfessionalLookupOption({
    required this.id,
    required this.name,
    required this.cpfCnpj,
    required this.companyId,
  });

  factory ProfessionalLookupOption.fromJson(Map<String, dynamic> json) {
    return ProfessionalLookupOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      cpfCnpj: json['cpfCnpj']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
