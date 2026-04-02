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
    final notes = controller.recordings;
    final activeProject = controller.activeProject;

    return AppShell(
      title: 'Inicio',
      navigationIndex: 0,
      onNavigationSelected: (index) => context.go(index == 0 ? '/' : '/settings'),
      actions: [
        if (controller.projects.isNotEmpty)
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              initialValue: controller.activeProjectId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Projeto',
              ),
              items: controller.projects
                  .map((project) => DropdownMenuItem(
                        value: project.id,
                        child: Text(project.name),
                      ))
                  .toList(),
              onChanged: controller.changeActiveProject,
            ),
          ),
        FilledButton.icon(
          onPressed: controller.isRecording ? controller.stopRecordingAndProcess : controller.startRecording,
          icon: Icon(controller.isRecording ? Icons.stop_circle_outlined : Icons.mic_none_rounded),
          label: Text(controller.isRecording ? 'Parar gravacao' : 'Gravar'),
        ),
        OutlinedButton.icon(
          onPressed: controller.pickAudioFile,
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Enviar audio'),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _HeroPanel(
              projectName: activeProject?.name ?? 'Sem projeto ativo',
              backendAvailable: controller.backendAvailable,
              totalCount: notes.length,
              processingCount: notes.where((note) => !note.isReady && note.status != ProcessingStatus.failed).length,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: TextField(
                  onChanged: controller.setSearchQuery,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por tema, resumo ou transcricao',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (controller.notice case final String notice)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: controller.backendAvailable ? const Color(0xFFE8F3E4) : const Color(0xFFFFF4D6),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(notice),
                ),
              ),
            if (controller.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (notes.isEmpty)
              _EmptyState(
                projectName: activeProject?.name,
                onRecord: controller.startRecording,
                onUpload: controller.pickAudioFile,
              )
            else ...[
              Text('Em andamento', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...notes
                  .where((note) => note.status != ProcessingStatus.ready && note.status != ProcessingStatus.failed)
                  .map((note) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RecordingCard(
                          note: note,
                          onTap: () => context.go('/recordings/${note.id}'),
                        ),
                      )),
              const SizedBox(height: 12),
              Text('Recentes', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...notes
                  .where((note) => note.status == ProcessingStatus.ready || note.status == ProcessingStatus.failed)
                  .map((note) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RecordingCard(
                          note: note,
                          onTap: () => context.go('/recordings/${note.id}'),
                        ),
                      )),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.projectName,
    required this.backendAvailable,
    required this.totalCount,
    required this.processingCount,
  });

  final String projectName;
  final bool backendAvailable;
  final int totalCount;
  final int processingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF231B18),
            Color(0xFF4A372E),
            Color(0xFFB25F2B),
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
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Projeto ativo: $projectName',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            backendAvailable
                ? 'Grave, envie e acompanhe as transcricoes do projeto em um unico fluxo.'
                : 'O backend esta offline. Voce pode continuar testando com dados locais.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricPill(label: 'Notas', value: '$totalCount'),
              _MetricPill(label: 'Em andamento', value: '$processingCount'),
              _MetricPill(label: 'Modo', value: backendAvailable ? 'HTTP' : 'Demo'),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.projectName,
    required this.onRecord,
    required this.onUpload,
  });

  final String? projectName;
  final Future<void> Function() onRecord;
  final Future<void> Function() onUpload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              projectName == null ? 'Nenhum projeto selecionado' : 'Nenhuma nota ainda',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              projectName == null
                  ? 'Escolha um projeto para comecar.'
                  : 'Comece gravando uma nota de voz ou enviando um audio existente para $projectName.',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onRecord,
                  icon: const Icon(Icons.mic_none_rounded),
                  label: const Text('Gravar'),
                ),
                OutlinedButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Enviar audio'),
                ),
              ],
            ),
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
  });

  final RecordingNote note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy - HH:mm');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(note.title, style: Theme.of(context).textTheme.titleLarge),
                  ),
                  Chip(label: Text(note.status.label)),
                ],
              ),
              const SizedBox(height: 10),
              Text(note.summary?.overview ?? 'Aguardando transcricao ou resumo.'),
              const SizedBox(height: 14),
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
