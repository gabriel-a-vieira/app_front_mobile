import 'package:dio/dio.dart';

class PublicProductService {
  PublicProductService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<List<PublicProduct>> findProducts({required String companyId}) async {
    final response = await _dio.get('$baseUrl/$companyId/products');

    if (response.data is! List) {
      return [];
    }

    return (response.data as List)
        .whereType<Map>()
        .map((item) => PublicProduct.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class PublicProduct {
  final String id;

  final String name;

  final String description;

  final double price;

  final int stockQuantity;

  final String imageUrl;

  const PublicProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.imageUrl,
  });

  factory PublicProduct.fromJson(Map<String, dynamic> json) {
    return PublicProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }
}
