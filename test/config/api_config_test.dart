import 'package:app_front_mobile/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('baseUrl falls back to the local backend without API_BASE_URL', () {
    expect(ApiConfig.baseUrl, 'http://localhost:8081');
  });
}
