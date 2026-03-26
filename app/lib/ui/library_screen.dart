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
    final readyCount = notes.where((note) => note.isReady).length;
    final hasQuery = controller.searchQuery.trim().isNotEmpty;

    return AppShell(
      title: 'Voice library',
      navigationIndex: 0,
      onNavigationSelected: (index) => context.go(index == 0 ? '/' : '/settings'),
      actions: [
        FilledButton.icon(
          onPressed: controller.isRecording ? controller.stopRecordingAndProcess : controller.startRecording,
          icon: Icon(controller.isRecording ? Icons.stop_circle_outlined : Icons.mic_none_rounded),
          label: Text(controller.isRecording ? 'Stop recording' : 'Record'),
        ),
        OutlinedButton.icon(
          onPressed: controller.pickAudioFile,
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Upload audio'),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _HeroPanel(
                  controller: controller,
                  totalCount: notes.length,
                  readyCount: readyCount,
                ),
                const SizedBox(height: 16),
                _SearchBar(
                  onChanged: controller.setSearchQuery,
                  onClear: controller.searchQuery.isEmpty ? null : () => controller.setSearchQuery(''),
                ),
                const SizedBox(height: 16),
                _ConnectionBanner(
                  isRemote: controller.backendAvailable,
                  message: controller.notice ??
                      (controller.backendAvailable
                          ? 'Connected to the local backend.'
                          : 'Backend is offline. Demo data is active.'),
                  onRetry: controller.refresh,
                ),
                const SizedBox(height: 16),
                if (controller.isLoading)
                  _LoadingState(
                    count: constraints.maxWidth >= 900 ? 3 : 2,
                  )
                else if (notes.isEmpty)
                  _EmptyState(
                    hasQuery: hasQuery,
                    onClearSearch: hasQuery ? () => controller.setSearchQuery('') : null,
                    onRecord: controller.startRecording,
                    onUpload: controller.pickAudioFile,
                  )
                else
                  ...notes.map((note) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _RecordingCard(
                          note: note,
                          onTap: () => context.go('/recordings/${note.id}'),
                        ),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.controller,
    required this.totalCount,
    required this.readyCount,
  });

  final PlaudeController controller;
  final int totalCount;
  final int readyCount;

  @override
  Widget build(BuildContext context) {
    final modeLabel = controller.backendAvailable ? 'HTTP mode' : 'Demo mode';
    final modeDetail = controller.backendAvailable
        ? 'The backend is reachable and test flows will exercise live HTTP.'
        : 'The backend is offline; you can still test the UX against local demo data.';

    return Container(
      padding: const EdgeInsets.all(28),
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
            'Meeting memory without the busywork',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Capture voice notes, structure the transcript, and keep a chat-ready knowledge thread for every recording.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.88)),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricPill(label: 'Notes', value: '$totalCount'),
              _MetricPill(label: 'Ready', value: '$readyCount'),
              _ModePill(label: modeLabel, detail: modeDetail),
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
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.label,
    required this.detail,
  });

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 210),
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
          Text(
            detail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.onChanged,
    required this.onClear,
  });
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search by topic, summary or transcript',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: onClear == null
                ? null
                : IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear_rounded),
                    tooltip: 'Clear search',
                  ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({
    required this.isRemote,
    required this.message,
    required this.onRetry,
  });

  final bool isRemote;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final background = isRemote ? const Color(0xFFE8F3E4) : const Color(0xFFFFF4D6);
    final icon = isRemote ? Icons.cloud_done_outlined : Icons.cloud_off_outlined;
    final label = isRemote ? 'Connected' : 'Offline / demo';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _LoadingCard(index: index),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E1D6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 80,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E8DC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF0E8DC),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 16,
              width: index.isEven ? 260 : 330,
              decoration: BoxDecoration(
                color: const Color(0xFFF0E8DC),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                3,
                (_) => Container(
                  width: 84,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6EFE4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasQuery,
    required this.onClearSearch,
    required this.onRecord,
    required this.onUpload,
  });

  final bool hasQuery;
  final VoidCallback? onClearSearch;
  final Future<void> Function() onRecord;
  final Future<void> Function() onUpload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome_outlined, size: 42),
            const SizedBox(height: 14),
            Text(
              hasQuery ? 'No notes match your search' : 'No notes yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Try a broader keyword or clear the search to inspect the full library.'
                  : 'Start by recording a voice note or uploading existing audio.',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (onClearSearch != null)
                  OutlinedButton.icon(
                    onPressed: onClearSearch,
                    icon: const Icon(Icons.clear_rounded),
                    label: const Text('Clear search'),
                  ),
                FilledButton.icon(
                  onPressed: onRecord,
                  icon: const Icon(Icons.mic_none_rounded),
                  label: const Text('Record'),
                ),
                OutlinedButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Upload audio'),
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
    final format = DateFormat('dd MMM yyyy - HH:mm');

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
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Chip(label: Text(note.status.label)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                note.summary?.overview ?? 'Uploaded and waiting for transcript + summary.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniMeta(icon: Icons.schedule_rounded, label: format.format(note.createdAt.toLocal())),
                  _MiniMeta(icon: Icons.graphic_eq_rounded, label: note.sourceType),
                  _MiniMeta(icon: Icons.notes_rounded, label: '${note.transcriptSegments.length} segments'),
                ],
              ),
              if (note.noteArtifact case final artifact?) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: artifact.tags.map((tag) => Chip(label: Text(tag))).toList(),
                ),
              ],
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
