import 'package:dio/dio.dart';

class PublicCompanyService {
  PublicCompanyService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<List<PublicCompanyServiceOption>> findServices({
    required String companyId,
  }) async {
    final response = await _dio.get('$baseUrl/$companyId/services');

    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => PublicCompanyServiceOption.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<List<PublicCompanyProfessional>> findProfessionals({
    required String companyId,
  }) async {
    final response = await _dio.get('$baseUrl/$companyId/professionals');

    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => PublicCompanyProfessional.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<PublicCompanyDetail> findDetail({required String companyId}) async {
    final response = await _dio.get('$baseUrl/$companyId/details');

    return PublicCompanyDetail.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }
}

class PublicCompanyServiceOption {
  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final double price;

  const PublicCompanyServiceOption({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
  });

  factory PublicCompanyServiceOption.fromJson(Map<String, dynamic> json) {
    return PublicCompanyServiceOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      durationMinutes: _toInt(json['durationMinutes']),
      price: _toDouble(json['price']),
    );
  }
}

class PublicCompanyProfessional {
  final String id;
  final String name;

  const PublicCompanyProfessional({required this.id, required this.name});

  factory PublicCompanyProfessional.fromJson(Map<String, dynamic> json) {
    return PublicCompanyProfessional(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
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

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class PublicCompanyDetail {
  final String id;
  final String legalName;
  final String tradeName;
  final String imageUrl;

  final PublicCompanyAddress? address;

  final List<PublicCompanyOpeningDay> openingHours;

  final List<String> paymentMethods;

  final List<String> amenities;

  final String instagramUrl;
  final String facebookUrl;
  final String websiteUrl;
  final String tiktokUrl;

  const PublicCompanyDetail({
    required this.id,
    required this.legalName,
    required this.tradeName,
    required this.imageUrl,
    required this.address,
    required this.openingHours,
    required this.paymentMethods,
    required this.amenities,
    required this.instagramUrl,
    required this.facebookUrl,
    required this.websiteUrl,
    required this.tiktokUrl,
  });

  factory PublicCompanyDetail.fromJson(Map<String, dynamic> json) {
    final rawHours = json['openingHours'];

    final rawPayments = json['paymentMethods'];

    final rawAmenities = json['amenities'];

    return PublicCompanyDetail(
      id: json['id']?.toString() ?? '',
      legalName: json['legalName']?.toString() ?? '',
      tradeName: json['tradeName']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',

      address: json['address'] is Map
          ? PublicCompanyAddress.fromJson(
              Map<String, dynamic>.from(json['address']),
            )
          : null,

      openingHours: rawHours is List
          ? rawHours
                .whereType<Map>()
                .map(
                  (item) => PublicCompanyOpeningDay.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : [],

      paymentMethods: rawPayments is List
          ? rawPayments.map((item) => item.toString()).toList()
          : [],

      amenities: rawAmenities is List
          ? rawAmenities.map((item) => item.toString()).toList()
          : [],

      instagramUrl: json['instagramUrl']?.toString() ?? '',
      facebookUrl: json['facebookUrl']?.toString() ?? '',
      websiteUrl: json['websiteUrl']?.toString() ?? '',
      tiktokUrl: json['tiktokUrl']?.toString() ?? '',
    );
  }
}

class PublicCompanyAddress {
  final String formattedAddress;

  final double? latitude;
  final double? longitude;

  const PublicCompanyAddress({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  factory PublicCompanyAddress.fromJson(Map<String, dynamic> json) {
    return PublicCompanyAddress(
      formattedAddress: json['formattedAddress']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class PublicCompanyOpeningDay {
  final String dayWeek;

  final List<PublicCompanyTimeRange> intervals;

  const PublicCompanyOpeningDay({
    required this.dayWeek,
    required this.intervals,
  });

  factory PublicCompanyOpeningDay.fromJson(Map<String, dynamic> json) {
    final raw = json['intervals'];

    return PublicCompanyOpeningDay(
      dayWeek: json['dayWeek']?.toString() ?? '',
      intervals: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) => PublicCompanyTimeRange.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : [],
    );
  }
}

class PublicCompanyTimeRange {
  final String startTime;
  final String endTime;

  const PublicCompanyTimeRange({
    required this.startTime,
    required this.endTime,
  });

  factory PublicCompanyTimeRange.fromJson(Map<String, dynamic> json) {
    return PublicCompanyTimeRange(
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
    );
  }
}
