import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../design/brand_design_system.dart';
import '../state/plaude_controller.dart';
import 'app_shell.dart';

const _webCaptureNotice =
    'A captura por microfone esta disponivel nas versoes mobile e desktop. Na web, use o envio de audio.';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaudeController>();

    return AppShell(
      title: 'Biblioteca operacional',
      subtitle:
          'Busca, filtros por projeto e leitura densa do pipeline em uma superfície única.',
      navigationIndex: 0,
      showCaptureFab: true,
      homeBrandOnly: true,
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
                  .map(
                    (project) => DropdownMenuItem(
                      value: project.id,
                      child: Text(project.name),
                    ),
                  )
                  .toList(),
              onChanged: controller.changeActiveProject,
            ),
          ),
      ],
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            BrandPanel(
              highlight: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pesquisa e triagem',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: controller.setSearchQuery,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por título, resumo ou transcript',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  if (controller.notice case final String notice
                      when notice != _webCaptureNotice) ...[
                    const SizedBox(height: 14),
                    _Banner(
                      text: notice,
                      positive: controller.backendAvailable,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final summary = _LibrarySummary(
                  processingCount: controller.processingRecordings.length,
                  readyCount: controller.readyRecordings.length,
                  failedCount: controller.failedRecordings.length,
                );
                final queue = _LibrarySection(
                  title: 'Em andamento',
                  subtitle: 'Status da esteira que ainda exige processamento.',
                  recordings: controller.processingRecordings,
                );
                final ready = _LibrarySection(
                  title: 'Notas prontas',
                  subtitle: 'Itens prontos para leitura, exportação e chat.',
                  recordings: controller.readyRecordings,
                );
                final failed = _LibrarySection(
                  title: 'Falhas',
                  subtitle: 'Itens acessíveis para retry e diagnóstico.',
                  recordings: controller.failedRecordings,
                );

                if (!wide) {
                  return Column(
                    children: [
                      summary,
                      const SizedBox(height: 16),
                      queue,
                      const SizedBox(height: 16),
                      ready,
                      const SizedBox(height: 16),
                      failed,
                    ],
                  );
                }

                return Column(
                  children: [
                    summary,
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: queue),
                        const SizedBox(width: 16),
                        Expanded(child: ready),
                      ],
                    ),
                    const SizedBox(height: 16),
                    failed,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.positive});

  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return BrandPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      backgroundColor: positive
          ? BrandColors.positive.withValues(alpha: 0.08)
          : BrandColors.warning.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(
            positive
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            color: positive ? const Color(0xFF087A45) : const Color(0xFFAA4300),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _LibrarySummary extends StatelessWidget {
  const _LibrarySummary({
    required this.processingCount,
    required this.readyCount,
    required this.failedCount,
  });

  final int processingCount;
  final int readyCount;
  final int failedCount;

  @override
  Widget build(BuildContext context) {
    return BrandPanel(
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          _SummaryCard(
            title: 'Processando',
            value: '$processingCount',
            tone: BrandStatusTone.accent,
          ),
          _SummaryCard(
            title: 'Prontas',
            value: '$readyCount',
            tone: BrandStatusTone.success,
          ),
          _SummaryCard(
            title: 'Falhas',
            value: '$failedCount',
            tone: BrandStatusTone.warning,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.tone,
  });

  final String title;
  final String value;
  final BrandStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      BrandStatusTone.success => BrandColors.positive,
      BrandStatusTone.warning => BrandColors.warning,
      BrandStatusTone.accent => BrandColors.accent,
      BrandStatusTone.info => BrandColors.info,
      BrandStatusTone.neutral => BrandColors.shell,
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180),
      child: BrandPanel(
        backgroundColor: color.withValues(alpha: 0.08),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}

class _LibrarySection extends StatelessWidget {
  const _LibrarySection({
    required this.title,
    required this.subtitle,
    required this.recordings,
  });

  final String title;
  final String subtitle;
  final List<RecordingNote> recordings;

  @override
  Widget build(BuildContext context) {
    return BrandPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: BrandMotion.medium,
            child: recordings.isEmpty
                ? _LibraryEmptyState(
                    key: ValueKey('$title-empty'),
                    label: 'Nenhum registro em $title.',
                  )
                : Column(
                    key: ValueKey('$title-list'),
                    children: [
                      for (final recording in recordings)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RecordingCard(
                            note: recording,
                            onTap: () =>
                                context.go('/recordings/${recording.id}'),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LibraryEmptyState extends StatelessWidget {
  const _LibraryEmptyState({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return BrandPanel(
      backgroundColor: BrandColors.surfaceMuted,
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _RecordingCard extends StatelessWidget {
  const _RecordingCard({required this.note, required this.onTap});

  final RecordingNote note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy · HH:mm');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BrandRadius.lg),
      child: BrandPanel(
        backgroundColor: BrandColors.surfaceMuted,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note.summary?.overview ??
                            'Aguardando transcript ou resumo.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                BrandStatusPill(
                  label: note.status.label,
                  tone: _toneForStatus(note.status),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.schedule_rounded,
                  label: format.format(note.createdAt.toLocal()),
                ),
                _MetaChip(
                  icon: Icons.workspaces_outline,
                  label: note.projectId,
                ),
                _MetaChip(
                  icon: Icons.person_outline_rounded,
                  label: note.createdByUserId,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(BrandRadius.pill),
        border: Border.all(color: BrandColors.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: BrandColors.shell),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

BrandStatusTone _toneForStatus(ProcessingStatus status) {
  switch (status) {
    case ProcessingStatus.ready:
      return BrandStatusTone.success;
    case ProcessingStatus.failed:
      return BrandStatusTone.warning;
    case ProcessingStatus.indexing:
      return BrandStatusTone.info;
    case ProcessingStatus.processingTranscript:
    case ProcessingStatus.processingSummary:
    case ProcessingStatus.uploaded:
      return BrandStatusTone.accent;
  }
}

void _goToIndex(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.go('/library');
      return;
    case 1:
      context.go('/home');
      return;
    case 2:
      context.go('/settings');
      return;
  }
}
