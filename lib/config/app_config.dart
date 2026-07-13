class AppConfig {
  AppConfig._();

  // LOCAL DEV: adb reverse tcp:8080 tcp:80 → device localhost:8080 = PC Apache port 80
  static const String apiBaseUrl = 'http://localhost:8080/api/v1';

  // Slug is auto-discovered at login via GET /api/v1/find-hospital
  // and restored from SharedPreferences on app restart.
  static String slug = '';

  static String hospitalName = 'Eye-SaaS HMS';

  static String get hospitalApiUrl => '$apiBaseUrl/$slug';

  static const Duration requestTimeout = Duration(seconds: 30);
}
