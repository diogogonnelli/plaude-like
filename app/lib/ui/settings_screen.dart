import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/app_config.dart';
import '../design/brand_design_system.dart';
import '../state/plaude_controller.dart';
import 'app_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaudeController>();

    return AppShell(
      title: 'Sistema e ambiente',
      subtitle:
          'Sessão, backend, projeto ativo e direção do produto consolidados em um painel único.',
      navigationIndex: 2,
      homeBrandOnly: true,
      interceptBackToPrimary: true,
      onNavigationSelected: (index) => _goToIndex(context, index),
      actions: [
        BrandButton(
          label: 'Atualizar',
          icon: Icons.sync_rounded,
          variant: BrandButtonVariant.secondary,
          onPressed: controller.refresh,
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final sessionCard = _SectionCard(
            title: 'Sessão',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KeyValueRow(
                  label: 'Auth exigida',
                  value: controller.requiresAuth ? 'Sim' : 'Não',
                ),
                _KeyValueRow(
                  label: 'Usuário',
                  value: controller.sessionEmail ?? 'Modo local / demo',
                ),
                _KeyValueRow(
                  label: 'Projeto ativo',
                  value: controller.activeProject?.name ?? 'Nenhum',
                ),
                const SizedBox(height: 12),
                if (controller.requiresAuth)
                  BrandButton(
                    label: controller.authBusy
                        ? 'Saindo...'
                        : 'Encerrar sessão',
                    icon: Icons.logout_rounded,
                    onPressed: controller.authBusy
                        ? null
                        : () async {
                            await controller.signOut();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                  ),
              ],
            ),
          );

          final connectionCard = _SectionCard(
            title: 'Conexão',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBanner(
                  title: controller.backendAvailable
                      ? 'Backend conectado'
                      : 'Backend indisponível',
                  description:
                      controller.notice ??
                      (controller.backendAvailable
                          ? 'O app está usando fluxos HTTP reais com Bearer token.'
                          : 'O app caiu para um modo de desenvolvimento sem backend autenticado.'),
                  positive: controller.backendAvailable,
                ),
                const SizedBox(height: 16),
                _KeyValueRow(
                  label: 'URL do backend',
                  value: AppConfig.backendBaseUrl,
                ),
                _KeyValueRow(
                  label: 'Supabase URL',
                  value: AppConfig.supabaseUrl.isEmpty
                      ? 'Não configurado'
                      : AppConfig.supabaseUrl,
                ),
                _KeyValueRow(
                  label: 'Supabase ativo',
                  value: AppConfig.hasSupabase ? 'Sim' : 'Não',
                ),
              ],
            ),
          );

          final productCard = const _SectionCard(
            title: 'Direção do produto',
            child: _DirectionBlock(),
          );

          if (!wide) {
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                sessionCard,
                const SizedBox(height: 16),
                connectionCard,
                const SizedBox(height: 16),
                productCard,
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: sessionCard),
                  const SizedBox(width: 16),
                  Expanded(child: connectionCard),
                ],
              ),
              const SizedBox(height: 16),
              productCard,
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BrandPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.title,
    required this.description,
    required this.positive,
  });

  final String title;
  final String description;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return BrandPanel(
      backgroundColor: positive
          ? BrandColors.positive.withValues(alpha: 0.08)
          : BrandColors.warning.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _DirectionBlock extends StatelessWidget {
  const _DirectionBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandWordmark(compact: true),
        const SizedBox(height: 16),
        Text(
          'O GravAção prioriza cockpit operacional, biblioteca legível, detalhe executivo e chat contextual por gravação.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            BrandStatusPill(
              label: 'Shell adaptativo único',
              tone: BrandStatusTone.info,
            ),
            BrandStatusPill(
              label: 'Capture first',
              tone: BrandStatusTone.accent,
            ),
            BrandStatusPill(
              label: 'Projeto ativo global',
              tone: BrandStatusTone.neutral,
            ),
            BrandStatusPill(
              label: 'Chat bloqueado até ready',
              tone: BrandStatusTone.warning,
            ),
          ],
        ),
      ],
    );
  }
}

void _goToIndex(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.go('/home');
      return;
    case 1:
      context.go('/library');
      return;
    case 2:
      context.go('/settings');
      return;
  }
}
