import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../state/plaude_controller.dart';
import 'app_shell.dart';

class RecordingDetailScreen extends StatelessWidget {
  const RecordingDetailScreen({
    super.key,
    required this.recordingId,
  });

  final String recordingId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaudeController>();
    final recording = controller.findById(recordingId);

    return AppShell(
      title: 'Detalhe',
      subtitle: 'Resumo executivo, destaques, itens de ação e transcript por speaker.',
      navigationIndex: 1,
      onNavigationSelected: (index) => _goToIndex(context, index),
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('/library'),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Biblioteca'),
        ),
        OutlinedButton.icon(
          onPressed: recording != null && recording.isReady ? () => context.go('/recordings/$recordingId/chat') : null,
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('Abrir chat'),
        ),
      ],
      child: recording == null
          ? const _MissingState()
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recording.noteArtifact?.title ?? recording.title, style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 10),
                        Text(recording.summary?.overview ?? 'Esta nota ainda está passando pelo pipeline de processamento.'),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text(recording.status.label)),
                            Chip(label: Text(DateFormat('dd/MM/yyyy • HH:mm').format(recording.createdAt.toLocal()))),
                            Chip(label: Text('Projeto ${recording.projectId}')),
                            Chip(label: Text('Autor ${recording.createdByUserId}')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _InfoBlock(
                          title: 'Destaques',
                          items: recording.noteArtifact?.highlights ?? const [],
                          emptyLabel: 'Nenhum destaque estruturado ainda.',
                        ),
                        const SizedBox(height: 16),
                        _InfoBlock(
                          title: 'Itens de ação',
                          items: recording.noteArtifact?.actionItems ?? const [],
                          emptyLabel: 'Nenhum item de ação estruturado ainda.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _TranscriptSection(recording: recording),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _ActionsSection(recording: recording),
                  ),
                ),
              ],
            ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
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
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text(emptyLabel)
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TranscriptSection extends StatelessWidget {
  const _TranscriptSection({required this.recording});

  final RecordingNote recording;

  @override
  Widget build(BuildContext context) {
    if (recording.transcriptSegments.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transcript', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('A transcrição ainda não está disponível para esta nota.'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transcript', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        ...recording.transcriptSegments.map(
          (segment) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F4EE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${segment.speakerLabel} • ${_timestamp(segment.startMs)}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(segment.text),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _timestamp(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({required this.recording});

  final RecordingNote recording;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaudeController>();
    final canPlay = controller.isPlayable(recording.audioPath);
    final isPlaying = controller.isCurrentlyPlaying(recording.audioPath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ações', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: controller.isProcessing(recording.id) ? null : () => controller.processRecording(recording.id),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(controller.isProcessing(recording.id) ? 'Processando' : 'Processar novamente'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: recording.isReady ? () => context.go('/recordings/${recording.id}/chat') : null,
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('Abrir chat'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: canPlay ? () => controller.togglePlayback(recording.audioPath!) : null,
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow_rounded),
          label: Text(isPlaying ? 'Pausar áudio local' : 'Reproduzir áudio local'),
        ),
        if (recording.lastError case final String error) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFECE6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(error),
          ),
        ],
      ],
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
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gravação não encontrada', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('A rota aponta para um item que não está no projeto ativo ou não existe mais.'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.go('/library'),
                  icon: const Icon(Icons.library_books_rounded),
                  label: const Text('Voltar para a biblioteca'),
                ),
              ],
            ),
          ),
        ),
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
