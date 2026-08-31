import 'package:dio/dio.dart';

class CustomerAppointmentService {
  CustomerAppointmentService({Dio? dio, required this.baseUrl})
    : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<List<String>> findAvailableSlots({
    required String token,
    required String companyId,
    required String professionalId,
    required String serviceId,
    required String date,
  }) async {
    final response = await _dio.get(
      '$baseUrl/available-slots',
      queryParameters: {
        'companyId': companyId,
        'professionalId': professionalId,
        'serviceIds': serviceId,
        'date': date,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data.map((item) => item.toString()).toList();
  }

  Future<void> create({
    required String token,
    required String companyId,
    required String professionalId,
    required String serviceId,
    required String startAt,
    required String notes,
    required bool prefersSilence,
  }) async {
    await _dio.post(
      '$baseUrl/customer',
      data: {
        'companyId': companyId,
        'professionalId': professionalId,
        'serviceIds': [serviceId],
        'startAt': startAt,
        'notes': notes,
        'prefersSilence': prefersSilence,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<CustomerAppointmentPage> findMine({
    required String token,
    int page = 0,
    int size = 10,
  }) async {
    final response = await _dio.get(
      '$baseUrl/mine',
      queryParameters: {'page': page, 'size': size},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return CustomerAppointmentPage.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<CustomerAppointment> findMineById({
    required String token,
    required String id,
  }) async {
    final response = await _dio.get(
      '$baseUrl/mine/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return CustomerAppointment.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<void> cancel({required String token, required String id}) async {
    await _dio.patch(
      '$baseUrl/mine/$id/cancel',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}

class CustomerAppointmentPage {
  final List<CustomerAppointment> content;
  final bool last;

  const CustomerAppointmentPage({required this.content, required this.last});

  factory CustomerAppointmentPage.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];

    return CustomerAppointmentPage(
      content: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) => CustomerAppointment.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : [],
      last: json['last'] == true,
    );
  }
}

class CustomerAppointment {
  final String id;

  final String companyId;
  final String companyName;

  final String professionalName;

  final String startAt;
  final String endAt;

  final String status;

  final double totalPrice;

  final String notes;

  final bool prefersSilence;

  final List<CustomerAppointmentServiceItem> services;

  const CustomerAppointment({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.professionalName,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.totalPrice,
    required this.notes,
    required this.prefersSilence,
    required this.services,
  });

  factory CustomerAppointment.fromJson(Map<String, dynamic> json) {
    final raw = json['services'];

    return CustomerAppointment(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      professionalName: json['professionalName']?.toString() ?? '',
      startAt: json['startAt']?.toString() ?? '',
      endAt: json['endAt']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      notes: json['notes']?.toString() ?? '',
      prefersSilence: json['prefersSilence'] == true,
      services: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) => CustomerAppointmentServiceItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : [],
    );
  }
}

class CustomerAppointmentServiceItem {
  final String name;
  final int durationMinutes;
  final double price;

  const CustomerAppointmentServiceItem({
    required this.name,
    required this.durationMinutes,
    required this.price,
  });

  factory CustomerAppointmentServiceItem.fromJson(Map<String, dynamic> json) {
    return CustomerAppointmentServiceItem(
      name: json['name']?.toString() ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}
