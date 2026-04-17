class AppConfig {
  static const backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const frontendBaseUrl = String.fromEnvironment(
    'FRONTEND_BASE_URL',
    defaultValue: 'https://sonora.spotpromo.com.br',
  );

  static const hostedFrontendEnabled = bool.fromEnvironment(
    'HOSTED_FRONTEND_ENABLED',
    defaultValue: true,
  );

  static const authEnabled = bool.fromEnvironment(
    'AUTH_ENABLED',
    defaultValue: true,
  );
}
