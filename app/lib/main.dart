import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/app_config.dart';
import 'data/plaude_api.dart';
import 'state/plaude_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => PlaudeController(
        api: PlaudeApi(baseUrl: AppConfig.backendBaseUrl),
      )..bootstrap(),
      child: const PlaudeApp(),
    ),
  );
}
