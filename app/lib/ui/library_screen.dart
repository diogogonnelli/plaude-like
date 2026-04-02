import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../state/plaude_controller.dart';
import 'app_shell.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaudeController>();

    return AppShell(
      title: 'Biblioteca',
      subtitle: 'Busca, filtros por projeto ativo e agrupamento por estado em uma superfície mobile-first.',
      navigationIndex: 1,
      showCaptureFab: true,
      interceptBackToPrimary: true,
      onNavigationSelected: (index) => _goToIndex(context, index),
      actions: [
        if (controller.projects.isNotEmpty)
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              key: ValueKey(controller.activeProjectId),
              initialValue: controller.activeProjectId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Projeto'),
              items: controller.projects
                  .map((project) => DropdownMenuItem(
                        value: project.id,
                        child: Text(project.name),
                      ))
                  .toList(),
              onChanged: controller.changeActiveProject,
            ),
          ),
      ],
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: controller.setSearchQuery,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por título, resumo ou transcript',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (controller.notice case final String notice)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _Banner(
                  text: notice,
                  positive: controller.backendAvailable,
                ),
              ),
            if (controller.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (controller.recordings.isEmpty)
              const _EmptyState()
            else ...[
              _SectionTitle(title: 'Em andamento', count: controller.processingRecordings.length),
              const SizedBox(height: 12),
              if (controller.processingRecordings.isEmpty)
                const _InlineEmptyState(label: 'Nenhuma gravação em andamento.')
              else
                ...controller.processingRecordings.map(
                  (recording) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecordingCard(
                      note: recording,
                      compact: true,
                      onTap: () => context.go('/recordings/${recording.id}'),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              _SectionTitle(title: 'Prontas', count: controller.readyRecordings.length),
              const SizedBox(height: 12),
              if (controller.readyRecordings.isEmpty)
                const _InlineEmptyState(label: 'Nenhuma nota pronta para consulta.')
              else
                ...controller.readyRecordings.map(
                  (recording) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecordingCard(
                      note: recording,
                      onTap: () => context.go('/recordings/${recording.id}'),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              _SectionTitle(title: 'Falharam', count: controller.failedRecordings.length),
              const SizedBox(height: 12),
              if (controller.failedRecordings.isEmpty)
                const _InlineEmptyState(label: 'Nenhuma falha registrada no projeto ativo.')
              else
                ...controller.failedRecordings.map(
                  (recording) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecordingCard(
                      note: recording,
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

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.positive,
  });

  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: positive ? const Color(0xFFE8F3E4) : const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(text),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        Text('$count', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(label),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome_outlined, size: 40),
            const SizedBox(height: 12),
            Text('Nenhuma nota ainda', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Use o FAB para gravar ou enviar áudio e começar a preencher a biblioteca do projeto ativo.'),
          ],
        ),
      ),
    );
  }
}

class _RecordingCard extends StatelessWidget {
  const _RecordingCard({
    required this.note,
    required this.onTap,
    this.compact = false,
  });

  final RecordingNote note;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy • HH:mm');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(compact ? 18 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(note.title, style: Theme.of(context).textTheme.titleLarge)),
                  Chip(label: Text(note.status.label)),
                ],
              ),
              const SizedBox(height: 8),
              Text(note.summary?.overview ?? 'Aguardando transcript ou resumo.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniMeta(icon: Icons.schedule_rounded, label: format.format(note.createdAt.toLocal())),
                  _MiniMeta(icon: Icons.work_outline_rounded, label: note.projectId),
                  _MiniMeta(icon: Icons.person_outline_rounded, label: note.createdByUserId),
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
