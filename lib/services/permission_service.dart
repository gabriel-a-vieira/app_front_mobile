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

/// One editable row of the permission matrix screen: a (role, module) pair
/// plus its four CRUD flags.
class RolePermissionEntry {
  final String role;
  final SystemModule module;
  final bool canCreate;
  final bool canUpdate;
  final bool canList;
  final bool canDelete;

  const RolePermissionEntry({
    required this.role,
    required this.module,
    required this.canCreate,
    required this.canUpdate,
    required this.canList,
    required this.canDelete,
  });

  factory RolePermissionEntry.fromJson(Map<String, dynamic> json) {
    return RolePermissionEntry(
      role: json['role']?.toString() ?? '',
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
      'role': role,
      'module': module.apiValue,
      'canCreate': canCreate,
      'canUpdate': canUpdate,
      'canList': canList,
      'canDelete': canDelete,
    };
  }

  RolePermissionEntry copyWith({
    bool? canCreate,
    bool? canUpdate,
    bool? canList,
    bool? canDelete,
  }) {
    return RolePermissionEntry(
      role: role,
      module: module,
      canCreate: canCreate ?? this.canCreate,
      canUpdate: canUpdate ?? this.canUpdate,
      canList: canList ?? this.canList,
      canDelete: canDelete ?? this.canDelete,
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

  Future<List<RolePermissionEntry>> findMatrix({required String token}) async {
    final response = await _dio.get(baseUrl, options: _auth(token));

    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => RolePermissionEntry.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> updateMatrix({
    required String token,
    required List<RolePermissionEntry> entries,
  }) async {
    await _dio.put(
      baseUrl,
      data: entries.map((entry) => entry.toJson()).toList(),
      options: _auth(token),
    );
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
