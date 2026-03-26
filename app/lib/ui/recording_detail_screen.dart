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
      title: 'Detalhe da gravação',
      navigationIndex: 0,
      onNavigationSelected: (index) => context.go(index == 0 ? '/' : '/settings'),
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('/recordings/$recordingId/chat'),
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('Abrir chat'),
        ),
      ],
      child: recording == null
          ? _RecoveryPanel(
              controller: controller,
              onBack: () => context.go('/'),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final summary = _SummaryColumn(recording: recording);
                final actions = _ActionsColumn(
                  recording: recording,
                  controller: controller,
                  onChat: () => context.go('/recordings/$recordingId/chat'),
                );
                final transcript = _TranscriptColumn(recording: recording);

                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: summary),
                                  const SizedBox(width: 24),
                                  SizedBox(width: 320, child: actions),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  summary,
                                  const SizedBox(height: 24),
                                  actions,
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: transcript,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _RecoveryPanel extends StatelessWidget {
  const _RecoveryPanel({
    required this.controller,
    required this.onBack,
  });

  final PlaudeController controller;
  final VoidCallback onBack;

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
                const Text(
                  'Isso pode acontecer quando uma nota foi filtrada, removida na origem ou a rota aponta para dados antigos.',
                ),
                const SizedBox(height: 16),
                if (!controller.backendAvailable)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4D6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text('O backend está offline, então você está vendo apenas dados locais de demonstração.'),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Voltar para a biblioteca'),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.pickAudioFile,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Enviar áudio'),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.isRecording ? controller.stopRecordingAndProcess : controller.startRecording,
                      icon: Icon(controller.isRecording ? Icons.stop_circle_outlined : Icons.mic_none_rounded),
                      label: Text(controller.isRecording ? 'Parar gravação' : 'Gravar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({required this.recording});

  final RecordingNote recording;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy - HH:mm');

    return Column(
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
            Chip(label: Text(format.format(recording.createdAt.toLocal()))),
            Chip(label: Text(recording.sourceType)),
          ],
        ),
        if (recording.noteArtifact case final artifact?) ...[
          const SizedBox(height: 22),
          Text('Destaques', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...artifact.highlights.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _BulletLine(text: item),
            ),
          ),
          const SizedBox(height: 16),
          Text('Itens de ação', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...artifact.actionItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _BulletLine(text: item),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionsColumn extends StatelessWidget {
  const _ActionsColumn({
    required this.recording,
    required this.controller,
    required this.onChat,
  });

  final RecordingNote recording;
  final PlaudeController controller;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final canPlay = controller.isPlayable(recording.audioPath);
    final isPlaying = controller.isCurrentlyPlaying(recording.audioPath);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2D7C8)),
      ),
      child: Column(
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
            onPressed: onChat,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Abrir chat'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: canPlay ? () => controller.togglePlayback(recording.audioPath!) : null,
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow_rounded),
            label: Text(isPlaying ? 'Pausar áudio local' : 'Reproduzir áudio local'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                final export = await controller.exportRecording(recording.id, 'md');
                if (!context.mounted) {
                  return;
                }
                await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(export.fileName),
                    content: SizedBox(
                      width: 560,
                      child: SingleChildScrollView(child: SelectableText(export.body)),
                    ),
                  ),
                );
              } catch (error) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Falha ao exportar: $error')),
                );
              }
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('Exportar markdown'),
          ),
          const SizedBox(height: 10),
          Text(
            canPlay
                ? 'O áudio pode ser reproduzido localmente nas versões desktop e mobile.'
                : 'A reprodução está desativada para esta origem. Envie um arquivo local para testar o player.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (recording.lastError case final String error) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECE6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(error),
            ),
          ],
        ],
      ),
    );
  }
}

class _TranscriptColumn extends StatelessWidget {
  const _TranscriptColumn({required this.recording});

  final RecordingNote recording;

  @override
  Widget build(BuildContext context) {
    if (recording.transcriptSegments.isEmpty) {
      return _TranscriptEmptyState(
        recordingStatus: recording.status.label,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transcrição', style: Theme.of(context).textTheme.titleLarge),
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

class _TranscriptEmptyState extends StatelessWidget {
  const _TranscriptEmptyState({required this.recordingStatus});

  final String recordingStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2D7C8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transcrição indisponível', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Esta nota ainda está em "$recordingStatus" ou foi criada localmente sem conteúdo de transcrição.',
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 8),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
