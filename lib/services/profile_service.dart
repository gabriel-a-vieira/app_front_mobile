import 'package:dio/dio.dart';
import 'package:app_front_mobile/config/api_client.dart';

class ProfileService {
  ProfileService({Dio? dio, required this.baseUrl}) : _dio = dio ?? ApiClient.dio;

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

  Future<MyProfile> findMyProfile({required String token}) async {
    final response = await _dio.get(
      '$baseUrl/profile/me',
      options: _auth(token),
    );

    return MyProfile.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<MyProfile> updateMyProfile({
    required String token,
    required UpdateMyProfileRequest request,
  }) async {
    final response = await _dio.put(
      '$baseUrl/profile/me',
      data: request.toJson(),
      options: _auth(token),
    );

    return MyProfile.fromJson(Map<String, dynamic>.from(response.data));
  }
}

class MyProfile {
  final String userId;
  final String name;
  final String email;
  final String role;

  final String? personId;

  final String? cpfCnpj;
  final String? phone;
  final DateTime? birthDate;
  final String? gender;

  final String? street;
  final String? number;
  final String? postalCode;
  final String? complement;
  final String? neighborhood;

  final double? latitude;
  final double? longitude;

  final String? city;
  final String? state;

  final bool googleLinked;
  final bool personalDataCompleted;

  const MyProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.personId,
    required this.cpfCnpj,
    required this.phone,
    required this.birthDate,
    required this.gender,
    required this.street,
    required this.number,
    required this.postalCode,
    required this.complement,
    required this.neighborhood,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.googleLinked,
    required this.personalDataCompleted,
  });

  factory MyProfile.fromJson(Map<String, dynamic> json) {
    final rawBirthDate = json['birthDate']?.toString();

    return MyProfile(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      personId: json['personId']?.toString(),
      cpfCnpj: json['cpfCnpj']?.toString(),
      phone: json['phone']?.toString(),
      birthDate: rawBirthDate == null || rawBirthDate.isEmpty
          ? null
          : DateTime.tryParse(rawBirthDate),
      gender: json['gender']?.toString(),

      street: json['street']?.toString(),
      number: json['number']?.toString(),
      postalCode: json['postalCode']?.toString(),
      complement: json['complement']?.toString(),
      neighborhood: json['neighborhood']?.toString(),

      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),

      city: json['city']?.toString(),
      state: json['state']?.toString(),

      googleLinked: json['googleLinked'] == true,

      personalDataCompleted: json['personalDataCompleted'] == true,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}

class UpdateMyProfileRequest {
  final String name;

  final String cpfCnpj;
  final String phone;
  final DateTime? birthDate;
  final String? gender;

  final String street;
  final String number;
  final String postalCode;
  final String complement;
  final String neighborhood;

  final double? latitude;
  final double? longitude;

  final String city;
  final String state;

  const UpdateMyProfileRequest({
    required this.name,
    required this.cpfCnpj,
    required this.phone,
    required this.birthDate,
    required this.gender,
    required this.street,
    required this.number,
    required this.postalCode,
    required this.complement,
    required this.neighborhood,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cpfCnpj': cpfCnpj,
      'phone': phone,
      'birthDate': birthDate == null ? null : _dateOnly(birthDate!),
      'gender': gender,

      'street': street,
      'number': number,
      'postalCode': postalCode,
      'complement': complement,
      'neighborhood': neighborhood,

      'latitude': latitude,
      'longitude': longitude,

      'city': city,
      'state': state,
    };
  }

  static String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
