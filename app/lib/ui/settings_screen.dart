import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/app_config.dart';
import '../state/plaude_controller.dart';
import 'app_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaudeController>();

    return AppShell(
      title: 'Ajustes',
      subtitle: 'Ambiente, sessão, backend, projeto ativo e integrações consolidados em um único lugar.',
      navigationIndex: 2,
      interceptBackToPrimary: true,
      onNavigationSelected: (index) => _goToIndex(context, index),
      actions: [
        OutlinedButton.icon(
          onPressed: controller.refresh,
          icon: const Icon(Icons.sync_rounded),
          label: const Text('Atualizar'),
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
                _KeyValueRow(label: 'Auth exigida', value: controller.requiresAuth ? 'Sim' : 'Não'),
                _KeyValueRow(label: 'Usuário', value: controller.sessionEmail ?? 'Modo local / demo'),
                _KeyValueRow(label: 'Projeto ativo', value: controller.activeProject?.name ?? 'Nenhum'),
                const SizedBox(height: 12),
                if (controller.requiresAuth)
                  FilledButton.icon(
                    onPressed: controller.authBusy
                        ? null
                        : () async {
                            await controller.signOut();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(controller.authBusy ? 'Saindo...' : 'Sair'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Conexão',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBanner(
                  title: controller.backendAvailable ? 'Backend conectado' : 'Backend indisponível',
                  description: controller.notice ??
                      (controller.backendAvailable
                          ? 'O app está usando fluxos HTTP reais com Bearer token.'
                          : 'O app caiu para um modo de desenvolvimento sem backend autenticado.'),
                  positive: controller.backendAvailable,
                ),
                const SizedBox(height: 16),
                _KeyValueRow(label: 'URL do backend', value: AppConfig.backendBaseUrl),
                _KeyValueRow(label: 'Supabase URL', value: AppConfig.supabaseUrl.isEmpty ? 'Não configurado' : AppConfig.supabaseUrl),
                _KeyValueRow(label: 'Supabase ativo', value: AppConfig.hasSupabase ? 'Sim' : 'Não'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Direção do produto',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Home operacional, biblioteca compacta, detalhe executivo e chat contextual por gravação.'),
                SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Chip(label: Text('Shell adaptativo único')),
                    Chip(label: Text('Capture-first')),
                    Chip(label: Text('Projeto ativo global')),
                    Chip(label: Text('Chat bloqueado até ready')),
                  ],
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
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: positive ? const Color(0xFFE8F3E4) : const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(description),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
  });

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
