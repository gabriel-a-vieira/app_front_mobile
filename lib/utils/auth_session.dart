import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:flutter/foundation.dart';

/// Single funnel for "the session changed" - a login (local or Google, from
/// any screen: the header's own modal, or a login prompt opened by
/// AuthGate.requireLogin from a booking/review/etc. flow), a manual logout,
/// or the backend rejecting the stored token (expired, DB reset, user
/// removed - see ApiClient's 401 interceptor).
///
/// Every place that saves or clears the access token should go through
/// [login]/[invalidate] instead of touching [TokenStorage] directly, so any
/// widget that displays logged-in state (e.g. HomePage's header) can listen
/// to [sessionChanged] once and stay correct, instead of every login entry
/// point needing to remember to notify it by hand.
class AuthSession {
  AuthSession._();

  static final TokenStorage _tokenStorage = TokenStorage();

  static final ValueNotifier<int> sessionChanged = ValueNotifier<int>(0);

  static Future<void> login(String token) async {
    await _tokenStorage.saveAccessToken(token);
    sessionChanged.value++;
  }

  static Future<void> invalidate() async {
    await _tokenStorage.clearAccessToken();
    sessionChanged.value++;
  }
}
