import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/plaude_controller.dart';
import '../ui/chat_screen.dart';
import '../ui/home_screen.dart';
import '../ui/library_screen.dart';
import '../ui/login_screen.dart';
import '../ui/recording_detail_screen.dart';
import '../ui/settings_screen.dart';
import 'theme.dart';

class PlaudeApp extends StatefulWidget {
  const PlaudeApp({super.key});

  @override
  State<PlaudeApp> createState() => _PlaudeAppState();
}

class _PlaudeAppState extends State<PlaudeApp> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= _buildRouter(context.read<PlaudeController>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Plaude Like',
      debugShowCheckedModeBanner: false,
      theme: buildPlaudeTheme(),
      routerConfig: _router!,
      locale: const Locale('pt', 'BR'),
    );
  }
}

GoRouter _buildRouter(PlaudeController controller) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: controller,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final onLogin = path == '/login';

      if (!controller.authReady) {
        return null;
      }

      if (controller.requiresAuth && !controller.isAuthenticated) {
        return onLogin ? null : '/login';
      }

      if (onLogin) {
        return '/home';
      }

      if (path == '/') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/recordings/:recordingId',
        builder: (context, state) => RecordingDetailScreen(
          recordingId: state.pathParameters['recordingId']!,
        ),
      ),
      GoRoute(
        path: '/recordings/:recordingId/chat',
        builder: (context, state) => ChatScreen(
          recordingId: state.pathParameters['recordingId']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Página indisponível', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    state.error == null
                        ? 'A rota solicitada não existe.'
                        : 'O roteador não conseguiu resolver esta página: ${state.error}',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Ir para a home'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/library'),
                        icon: const Icon(Icons.library_books_rounded),
                        label: const Text('Abrir biblioteca'),
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
}
