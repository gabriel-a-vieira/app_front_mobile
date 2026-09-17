import 'package:app_front_mobile/models/system_module.dart';
import 'package:app_front_mobile/services/permission_service.dart';
import 'package:app_front_mobile/utils/user_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers UserPermissions' fail-open behavior: a module that was never
/// fetched (or that update()/clear() never touched) reads as allowed, and
/// only an explicit false in the cached map blocks an action.
void main() {
  setUp(() {
    UserPermissions.clear();
  });

  test('a module with no cached entry is treated as fully allowed', () {
    expect(UserPermissions.can(SystemModule.client, CrudAction.create), isTrue);
    expect(UserPermissions.can(SystemModule.client, CrudAction.delete), isTrue);
  });

  test('respects an explicit false for the requested action', () {
    UserPermissions.update({
      SystemModule.client: const ModulePermission(
        canCreate: false,
        canUpdate: true,
        canList: true,
        canDelete: false,
      ),
    });

    expect(UserPermissions.can(SystemModule.client, CrudAction.create), isFalse);
    expect(UserPermissions.can(SystemModule.client, CrudAction.update), isTrue);
    expect(UserPermissions.can(SystemModule.client, CrudAction.list), isTrue);
    expect(UserPermissions.can(SystemModule.client, CrudAction.delete), isFalse);
  });

  test('a module missing from an otherwise-populated map still fails open', () {
    UserPermissions.update({
      SystemModule.client: const ModulePermission(
        canCreate: false,
        canUpdate: false,
        canList: false,
        canDelete: false,
      ),
    });

    expect(UserPermissions.can(SystemModule.product, CrudAction.delete), isTrue);
  });

  test('clear() resets back to fail-open for every module', () {
    UserPermissions.update({
      SystemModule.client: const ModulePermission(
        canCreate: false,
        canUpdate: false,
        canList: false,
        canDelete: false,
      ),
    });

    UserPermissions.clear();

    expect(UserPermissions.can(SystemModule.client, CrudAction.create), isTrue);
  });
}
