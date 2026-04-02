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
    final isReady = recording?.isReady ?? false;

    return AppShell(
      title: 'Chat contextual',
      subtitle: 'Perguntas sugeridas e respostas ancoradas apenas na gravação atual.',
      navigationIndex: 1,
      onNavigationSelected: (index) => _goToIndex(context, index),
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('/recordings/${widget.recordingId}'),
          icon: const Icon(Icons.article_outlined),
          label: const Text('Voltar ao detalhe'),
        ),
      ],
      child: recording == null
          ? const _MissingChatState()
          : Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(recording.title, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 6),
                              Text('Projeto ${recording.projectId} • ${recording.status.label}'),
                            ],
                          ),
                        ),
                        Chip(label: Text(recording.status.label)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!isReady)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4D6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'O chat será liberado quando a gravação atingir o estado ready.',
                    ),
                  ),
                if (!isReady) const SizedBox(height: 16),
                Expanded(
                  child: messages.isEmpty
                      ? _ChatEmptyState(
                          recordingTitle: recording.title,
                          enabled: isReady,
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
                                                  child: Text(citation.quote),
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
                  disabled: controller.isChatBusy(widget.recordingId) || !isReady,
                  onSend: (question) => _submitPrompt(controller, question),
                ),
              ],
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

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({
    required this.recordingTitle,
    required this.enabled,
    required this.onPromptTap,
  });

  final String recordingTitle;
  final bool enabled;
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
            Text(
              enabled
                  ? 'Use o assistente para perguntar sobre decisões, participantes, riscos ou próximos passos.'
                  : 'Aguarde a conclusão da transcrição para usar o chat contextual.',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PromptChip(label: 'Quais são os próximos passos?', enabled: enabled, onTap: onPromptTap),
                _PromptChip(label: 'Resuma as principais decisões.', enabled: enabled, onTap: onPromptTap),
                _PromptChip(label: 'Quais riscos foram mencionados?', enabled: enabled, onTap: onPromptTap),
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
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: enabled ? () => onTap(label) : null,
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
              child: Text(disabled ? 'Indisponível' : 'Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingChatState extends StatelessWidget {
  const _MissingChatState();

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
                const Text('A gravação não foi encontrada ou a rota aponta para dados antigos.'),
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
