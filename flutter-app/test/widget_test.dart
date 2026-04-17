import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plaude_like/app/hosted_frontend_app.dart';

void main() {
  testWidgets('renders the hosted frontend shell for Android', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      HostedFrontendApp(
        initialUrl: 'https://sonora.spotpromo.com.br',
        webViewBuilder: () => const SizedBox(
          key: Key('hosted-frontend-view'),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const Key('hosted-frontend-view')), findsOneWidget);
    expect(find.text('GravAção'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });
}
