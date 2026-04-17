import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plaude_like/app/app_launch_config.dart';

void main() {
  test('uses the PHP frontend shell on Android when configured', () {
    final config = AppLaunchConfig.resolve(
      isWeb: false,
      targetPlatform: TargetPlatform.android,
      backendBaseUrl: 'https://sonora.spotpromo.com.br',
      frontendBaseUrl: 'https://sonora.spotpromo.com.br',
      hostedFrontendEnabled: true,
      authEnabled: true,
    );

    expect(config.mode, AppMode.hostedFrontend);
    expect(config.frontendUrl, 'https://sonora.spotpromo.com.br');
    expect(config.authEnabled, isFalse);
  });

  test('keeps the native client outside Android', () {
    final config = AppLaunchConfig.resolve(
      isWeb: false,
      targetPlatform: TargetPlatform.windows,
      backendBaseUrl: 'http://localhost:8787',
      frontendBaseUrl: 'https://sonora.spotpromo.com.br',
      hostedFrontendEnabled: true,
      authEnabled: true,
    );

    expect(config.mode, AppMode.nativeClient);
    expect(config.frontendUrl, isNull);
    expect(config.authEnabled, isTrue);
  });

  test('can force the Android build to stay native', () {
    final config = AppLaunchConfig.resolve(
      isWeb: false,
      targetPlatform: TargetPlatform.android,
      backendBaseUrl: 'http://localhost:8787',
      frontendBaseUrl: 'https://sonora.spotpromo.com.br',
      hostedFrontendEnabled: false,
      authEnabled: true,
    );

    expect(config.mode, AppMode.nativeClient);
    expect(config.frontendUrl, isNull);
    expect(config.authEnabled, isTrue);
  });
}
