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

  final api = PlaudeApi(
    baseUrl: AppConfig.backendBaseUrl,
    accessTokenProvider: () async => AppConfig.hasSupabase
        ? Supabase.instance.client.auth.currentSession?.accessToken
        : null,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => PlaudeController(
        api: api,
        supabaseClient: AppConfig.hasSupabase ? Supabase.instance.client : null,
      )..bootstrap(),
      child: const GravacaoApp(),
    ),
  );
}
