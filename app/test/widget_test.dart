import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:plaude_like/app/app.dart';
import 'package:plaude_like/data/plaude_api.dart';
import 'package:plaude_like/state/plaude_controller.dart';
import 'package:plaude_like/ui/app_shell.dart';

Widget buildApp() {
  final controller = PlaudeController(
    api: PlaudeApi(baseUrl: 'http://localhost:8787'),
  )..bootstrap();

  return ChangeNotifierProvider(
    create: (_) => controller,
    child: const PlaudeApp(),
  );
}

void main() {
  testWidgets('renders the library shell with mobile navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Gravar'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('switches to desktop navigation when the viewport is wide', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Enviar audio'), findsOneWidget);
  });

  testWidgets('shows the route recovery state for unknown pages', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/missing',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
      errorBuilder: (context, state) => AppShell(
        title: 'Página não encontrada',
        child: Center(
          child: Text(state.error?.toString() ?? 'desconhecido'),
        ),
      ),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Página não encontrada'), findsOneWidget);
    expect(find.textContaining('/missing'), findsOneWidget);
  });
}
