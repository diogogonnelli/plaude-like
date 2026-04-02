import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
      subtitle: '',
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
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _SectionCard(
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
          ),
        ],
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
