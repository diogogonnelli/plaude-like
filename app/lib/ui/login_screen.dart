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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    final narrative = _BrandNarrative(
                      authRequired: controller.requiresAuth,
                      backendAvailable: controller.backendAvailable,
                    );
                    final form = _LoginCard(
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
                                ? error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  )
                                : 'Falha ao autenticar.';
                          });
                        }
                      },
                    );

                    if (!wide) {
                      return ListView(
                        children: [narrative, const SizedBox(height: 16), form],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(flex: 7, child: narrative),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: form),
                      ],
                    );
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

class _BrandNarrative extends StatelessWidget {
  const _BrandNarrative({
    required this.authRequired,
    required this.backendAvailable,
  });

  final bool authRequired;
  final bool backendAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BrandRadius.xl),
        gradient: BrandColors.heroGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandWordmark(
            compact: true,
            textColor: Colors.white,
            subtitleColor: Colors.white70,
          ),
          const SizedBox(height: 18),
          BrandBadge(
            label: backendAvailable
                ? 'SPOT backend pronto'
                : 'Aguardando backend',
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            foregroundColor: Colors.white,
            borderColor: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 22),
          Text(
            'Captura, estrutura e execução na mesma operação.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 34,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'GravAção é o produto de captação operacional co-branded com SPOT para transformar áudio em contexto acionável.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _NarrativePill(
                label: authRequired
                    ? 'Supabase Auth exigido'
                    : 'Modo local liberado',
              ),
              _NarrativePill(label: 'Resumo estruturado'),
              _NarrativePill(label: 'Chat com evidências'),
            ],
          ),
        ],
      ),
    );
  }
}

class _NarrativePill extends StatelessWidget {
  const _NarrativePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BrandRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: Colors.white),
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
      highlight: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SpotEndorsement(),
          const SizedBox(height: 18),
          Text(
            'Entrar no GravAção',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Use uma conta provisionada no Supabase Auth para acessar o fluxo autenticado do aplicativo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
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
