class AppConfig {
  static const backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const authEnabled = bool.fromEnvironment(
    'AUTH_ENABLED',
    defaultValue: true,
  );
}
