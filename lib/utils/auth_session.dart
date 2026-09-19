import 'package:app_front_mobile/config/api_config.dart';
import 'package:app_front_mobile/services/permission_service.dart';
import 'package:app_front_mobile/services/profile_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/auth_gate.dart';
import 'package:app_front_mobile/utils/user_permissions.dart';
import 'package:flutter/foundation.dart';

/// Single funnel for "the session changed" - a login (local or Google, from
/// any screen: the header's own modal, or a login prompt opened by
/// AuthGate.requireLogin from a booking/review/etc. flow), a manual logout,
/// or the backend rejecting the stored token (expired, DB reset, user
/// removed - see ApiClient's 401 interceptor).
///
/// Every place that saves or clears the access token should go through
/// [login]/[invalidate] instead of touching [TokenStorage] directly, so any
/// widget that displays logged-in state (e.g. AppHeader) can listen to
/// [sessionChanged] once and stay correct, instead of every login entry
/// point needing to remember to notify it by hand.
class AuthSession {
  AuthSession._();

  static final TokenStorage _tokenStorage = TokenStorage();
  static final ProfileService _profileService = ProfileService(
    baseUrl: ApiConfig.baseUrl,
  );
  static final PermissionService _permissionService = PermissionService(
    baseUrl: '${ApiConfig.baseUrl}/permission',
  );

  static final ValueNotifier<int> sessionChanged = ValueNotifier<int>(0);

  /// Last profile fetched by [refreshProfile], so a freshly-mounted AppHeader
  /// (every page gets its own instance) can paint the right name/role
  /// immediately instead of showing a blank/logged-out flash while it
  /// refreshes in the background.
  static String? cachedFirstName;
  static String? cachedRole;

  static Future<void> login(String token) async {
    await _tokenStorage.saveAccessToken(token);
    sessionChanged.value++;
  }

  static Future<void> invalidate() async {
    await _tokenStorage.clearAccessToken();
    sessionChanged.value++;
  }

  /// Re-fetches the logged-in user's name/role and permission matrix (or
  /// clears the cache when logged out), used by every AppHeader instance so
  /// the fetch logic lives in one place instead of being copied per page.
  /// Returns true when the cached name/role actually changed, so a caller
  /// like HomePage can decide whether it needs to reload data that depends
  /// on login state (e.g. the favorites filter).
  static Future<bool> refreshProfile() async {
    final authenticated = await AuthGate.isAuthenticated();

    if (!authenticated) {
      final changed = cachedFirstName != null || cachedRole != null;

      cachedFirstName = null;
      cachedRole = null;
      UserPermissions.clear();

      return changed;
    }

    final token = await _tokenStorage.getAccessToken();
    if (token == null) return false;

    try {
      final profile = await _profileService.findMyProfile(token: token);

      final changed =
          cachedFirstName != profile.firstName || cachedRole != profile.role;

      cachedFirstName = profile.firstName;
      cachedRole = profile.role;

      try {
        final permissions = await _permissionService.findMyPermissions(
          token: token,
        );
        UserPermissions.update(permissions);
      } catch (_) {
        // Fail-open, same reasoning as UserPermissions.can(): a failed
        // fetch here shouldn't block the page from rendering.
      }

      return changed;
    } catch (_) {
      await _tokenStorage.clearAccessToken();
      return false;
    }
  }
}
