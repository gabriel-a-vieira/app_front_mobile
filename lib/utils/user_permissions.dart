import 'package:app_front_mobile/models/system_module.dart';
import 'package:app_front_mobile/services/permission_service.dart';

/// Caches the logged-in user's effective permission matrix (see
/// PermissionService.findMyPermissions), refreshed by HomePage alongside the
/// role sync in _syncSessionState.
///
/// Fail-open by design: a module missing from the map (never fetched yet, or
/// the fetch failed) is treated as allowed, mirroring the backend's own
/// default-allow behavior for an unconfigured (role, module) combination -- a
/// permission-check bug should never be the reason a legitimate action gets
/// silently blocked.
class UserPermissions {
  UserPermissions._();

  static Map<SystemModule, ModulePermission> _permissions = {};

  static void update(Map<SystemModule, ModulePermission> permissions) {
    _permissions = permissions;
  }

  static void clear() {
    _permissions = {};
  }

  static bool can(SystemModule module, CrudAction action) {
    final permission = _permissions[module];

    if (permission == null) {
      return true;
    }

    switch (action) {
      case CrudAction.create:
        return permission.canCreate;
      case CrudAction.update:
        return permission.canUpdate;
      case CrudAction.list:
        return permission.canList;
      case CrudAction.delete:
        return permission.canDelete;
    }
  }
}
