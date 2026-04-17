import 'package:flutter/material.dart';

enum AppMode { hostedFrontend, nativeClient }

class AppLaunchConfig {
  const AppLaunchConfig._({
    required this.mode,
    required this.backendBaseUrl,
    required this.authEnabled,
    this.frontendUrl,
  });

  final AppMode mode;
  final String backendBaseUrl;
  final bool authEnabled;
  final String? frontendUrl;

  bool get usesHostedFrontend => mode == AppMode.hostedFrontend;

  static AppLaunchConfig resolve({
    required bool isWeb,
    required TargetPlatform targetPlatform,
    required String backendBaseUrl,
    required String frontendBaseUrl,
    required bool hostedFrontendEnabled,
    required bool authEnabled,
  }) {
    final normalizedFrontendUrl = frontendBaseUrl.trim();
    final shouldUseHostedFrontend =
        !isWeb &&
        targetPlatform == TargetPlatform.android &&
        hostedFrontendEnabled &&
        normalizedFrontendUrl.isNotEmpty;

    if (shouldUseHostedFrontend) {
      return AppLaunchConfig._(
        mode: AppMode.hostedFrontend,
        backendBaseUrl: backendBaseUrl,
        authEnabled: false,
        frontendUrl: normalizedFrontendUrl,
      );
    }

    return AppLaunchConfig._(
      mode: AppMode.nativeClient,
      backendBaseUrl: backendBaseUrl,
      authEnabled: authEnabled,
    );
  }
}
