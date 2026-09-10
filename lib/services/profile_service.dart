import 'package:dio/dio.dart';

class ProfileService {
  ProfileService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

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
    required this.googleLinked,
    required this.personalDataCompleted,
  });

  factory MyProfile.fromJson(Map<String, dynamic> json) {
    DateTime? birthDate;

    final rawBirthDate = json['birthDate']?.toString();

    if (rawBirthDate != null && rawBirthDate.isNotEmpty) {
      birthDate = DateTime.tryParse(rawBirthDate);
    }

    return MyProfile(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      personId: json['personId']?.toString(),
      cpfCnpj: json['cpfCnpj']?.toString(),
      phone: json['phone']?.toString(),
      birthDate: birthDate,
      gender: json['gender']?.toString(),
      googleLinked: json['googleLinked'] == true,
      personalDataCompleted: json['personalDataCompleted'] == true,
    );
  }
}

class UpdateMyProfileRequest {
  final String name;

  final String cpfCnpj;

  final String phone;

  final DateTime? birthDate;

  final String? gender;

  const UpdateMyProfileRequest({
    required this.name,
    required this.cpfCnpj,
    required this.phone,
    required this.birthDate,
    required this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cpfCnpj': cpfCnpj,
      'phone': phone,
      'birthDate': birthDate == null ? null : _dateOnly(birthDate!),
      'gender': gender,
    };
  }

  static String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
