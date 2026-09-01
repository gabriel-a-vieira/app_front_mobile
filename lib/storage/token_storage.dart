import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class TokenStorage {
  
  static const _storage = FlutterSecureStorage();
  static const _kAccessToken = 'access_token';

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _kAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _kAccessToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccessToken);
  }

  Future<void> clearAccessToken() async {
    await _storage.delete(key: _kAccessToken);
  }

  Future<bool> isAccessTokenValid() async {
    final token = await getAccessToken();

    if (token == null || token.trim().isEmpty) {
      return false;
    }

    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        await clearAccessToken();
        return false;
      }

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      if (payload is! Map) {
        await clearAccessToken();
        return false;
      }

      final exp = payload['exp'];

      if (exp == null) {
        await clearAccessToken();
        return false;
      }

      final expiration = DateTime.fromMillisecondsSinceEpoch(
        (exp as num).toInt() * 1000,
      );

      final valid = expiration.isAfter(DateTime.now());

      if (!valid) {
        await clearAccessToken();
      }

      return valid;
    } catch (_) {
      await clearAccessToken();
      return false;
    }
  }

}
