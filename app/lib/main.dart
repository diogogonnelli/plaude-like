import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/app_config.dart';
import 'data/plaude_api.dart';
import 'state/plaude_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = PlaudeController(
    baseUrl: AppConfig.backendBaseUrl,
    authRequired: AppConfig.authEnabled,
  );

  await controller.bootstrap();

  runApp(
    ChangeNotifierProvider.value(value: controller, child: const GravacaoApp()),
  );
}
