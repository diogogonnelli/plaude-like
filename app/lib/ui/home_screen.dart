import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design/brand_design_system.dart';
import '../state/plaude_controller.dart';
import 'app_shell.dart';

const _webCaptureNotice =
    'A captura por microfone esta disponivel nas versoes mobile e desktop. Na web, use o envio de audio.';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaudeController>();
    final activeProject = controller.activeProject;

    return AppShell(
      title: '',
      subtitle: '',
      navigationIndex: 1,
      showCaptureFab: false,
      homeBrandOnly: true,
      onNavigationSelected: (index) => _goToIndex(context, index),
      actions: [
        if (controller.projects.isNotEmpty)
          SizedBox(
            width: 240,
            child: DropdownButtonFormField<String>(
              key: ValueKey(controller.activeProjectId),
              initialValue: controller.activeProjectId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Projeto ativo'),
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
        BrandButton(
          label: 'Atualizar',
          icon: Icons.sync_rounded,
          variant: BrandButtonVariant.secondary,
          onPressed: controller.refresh,
        ),
      ],
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            if (controller.notice case final String notice
                when notice != 'Conectado ao backend.') ...[
              _NoticeStrip(text: notice, positive: notice != _webCaptureNotice),
              const SizedBox(height: 16),
            ],
            _CommandDeck(
              controller: controller,
              activeProjectName: activeProject?.name ?? 'Nenhum projeto ativo',
              totalCount: controller.recordings.length,
              processingCount: controller.processingRecordings.length,
              failedCount: controller.failedRecordings.length,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeStrip extends StatelessWidget {
  const _NoticeStrip({required this.text, required this.positive});

  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return BrandPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      backgroundColor: positive
          ? BrandColors.positive.withValues(alpha: 0.08)
          : BrandColors.warning.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(
            positive
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: positive ? const Color(0xFF087A45) : BrandColors.shellDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: BrandColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandDeck extends StatelessWidget {
  const _CommandDeck({
    required this.controller,
    required this.activeProjectName,
    required this.totalCount,
    required this.processingCount,
    required this.failedCount,
  });

  final PlaudeController controller;
  final String activeProjectName;
  final int totalCount;
  final int processingCount;
  final int failedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BrandRadius.xl),
        gradient: BrandColors.heroGradient,
        boxShadow: [
          BoxShadow(
            color: BrandColors.accent.withValues(alpha: 0.24),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grave agora. Execute depois.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Projeto ativo: $activeProjectName',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'O GravAção consolida áudio, resumo estruturado, evidências e contexto de chat em uma esteira única com selo SPOT.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: controller.isRecording
                      ? controller.stopRecordingAndProcess
                      : controller.startRecording,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: BrandColors.shellDark,
                    minimumSize: const Size(0, 52),
                  ),
                  icon: Icon(
                    controller.isRecording
                        ? Icons.stop_circle_outlined
                        : Icons.mic_none_rounded,
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      controller.isRecording
                          ? 'Parar captação'
                          : 'Iniciar captação',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.pickAudioFile,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Enviar áudio'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _MetricPanel(label: 'Notas', value: '$totalCount'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricPanel(
                  label: 'Processando',
                  value: '$processingCount',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricPanel(label: 'Falhas', value: '$failedCount'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BrandRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 18,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
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
