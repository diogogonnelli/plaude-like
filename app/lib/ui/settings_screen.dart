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
      title: 'Settings',
      navigationIndex: 1,
      onNavigationSelected: (index) => context.go(index == 0 ? '/' : '/settings'),
      actions: [
        OutlinedButton.icon(
          onPressed: controller.refresh,
          icon: const Icon(Icons.sync_rounded),
          label: const Text('Refresh status'),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _ConnectionCard(
            backendAvailable: controller.backendAvailable,
            notice: controller.notice,
            backendUrl: AppConfig.backendBaseUrl,
            supabaseConfigured: AppConfig.hasSupabase,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Test readiness', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  const Text('These controls show whether the product is safe to exercise in a test run.'),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: const [
                      Chip(label: Text('Flutter web + mobile')),
                      Chip(label: Text('Backend status surfaced')),
                      Chip(label: Text('Demo fallback available')),
                      Chip(label: Text('Upload / record / chat / export')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Product stance', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  const Text('Single-user voice capture, structured summaries, grounded chat and export-ready notes.'),
                  const SizedBox(height: 16),
                  _KeyValueRow(label: 'Backend URL', value: AppConfig.backendBaseUrl),
                  _KeyValueRow(label: 'Backend status', value: controller.backendAvailable ? 'Connected' : 'Offline / demo'),
                  _KeyValueRow(label: 'Supabase configured', value: AppConfig.hasSupabase ? 'Yes' : 'No'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.backendAvailable,
    required this.notice,
    required this.backendUrl,
    required this.supabaseConfigured,
  });

  final bool backendAvailable;
  final String? notice;
  final String backendUrl;
  final bool supabaseConfigured;

  @override
  Widget build(BuildContext context) {
    final background = backendAvailable ? const Color(0xFFE8F3E4) : const Color(0xFFFFF4D6);
    final icon = backendAvailable ? Icons.cloud_done_outlined : Icons.cloud_off_outlined;
    final title = backendAvailable ? 'Backend connected' : 'Backend offline';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connection', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          notice ??
                              (backendAvailable
                                  ? 'The app is using live HTTP flows.'
                                  : 'The app is using local demo data until the backend comes back online.'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _KeyValueRow(label: 'Backend URL', value: backendUrl),
            _KeyValueRow(label: 'Supabase configured', value: supabaseConfigured ? 'Yes' : 'No'),
          ],
        ),
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
            width: 170,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
