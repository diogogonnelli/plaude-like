import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../design/brand_design_system.dart';
import '../state/plaude_controller.dart';
import 'app_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaudeController>();
    final activeProject = controller.activeProject;
    final inFlight = controller.processingRecordings;
    final recent = controller.readyRecordings.take(5).toList();

    return AppShell(
      title: 'Cockpit de captação',
      subtitle:
          controller.notice ??
          'Capture, acompanhe o pipeline e transforme cada gravação em execução com contexto visível.',
      navigationIndex: 0,
      showCaptureFab: true,
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
            if (controller.notice case final String notice) ...[
              _NoticeStrip(text: notice, positive: controller.backendAvailable),
              const SizedBox(height: 16),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final hero = _CommandDeck(
                  controller: controller,
                  activeProjectName:
                      activeProject?.name ?? 'Nenhum projeto ativo',
                  backendAvailable: controller.backendAvailable,
                  totalCount: controller.recordings.length,
                  processingCount: inFlight.length,
                  failedCount: controller.failedRecordings.length,
                );
                final side = _OverviewColumn(
                  activeProjectName:
                      activeProject?.name ?? 'Nenhum projeto ativo',
                  projectCount: controller.projects.length,
                  readyCount: controller.readyRecordings.length,
                  chatEnabledCount: controller.readyRecordings
                      .where((recording) => recording.chatSession != null)
                      .length,
                  backendAvailable: controller.backendAvailable,
                );

                if (!wide) {
                  return Column(
                    children: [hero, const SizedBox(height: 16), side],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 8, child: hero),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: side),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (controller.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 980;
                  final queue = _SectionPanel(
                    title: 'Pipeline em andamento',
                    subtitle:
                        'Itens que ainda estão transcrevendo, resumindo ou indexando.',
                    actionLabel: 'Abrir biblioteca',
                    onAction: () => context.go('/library'),
                    child: AnimatedSwitcher(
                      duration: BrandMotion.medium,
                      child: inFlight.isEmpty
                          ? const _EmptyPanelCopy(
                              key: ValueKey('queue-empty'),
                              title: 'Nenhum item em andamento',
                              description:
                                  'A próxima captação aparecerá aqui com status de transcript e resumo.',
                            )
                          : Column(
                              key: const ValueKey('queue-list'),
                              children: [
                                for (final recording in inFlight)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _QueueTile(
                                      recording: recording,
                                      onTap: () => context.go(
                                        '/recordings/${recording.id}',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  );

                  final notes = _SectionPanel(
                    title: 'Notas prontas',
                    subtitle:
                        'Resumo executivo, highlights e chat já liberados.',
                    child: AnimatedSwitcher(
                      duration: BrandMotion.medium,
                      child: recent.isEmpty
                          ? const _EmptyPanelCopy(
                              key: ValueKey('recent-empty'),
                              title: 'Nenhuma nota pronta',
                              description:
                                  'Conclua uma gravação para destravar resumo, evidências e chat contextual.',
                            )
                          : Column(
                              key: const ValueKey('recent-list'),
                              children: [
                                for (final recording in recent)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ReadyNoteTile(
                                      recording: recording,
                                      onTap: () => context.go(
                                        '/recordings/${recording.id}',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  );

                  if (!wide) {
                    return Column(
                      children: [queue, const SizedBox(height: 16), notes],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: queue),
                      const SizedBox(width: 16),
                      Expanded(child: notes),
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
                : Icons.warning_amber_rounded,
            color: positive ? const Color(0xFF087A45) : const Color(0xFFAA4300),
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
    required this.backendAvailable,
    required this.totalCount,
    required this.processingCount,
    required this.failedCount,
  });

  final PlaudeController controller;
  final String activeProjectName;
  final bool backendAvailable;
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              const BrandBadge(
                label: 'SPOT execution layer',
                backgroundColor: Color(0x1AFFFFFF),
                foregroundColor: Colors.white,
                borderColor: Color(0x24FFFFFF),
              ),
              BrandBadge(
                label: backendAvailable
                    ? 'Backend autenticado'
                    : 'Modo demonstração',
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                foregroundColor: Colors.white,
                borderColor: Colors.white.withValues(alpha: 0.18),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
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
                label: Text(
                  controller.isRecording
                      ? 'Parar captação'
                      : 'Iniciar captação',
                ),
              ),
              OutlinedButton.icon(
                onPressed: controller.pickAudioFile,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Enviar áudio'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricPanel(label: 'Notas', value: '$totalCount'),
              _MetricPanel(label: 'Em andamento', value: '$processingCount'),
              _MetricPanel(label: 'Falhas', value: '$failedCount'),
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
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white70),
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

class _OverviewColumn extends StatelessWidget {
  const _OverviewColumn({
    required this.activeProjectName,
    required this.projectCount,
    required this.readyCount,
    required this.chatEnabledCount,
    required this.backendAvailable,
  });

  final String activeProjectName;
  final int projectCount;
  final int readyCount;
  final int chatEnabledCount;
  final bool backendAvailable;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BrandPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leitura operacional',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _KpiLine(label: 'Projeto em foco', value: activeProjectName),
              _KpiLine(label: 'Projetos disponíveis', value: '$projectCount'),
              _KpiLine(label: 'Notas prontas', value: '$readyCount'),
              _KpiLine(label: 'Chats habilitados', value: '$chatEnabledCount'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BrandPanel(
          backgroundColor: BrandColors.surfaceMuted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modo de operação',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              BrandStatusPill(
                label: backendAvailable
                    ? 'SPOT pipeline online'
                    : 'Demo local ativo',
                tone: backendAvailable
                    ? BrandStatusTone.success
                    : BrandStatusTone.warning,
              ),
              const SizedBox(height: 12),
              Text(
                backendAvailable
                    ? 'O pipeline autenticado está respondendo. Gravações podem seguir direto para transcript, resumo e indexação.'
                    : 'Sem backend disponível, o GravAção mantém a leitura de UX com dados locais para não interromper o fluxo.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiLine extends StatelessWidget {
  const _KpiLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return BrandPanel(
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
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null)
                BrandButton(
                  label: actionLabel!,
                  variant: BrandButtonVariant.ghost,
                  onPressed: onAction,
                ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _EmptyPanelCopy extends StatelessWidget {
  const _EmptyPanelCopy({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return BrandPanel(
      backgroundColor: BrandColors.surfaceMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({required this.recording, required this.onTap});

  final RecordingNote recording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BrandRadius.lg),
      child: BrandPanel(
        backgroundColor: BrandColors.surfaceMuted,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: BrandColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(BrandRadius.md),
              ),
              child: const Icon(
                Icons.motion_photos_auto_rounded,
                color: BrandColors.accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recording.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Projeto ${recording.projectId} · ${recording.createdByUserId}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            BrandStatusPill(
              label: recording.status.label,
              tone: _toneForStatus(recording.status),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyNoteTile extends StatelessWidget {
  const _ReadyNoteTile({required this.recording, required this.onTap});

  final RecordingNote recording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM · HH:mm');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BrandRadius.lg),
      child: BrandPanel(
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
                        recording.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        recording.summary?.overview ?? 'Sem resumo disponível.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const BrandStatusPill(
                  label: 'Pronto',
                  tone: BrandStatusTone.success,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetaChip(
                  icon: Icons.schedule_rounded,
                  label: format.format(recording.createdAt.toLocal()),
                ),
                _MetaChip(
                  icon: Icons.workspaces_outline,
                  label: recording.projectId,
                ),
                _MetaChip(icon: Icons.forum_outlined, label: 'Chat contextual'),
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
