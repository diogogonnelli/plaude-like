import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:plaude_like/app/theme.dart';
import 'package:plaude_like/state/plaude_controller.dart';
import 'package:plaude_like/ui/login_screen.dart';

void main() {
  testWidgets('renders the simplified Sonora login card', (
    WidgetTester tester,
  ) async {
    final controller = PlaudeController(baseUrl: 'http://localhost:8000');

    await tester.pumpWidget(
      ChangeNotifierProvider<PlaudeController>.value(
        value: controller,
        child: MaterialApp(
          theme: buildGravacaoTheme(),
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const Key('login-card')), findsOneWidget);
    expect(find.text('Sonora'), findsOneWidget);
    expect(
      find.text('Gravacao inteligente em uma unica pagina.'),
      findsOneWidget,
    );
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(
      find.text('Captação, estrutura e execução na mesma operação.'),
      findsNothing,
    );
  });
}
