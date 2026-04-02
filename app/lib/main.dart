import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/app_config.dart';
import 'app/push_notification_service.dart';
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
  final pushNotifications = PushNotificationService(api: api);

  runApp(
    ChangeNotifierProvider(
      create: (_) => PlaudeController(
        api: api,
        pushNotifications: pushNotifications,
        supabaseClient: AppConfig.hasSupabase ? Supabase.instance.client : null,
      )..bootstrap(),
      child: const GravacaoApp(),
    ),
  );
}
