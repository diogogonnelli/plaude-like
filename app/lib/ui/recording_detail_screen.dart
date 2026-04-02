import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../design/brand_design_system.dart';
import '../state/plaude_controller.dart';
import 'app_shell.dart';

class RecordingDetailScreen extends StatelessWidget {
  const RecordingDetailScreen({super.key, required this.recordingId});

  final String recordingId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaudeController>();
    final recording = controller.findById(recordingId);

    return AppShell(
      title: 'Leitura executiva da gravação',
      subtitle:
          'Resumo, destaques, transcript com speaker e ações imediatas em um mesmo fluxo.',
      navigationIndex: 1,
      onNavigationSelected: (index) => _goToIndex(context, index),
      actions: [
        BrandButton(
          label: 'Biblioteca',
          icon: Icons.arrow_back_rounded,
          variant: BrandButtonVariant.secondary,
          onPressed: () => context.go('/library'),
        ),
        BrandButton(
          label: 'Abrir chat',
          icon: Icons.chat_bubble_outline_rounded,
          onPressed: recording != null && recording.isReady
              ? () => context.go('/recordings/$recordingId/chat')
              : null,
        ),
      ],
      child: recording == null
          ? const _MissingState()
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _SummaryHero(recording: recording),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final insights = _InsightsPanel(recording: recording);
                    final actions = _ActionsPanel(recording: recording);

                    if (!wide) {
                      return Column(
                        children: [
                          insights,
                          const SizedBox(height: 16),
                          actions,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 8, child: insights),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: actions),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _TranscriptPanel(recording: recording),
              ],
            ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.recording});

  final RecordingNote recording;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy · HH:mm');
    return BrandPanel(
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              BrandStatusPill(
                label: recording.status.label,
                tone: _toneForStatus(recording.status),
              ),
              _MetaPill(
                icon: Icons.schedule_rounded,
                label: format.format(recording.createdAt.toLocal()),
              ),
              _MetaPill(
                icon: Icons.workspaces_outline,
                label: 'Projeto ${recording.projectId}',
              ),
              _MetaPill(
                icon: Icons.person_outline_rounded,
                label: 'Autor ${recording.createdByUserId}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            recording.noteArtifact?.title ?? recording.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            recording.summary?.overview ??
                'Esta nota ainda está passando pelo pipeline de processamento.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (recording.summary?.chapters case final chapters?
              when chapters.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: chapters
                  .map(
                    (chapter) => SizedBox(
                      width: 280,
                      child: BrandPanel(
                        backgroundColor: BrandColors.surfaceMuted,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapter.heading,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              chapter.body,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightsPanel extends StatelessWidget {
  const _InsightsPanel({required this.recording});

  final RecordingNote recording;

  @override
  Widget build(BuildContext context) {
    return BrandPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insights estruturados',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Destaques, tags e itens acionáveis derivados da gravação.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          _InsightBlock(
            title: 'Highlights',
            items: recording.noteArtifact?.highlights ?? const [],
            emptyLabel: 'Nenhum highlight estruturado ainda.',
          ),
          const SizedBox(height: 16),
          _InsightBlock(
            title: 'Action items',
            items: recording.noteArtifact?.actionItems ?? const [],
            emptyLabel: 'Nenhum item de ação estruturado ainda.',
          ),
          if (recording.noteArtifact?.tags case final tags?
              when tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Tags operacionais',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (tag) => BrandStatusPill(
                      label: tag,
                      tone: BrandStatusTone.neutral,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightBlock extends StatelessWidget {
  const _InsightBlock({
    required this.title,
    required this.items,
    required this.emptyLabel,
  });

  final String title;
  final List<String> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (items.isEmpty)
          BrandPanel(
            backgroundColor: BrandColors.surfaceMuted,
            child: Text(
              emptyLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BrandPanel(
                backgroundColor: BrandColors.surfaceMuted,
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: BrandColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _TranscriptPanel extends StatelessWidget {
  const _TranscriptPanel({required this.recording});

  final RecordingNote recording;

  @override
  Widget build(BuildContext context) {
    return BrandPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transcript contextual',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Leitura cronológica com speaker, timestamp e contraste alto para revisão rápida.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          if (recording.transcriptSegments.isEmpty)
            BrandPanel(
              backgroundColor: BrandColors.surfaceMuted,
              child: Text(
                'A transcrição ainda não está disponível para esta nota.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ...recording.transcriptSegments.map(
              (segment) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BrandPanel(
                  backgroundColor: BrandColors.surfaceMuted,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            segment.speakerLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 10),
                          BrandStatusPill(
                            label: _timestamp(segment.startMs),
                            tone: BrandStatusTone.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        segment.text,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _timestamp(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _ActionsPanel extends StatelessWidget {
  const _ActionsPanel({required this.recording});

  final RecordingNote recording;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaudeController>();
    final canPlay = controller.isPlayable(recording.audioPath);
    final isPlaying = controller.isCurrentlyPlaying(recording.audioPath);

    return BrandPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações do operador',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Retry, chat e reprodução local com feedback claro de estado.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          BrandButton(
            label: controller.isProcessing(recording.id)
                ? 'Processando'
                : 'Processar novamente',
            icon: Icons.auto_awesome_rounded,
            onPressed: controller.isProcessing(recording.id)
                ? null
                : () => controller.processRecording(recording.id),
            expanded: true,
          ),
          const SizedBox(height: 12),
          BrandButton(
            label: 'Abrir chat contextual',
            icon: Icons.chat_bubble_outline_rounded,
            variant: BrandButtonVariant.secondary,
            onPressed: recording.isReady
                ? () => context.go('/recordings/${recording.id}/chat')
                : null,
            expanded: true,
          ),
          const SizedBox(height: 12),
          BrandButton(
            label: isPlaying ? 'Pausar áudio local' : 'Reproduzir áudio local',
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            variant: BrandButtonVariant.ghost,
            onPressed: canPlay
                ? () => controller.togglePlayback(recording.audioPath!)
                : null,
            expanded: true,
          ),
          if (recording.lastError case final String error) ...[
            const SizedBox(height: 18),
            BrandPanel(
              backgroundColor: BrandColors.warning.withValues(alpha: 0.12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Último erro do pipeline',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: BrandColors.text),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: BrandColors.surfaceMuted,
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

class _MissingState extends StatelessWidget {
  const _MissingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: BrandPanel(
          highlight: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gravação não encontrada',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'A rota aponta para um item fora do projeto ativo ou que já não existe mais.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              BrandButton(
                label: 'Voltar para a biblioteca',
                icon: Icons.library_books_rounded,
                onPressed: () => context.go('/library'),
              ),
            ],
          ),
        ),
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
