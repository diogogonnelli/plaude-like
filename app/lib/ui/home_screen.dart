import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../state/plaude_controller.dart';
import 'app_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaudeController>();
    final activeProject = controller.activeProject;
    final inFlight = controller.processingRecordings;
    final recent = controller.readyRecordings.take(4).toList();

    return AppShell(
      title: 'Home',
      subtitle: controller.notice ?? 'Capture primeiro, revise depois e mantenha o projeto ativo sempre visível.',
      navigationIndex: 0,
      showCaptureFab: true,
      onNavigationSelected: (index) => _goToIndex(context, index),
      actions: [
        if (controller.projects.isNotEmpty)
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              key: ValueKey(controller.activeProjectId),
              initialValue: controller.activeProjectId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Projeto ativo'),
              items: controller.projects
                  .map((project) => DropdownMenuItem(
                        value: project.id,
                        child: Text(project.name),
                      ))
                  .toList(),
              onChanged: controller.changeActiveProject,
            ),
          ),
        OutlinedButton.icon(
          onPressed: controller.refresh,
          icon: const Icon(Icons.sync_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _HeroPanel(
              activeProjectName: activeProject?.name ?? 'Sem projeto ativo',
              backendAvailable: controller.backendAvailable,
              totalCount: controller.recordings.length,
              processingCount: inFlight.length,
              failedCount: controller.failedRecordings.length,
            ),
            const SizedBox(height: 16),
            if (controller.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _SectionTitle(
                title: 'Fila em andamento',
                actionLabel: 'Abrir biblioteca',
                onTap: () => context.go('/library'),
              ),
              const SizedBox(height: 12),
              if (inFlight.isEmpty)
                const _InlineEmptyState(
                  title: 'Nenhum item em andamento',
                  description: 'A próxima captura ficará visível aqui até concluir transcript e resumo.',
                )
              else
                ...inFlight.map(
                  (recording) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HomeRecordingTile(
                      recording: recording,
                      onTap: () => context.go('/recordings/${recording.id}'),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const _SectionTitle(title: 'Notas recentes'),
              const SizedBox(height: 12),
              if (recent.isEmpty)
                const _InlineEmptyState(
                  title: 'Nenhuma nota pronta ainda',
                  description: 'Conclua uma captura para abrir resumo executivo, destaques e chat contextual.',
                )
              else
                ...recent.map(
                  (recording) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecentCard(
                      recording: recording,
                      onTap: () => context.go('/recordings/${recording.id}'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.activeProjectName,
    required this.backendAvailable,
    required this.totalCount,
    required this.processingCount,
    required this.failedCount,
  });

  final String activeProjectName;
  final bool backendAvailable;
  final int totalCount;
  final int processingCount;
  final int failedCount;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 28 : 32),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF201813),
            Color(0xFF6E4B2A),
            Color(0xFFE08C2A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Captura primeiro',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontSize: compact ? 24 : 28,
                  height: 1,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Projeto ativo: $activeProjectName',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontSize: compact ? 14 : 16,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            backendAvailable
                ? 'Fluxo autenticado ativo. Grave, envie e acompanhe o pipeline do projeto em um shell mobile-first.'
                : 'Modo local disponível para desenvolvimento quando o backend autenticado não estiver acessível.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: compact ? 13 : 14,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(label: 'Notas', value: '$totalCount'),
              _MetricPill(label: 'Em andamento', value: '$processingCount'),
              _MetricPill(label: 'Falhas', value: '$failedCount'),
              _MetricPill(label: 'Modo', value: backendAvailable ? 'Autenticado' : 'Demo'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 86),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (actionLabel != null && onTap != null)
          TextButton(onPressed: onTap, child: Text(actionLabel!)),
      ],
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }
}

class _HomeRecordingTile extends StatelessWidget {
  const _HomeRecordingTile({
    required this.recording,
    required this.onTap,
  });

  final RecordingNote recording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4E4CD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recording.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('${recording.status.label} • ${recording.projectId}'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.recording,
    required this.onTap,
  });

  final RecordingNote recording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM • HH:mm');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(recording.title, style: Theme.of(context).textTheme.titleLarge)),
                  Chip(label: Text(recording.status.label)),
                ],
              ),
              const SizedBox(height: 10),
              Text(recording.summary?.overview ?? 'Sem resumo disponível.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniMeta(icon: Icons.schedule_rounded, label: format.format(recording.createdAt.toLocal())),
                  _MiniMeta(icon: Icons.work_outline_rounded, label: recording.projectId),
                  _MiniMeta(icon: Icons.person_outline_rounded, label: recording.createdByUserId),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(label),
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
