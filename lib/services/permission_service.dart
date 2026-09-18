import 'package:dio/dio.dart';
import 'package:app_front_mobile/config/api_client.dart';
import 'package:app_front_mobile/models/system_module.dart';

class ModulePermission {
  final bool canCreate;
  final bool canUpdate;
  final bool canList;
  final bool canDelete;

  const ModulePermission({
    required this.canCreate,
    required this.canUpdate,
    required this.canList,
    required this.canDelete,
  });

  factory ModulePermission.fromJson(Map<String, dynamic> json) {
    return ModulePermission(
      canCreate: json['canCreate'] == true,
      canUpdate: json['canUpdate'] == true,
      canList: json['canList'] == true,
      canDelete: json['canDelete'] == true,
    );
  }
}

/// One row of a specific user's permission matrix.
class ModulePermissionEntry {
  final SystemModule module;
  final bool canCreate;
  final bool canUpdate;
  final bool canList;
  final bool canDelete;

  const ModulePermissionEntry({
    required this.module,
    required this.canCreate,
    required this.canUpdate,
    required this.canList,
    required this.canDelete,
  });

  factory ModulePermissionEntry.fromJson(Map<String, dynamic> json) {
    return ModulePermissionEntry(
      module:
          SystemModule.fromApiValue(json['module']?.toString() ?? '') ??
          SystemModule.client,
      canCreate: json['canCreate'] == true,
      canUpdate: json['canUpdate'] == true,
      canList: json['canList'] == true,
      canDelete: json['canDelete'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'module': module.apiValue,
      'canCreate': canCreate,
      'canUpdate': canUpdate,
      'canList': canList,
      'canDelete': canDelete,
    };
  }

  ModulePermissionEntry copyWith({
    bool? canCreate,
    bool? canUpdate,
    bool? canList,
    bool? canDelete,
  }) {
    return ModulePermissionEntry(
      module: module,
      canCreate: canCreate ?? this.canCreate,
      canUpdate: canUpdate ?? this.canUpdate,
      canList: canList ?? this.canList,
      canDelete: canDelete ?? this.canDelete,
    );
  }
}

/// One row of the permission cadastro's list: a user that already has a
/// custom permission profile configured for this company.
class PermissionProfile {
  final String userId;
  final String name;
  final String email;
  final String role;

  const PermissionProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  factory PermissionProfile.fromJson(Map<String, dynamic> json) {
    return PermissionProfile(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }
}

class PermissionProfilePage {
  final List<PermissionProfile> content;
  final int number;
  final bool last;

  PermissionProfilePage({
    required this.content,
    required this.number,
    required this.last,
  });

  factory PermissionProfilePage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];

    return PermissionProfilePage(
      content: rawContent is List
          ? rawContent
                .whereType<Map>()
                .map(
                  (item) =>
                      PermissionProfile.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : [],
      number: json['number'] is int ? json['number'] : 0,
      last: json['last'] == true,
    );
  }
}

class PermissionService {
  PermissionService({Dio? dio, required this.baseUrl})
    : _dio = dio ?? ApiClient.dio;

  final Dio _dio;
  final String baseUrl;

  Options _auth(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<PermissionProfilePage> findProfiles({
    required String token,
    required int page,
    required int size,
    String search = '',
  }) async {
    final response = await _dio.get(
      baseUrl,
      queryParameters: {
        'page': page,
        'size': size,
        if (search.isNotEmpty) 'search': search,
      },
      options: _auth(token),
    );

    return PermissionProfilePage.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<ModulePermissionEntry>> findUserMatrix({
    required String token,
    required String userId,
  }) async {
    final response = await _dio.get('$baseUrl/$userId', options: _auth(token));

    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) =>
              ModulePermissionEntry.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> updateUserMatrix({
    required String token,
    required String userId,
    required List<ModulePermissionEntry> entries,
  }) async {
    await _dio.put(
      '$baseUrl/$userId',
      data: entries.map((entry) => entry.toJson()).toList(),
      options: _auth(token),
    );
  }

  Future<void> deleteProfiles({
    required String token,
    required List<String> userIds,
  }) async {
    await _dio.delete(baseUrl, data: userIds, options: _auth(token));
  }

  Future<Map<SystemModule, ModulePermission>> findMyPermissions({
    required String token,
  }) async {
    final response = await _dio.get('$baseUrl/me', options: _auth(token));

    final data = response.data;

    if (data is! Map) {
      return {};
    }

    final result = <SystemModule, ModulePermission>{};

    data.forEach((key, value) {
      final module = SystemModule.fromApiValue(key.toString());

      if (module != null && value is Map) {
        result[module] = ModulePermission.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
    });

    return result;
  }
}
