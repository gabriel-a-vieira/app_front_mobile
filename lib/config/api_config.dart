/// Central place for backend API configuration.
///
/// Every service/page used to hardcode `http://localhost:8081` on its own,
/// which meant switching environments (dev/staging/prod) required editing
/// dozens of files by hand. Point this at a different host/port instead.
class ApiConfig {
  ApiConfig._();

  /// Defined at build time, e.g.
  /// `flutter build web --dart-define=API_BASE_URL=https://api.example.com`.
  /// Falls back to the local backend when not provided.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081',
  );
}
