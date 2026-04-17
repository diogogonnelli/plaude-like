import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/brand_design_system.dart';
import '../state/plaude_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaudeController>();

    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: _LoginCard(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  authBusy: controller.authBusy,
                  error: _error,
                  onSubmit: () async {
                    setState(() => _error = null);
                    try {
                      await controller.signIn(
                        _emailController.text.trim(),
                        _passwordController.text,
                      );
                    } catch (error) {
                      setState(() {
                        _error = error is Exception
                            ? error.toString().replaceFirst('Exception: ', '')
                            : 'Falha ao autenticar.';
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.authBusy,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool authBusy;
  final String? error;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return BrandPanel(
      key: const Key('login-card'),
      highlight: true,
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sonora',
            textAlign: TextAlign.center,
            style: BrandTypography.wordmark(
              size: 34,
              color: BrandColors.shellDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gravacao inteligente em uma unica pagina.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Senha',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            BrandPanel(
              backgroundColor: BrandColors.warning.withValues(alpha: 0.12),
              child: Text(
                error!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: BrandColors.text),
              ),
            ),
          ],
          const SizedBox(height: 18),
          BrandButton(
            label: authBusy ? 'Entrando...' : 'Entrar',
            icon: Icons.login_rounded,
            onPressed: authBusy ? null : () => onSubmit(),
            expanded: true,
          ),
        ],
      ),
    );
  }
}
