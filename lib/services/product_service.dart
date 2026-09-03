import 'package:dio/dio.dart';

class ProductService {
  ProductService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Options _auth(String token) {
    return Options(
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<ProductPage> findAll({
    required String token,
    int page = 0,
    int size = 10,
    String search = '',
    String status = '',
    double? minPrice,
    double? maxPrice,
    String? companyId,
  }) async {
    final response = await _dio.get(
      baseUrl,
      queryParameters: {
        'page': page,
        'size': size,

        if (search.trim().isNotEmpty) 'search': search.trim(),

        if (status.isNotEmpty) 'status': status,

        if (minPrice != null) 'minPrice': minPrice,

        if (maxPrice != null) 'maxPrice': maxPrice,

        if (companyId != null && companyId.isNotEmpty) 'companyId': companyId,
      },
      options: _auth(token),
    );

    return ProductPage.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<ProductSummary> findById({
    required String token,
    required String id,
  }) async {
    final response = await _dio.get('$baseUrl/$id', options: _auth(token));

    return ProductSummary.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> create({
    required String token,
    required ProductRequest request,
  }) async {
    await _dio.post(baseUrl, data: request.toJson(), options: _auth(token));
  }

  Future<void> update({
    required String token,
    required String id,
    required ProductRequest request,
  }) async {
    await _dio.put(
      '$baseUrl/$id',
      data: request.toJson(),
      options: _auth(token),
    );
  }

  Future<void> deleteMany({
    required String token,
    required List<String> ids,
    String? companyId,
  }) async {
    await _dio.delete(
      baseUrl,
      data: ids,
      queryParameters: {
        if (companyId != null && companyId.isNotEmpty) 'companyId': companyId,
      },
      options: _auth(token),
    );
  }

  Future<List<String>> findStatuses({required String token}) async {
    final response = await _dio.get('$baseUrl/statuses', options: _auth(token));

    if (response.data is! List) {
      return [];
    }

    return (response.data as List).map((item) => item.toString()).toList();
  }
}

class ProductPage {
  final List<ProductSummary> content;

  final int number;
  final int totalPages;

  final bool first;
  final bool last;

  const ProductPage({
    required this.content,
    required this.number,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  factory ProductPage.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];

    return ProductPage(
      content: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) =>
                      ProductSummary.fromJson(Map<String, dynamic>.from(item)),
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

class ProductSummary {
  final String id;

  final String companyId;
  final String companyName;

  final String name;
  final String description;

  final double price;

  final int stockQuantity;

  final String imageUrl;

  final String status;

  const ProductSummary({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.imageUrl,
    required this.status,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _toDouble(json['price']),
      stockQuantity: _toInt(json['stockQuantity']),
      imageUrl: json['imageUrl']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class ProductRequest {
  final String? companyId;

  final String name;
  final String description;

  final double price;

  final int stockQuantity;

  final String imageUrl;

  final String status;

  const ProductRequest({
    required this.companyId,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.imageUrl,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      if (companyId != null && companyId!.isNotEmpty) 'companyId': companyId,

      'name': name,

      'description': description,

      'price': price,

      'stockQuantity': stockQuantity,

      'imageUrl': imageUrl,

      'status': status,
    };
  }
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

double _toDouble(dynamic value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}
