import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/app_shell.dart';
import '../ui/chat_screen.dart';
import '../ui/library_screen.dart';
import '../ui/recording_detail_screen.dart';
import '../ui/settings_screen.dart';
import 'theme.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LibraryScreen(),
      routes: [
        GoRoute(
          path: 'recordings/:recordingId',
          builder: (context, state) => RecordingDetailScreen(
            recordingId: state.pathParameters['recordingId']!,
          ),
        ),
        GoRoute(
          path: 'recordings/:recordingId/chat',
          builder: (context, state) => ChatScreen(
            recordingId: state.pathParameters['recordingId']!,
          ),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => AppShell(
    title: 'Page not found',
    navigationIndex: 0,
    onNavigationSelected: (index) => context.go(index == 0 ? '/' : '/settings'),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Route unavailable', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  state.error == null
                      ? 'The page does not exist.'
                      : 'The router could not resolve this page: ${state.error}',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.dashboard_rounded),
                      label: const Text('Go to library'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/settings'),
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Open settings'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

class PlaudeApp extends StatelessWidget {
  const PlaudeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Plaude Like',
      debugShowCheckedModeBanner: false,
      theme: buildPlaudeTheme(),
      routerConfig: _router,
    );
  }
}
