import 'dart:typed_data';

import 'package:dio/dio.dart';

class CompanyReviewService {
  CompanyReviewService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<CompanyReviewPage> findPublic({
    required String companyId,
    int page = 0,
    int size = 10,
  }) async {
    final response = await _dio.get(
      '$baseUrl/public/company/$companyId/reviews',
      queryParameters: {'page': page, 'size': size},
    );

    return CompanyReviewPage.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<CompanyReviewSummary> findSummary({required String companyId}) async {
    final response = await _dio.get(
      '$baseUrl/public/company/$companyId/review-summary',
    );

    return CompanyReviewSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<String> uploadImage({
    required String token,
    required Uint8List bytes,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });

    final response = await _dio.post(
      '$baseUrl/company-review/image',
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data['url']?.toString() ?? '';
  }

  Future<void> create({
    required String token,
    required String companyId,
    required int rating,
    required String comment,
    String imageUrl = '',
  }) async {
    await _dio.post(
      '$baseUrl/company-review',
      data: {
        'companyId': companyId,
        'rating': rating,
        'comment': comment,
        if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}

class CompanyReviewPage {
  final List<CompanyReviewItem> content;
  final bool last;

  const CompanyReviewPage({required this.content, required this.last});

  factory CompanyReviewPage.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];

    return CompanyReviewPage(
      content: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) => CompanyReviewItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : [],
      last: json['last'] == true,
    );
  }
}

class CompanyReviewItem {
  final String id;
  final String authorName;
  final int rating;
  final String comment;
  final String imageUrl;
  final String createdAt;

  const CompanyReviewItem({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.imageUrl,
    required this.createdAt,
  });

  factory CompanyReviewItem.fromJson(Map<String, dynamic> json) {
    return CompanyReviewItem(
      id: json['id']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? 'Cliente',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class CompanyReviewSummary {
  final double average;
  final int total;

  const CompanyReviewSummary({required this.average, required this.total});

  factory CompanyReviewSummary.fromJson(Map<String, dynamic> json) {
    return CompanyReviewSummary(
      average: (json['average'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}
