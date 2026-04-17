import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:plaude_like/app/app.dart';
import 'package:plaude_like/data/plaude_api.dart';
import 'package:plaude_like/state/plaude_controller.dart';

Widget buildApp({bool authRequiredOverride = false}) {
  final controller = PlaudeController(
    api: PlaudeApi(baseUrl: 'http://localhost:8787'),
    authRequiredOverride: authRequiredOverride,
  )..bootstrap();

  return ChangeNotifierProvider(
    create: (_) => controller,
    child: const GravacaoApp(),
  );
}

void main() {
  testWidgets('renders the home shell with mobile navigation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Cockpit de captação'), findsNothing);
    expect(find.textContaining('Grav'), findsWidgets);
    expect(find.text('Nova captação'), findsNothing);
    expect(find.text('Iniciar captação'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('switches to desktop navigation when the viewport is wide', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('SPOT'), findsWidgets);
    expect(find.text('Biblioteca'), findsWidgets);
  });

  testWidgets(
    'redirects to login when auth is required and there is no session',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(authRequiredOverride: true));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Entrar no GravAção'), findsOneWidget);
      expect(find.textContaining('Supabase Auth'), findsWidgets);
    },
  );

  testWidgets('shows route recovery state for unknown pages', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/missing',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text(state.error?.toString() ?? 'desconhecido')),
      ),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.textContaining('/missing'), findsOneWidget);
  });
}
