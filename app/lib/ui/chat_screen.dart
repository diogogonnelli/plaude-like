import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/plaude_controller.dart';
import 'app_shell.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.recordingId,
  });

  final String recordingId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaudeController>();
    final recording = controller.findById(widget.recordingId);
    final messages = recording?.chatSession?.messages ?? const [];

    return AppShell(
      title: 'Chat contextual',
      navigationIndex: 0,
      onNavigationSelected: (index) => context.go(index == 0 ? '/' : '/settings'),
      actions: [
        OutlinedButton.icon(
          onPressed: recording == null
              ? null
              : () async {
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
          label: const Text('Exportar nota'),
        ),
      ],
      child: recording == null
          ? _MissingChatState(onBack: () => context.go('/'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;

                return Column(
                  children: [
                    if (wide) ...[
                      _ChatContextCard(recordingId: recording.id, title: recording.title, status: recording.status.label),
                      const SizedBox(height: 16),
                    ],
                    Expanded(
                      child: messages.isEmpty
                          ? _ChatEmptyState(
                              recordingTitle: recording.title,
                              onPromptTap: (prompt) => _submitPrompt(controller, prompt),
                            )
                          : ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: messages.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final isUser = message.role == 'user';
                                return Align(
                                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 760),
                                    child: Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: isUser ? const Color(0xFF2E2521) : Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: isUser ? const Color(0xFF2E2521) : const Color(0xFFD8CFC2),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isUser ? 'Você' : 'Assistente',
                                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                                  color: isUser ? Colors.white70 : null,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            message.content,
                                            style: TextStyle(color: isUser ? Colors.white : null),
                                          ),
                                          if (message.citations.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: message.citations
                                                  .map(
                                                    (citation) => Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                      decoration: BoxDecoration(
                                                        color: isUser
                                                            ? Colors.white.withValues(alpha: 0.08)
                                                            : const Color(0xFFF8F4EE),
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      child: Text(
                                                        citation.quote,
                                                        style: TextStyle(color: isUser ? Colors.white70 : null),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    _Composer(
                      controller: _textController,
                      disabled: controller.isChatBusy(widget.recordingId),
                      onSend: (question) => _submitPrompt(controller, question),
                    ),
                    if (controller.notice case final String notice) ...[
                      const SizedBox(height: 12),
                      _InlineStatus(message: notice, remote: controller.backendAvailable),
                    ],
                  ],
                );
              },
            ),
    );
  }

  Future<void> _submitPrompt(PlaudeController controller, String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      return;
    }

    _textController.clear();
    await controller.sendChat(widget.recordingId, trimmed);
    if (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
  }
}

class _ChatContextCard extends StatelessWidget {
  const _ChatContextCard({
    required this.recordingId,
    required this.title,
    required this.status,
  });

  final String recordingId;
  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text('ID da gravação: $recordingId'),
                ],
              ),
            ),
            Chip(label: Text(status)),
          ],
        ),
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({
    required this.recordingTitle,
    required this.onPromptTap,
  });

  final String recordingTitle;
  final ValueChanged<String> onPromptTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pergunte sobre "$recordingTitle"', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Use o assistente para perguntar sobre decisões, participantes, riscos ou próximos passos com base apenas nesta nota.'),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PromptChip(label: 'Quais são os próximos passos?', onTap: onPromptTap),
                _PromptChip(label: 'Resuma as principais decisões.', onTap: onPromptTap),
                _PromptChip(label: 'Qual foi a responsabilidade do Participante 2?', onTap: onPromptTap),
                _PromptChip(label: 'Quais riscos foram mencionados?', onTap: onPromptTap),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () => onTap(label),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.disabled,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Pergunte sobre decisões, participantes ou itens de ação',
                ),
                onSubmitted: onSend,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: disabled ? null : () => onSend(controller.text),
              child: Text(disabled ? 'Enviando' : 'Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({
    required this.message,
    required this.remote,
  });

  final String message;
  final bool remote;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: remote ? const Color(0xFFE8F3E4) : const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(message),
    );
  }
}

class _MissingChatState extends StatelessWidget {
  const _MissingChatState({required this.onBack});

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
                Text('Chat indisponível', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('A gravação não foi encontrada ou a rota aponta para dados antigos. Volte para a biblioteca e tente novamente.'),
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
