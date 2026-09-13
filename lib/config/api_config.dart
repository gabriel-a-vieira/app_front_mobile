/// Central place for backend API configuration.
///
/// Every service/page used to hardcode `http://localhost:8081` on its own,
/// which meant switching environments (dev/staging/prod) required editing
/// dozens of files by hand. Point this at a different host/port instead.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://localhost:8081';
}
