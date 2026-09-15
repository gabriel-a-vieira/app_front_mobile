import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:flutter/foundation.dart';

/// App-wide signal for "the stored session is no longer accepted by the
/// backend" (expired token, secret/DB reset invalidating it, user removed,
/// etc). [ApiClient] bumps [invalidationTick] whenever any request comes
/// back 401; widgets that show logged-in state (e.g. [HomePage]'s header)
/// listen to it to stay in sync instead of caching stale login state.
class AuthSession {
  AuthSession._();

  static final TokenStorage _tokenStorage = TokenStorage();

  static final ValueNotifier<int> invalidationTick = ValueNotifier<int>(0);

  static Future<void> invalidate() async {
    await _tokenStorage.clearAccessToken();
    invalidationTick.value++;
  }
}
