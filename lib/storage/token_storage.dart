import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
}