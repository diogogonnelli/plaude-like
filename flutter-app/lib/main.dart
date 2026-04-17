import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/app_launch_config.dart';
import 'app/app_config.dart';
import 'app/hosted_frontend_app.dart';
import 'state/plaude_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final launchConfig = AppLaunchConfig.resolve(
    isWeb: kIsWeb,
    targetPlatform: defaultTargetPlatform,
    backendBaseUrl: AppConfig.backendBaseUrl,
    frontendBaseUrl: AppConfig.frontendBaseUrl,
    hostedFrontendEnabled: AppConfig.hostedFrontendEnabled,
    authEnabled: AppConfig.authEnabled,
  );

  if (launchConfig.usesHostedFrontend) {
    runApp(HostedFrontendApp(initialUrl: launchConfig.frontendUrl!));
    return;
  }

  final controller = PlaudeController(
    baseUrl: launchConfig.backendBaseUrl,
    authRequired: launchConfig.authEnabled,
  );

  await controller.bootstrap();

  runApp(
    ChangeNotifierProvider.value(value: controller, child: const GravacaoApp()),
  );
}
