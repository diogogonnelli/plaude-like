import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design/brand_design_system.dart';
import '../state/plaude_controller.dart';
import 'app_shell.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.recordingId});

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
      subtitle:
          'Perguntas guiadas por evidências da gravação, com respostas ancoradas no transcript atual.',
      navigationIndex: 1,
      onNavigationSelected: (index) => _goToIndex(context, index),
      actions: [
        BrandButton(
          label: 'Voltar ao detalhe',
          icon: Icons.article_outlined,
          variant: BrandButtonVariant.secondary,
          onPressed: () => context.go('/recordings/${widget.recordingId}'),
        ),
      ],
      child: recording == null
          ? const _MissingChatState()
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1040;
                final thread = Column(
                  children: [
                    _ChatHeader(
                      recordingTitle: recording.title,
                      isReady: isReady,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: BrandPanel(
                        child: messages.isEmpty
                            ? _ThreadEmptyState(
                                recordingTitle: recording.title,
                                enabled: isReady,
                                onPromptTap: (prompt) =>
                                    _submitPrompt(controller, prompt),
                              )
                            : ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.only(bottom: 12),
                                itemCount: messages.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final message = messages[index];
                                  return _MessageBubble(message: message);
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Composer(
                      controller: _textController,
                      disabled:
                          controller.isChatBusy(widget.recordingId) || !isReady,
                      onSend: (question) => _submitPrompt(controller, question),
                    ),
                  ],
                );

                final contextPanel = _ChatContextPanel(
                  recordingTitle: recording.title,
                  statusLabel: recording.status.label,
                  summary:
                      recording.summary?.overview ??
                      'Aguardando resumo estruturado.',
                  isReady: isReady,
                  onPromptTap: (prompt) => _submitPrompt(controller, prompt),
                );

                if (!wide) {
                  return Column(
                    children: [
                      Expanded(child: thread),
                      const SizedBox(height: 16),
                      contextPanel,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 8, child: thread),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: contextPanel),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _submitPrompt(
    PlaudeController controller,
    String question,
  ) async {
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
          duration: BrandMotion.medium,
          curve: BrandMotion.standardCurve,
        );
      }
    }
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.recordingTitle, required this.isReady});

  final String recordingTitle;
  final bool isReady;

  @override
  Widget build(BuildContext context) {
    return BrandPanel(
      highlight: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recordingTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  isReady
                      ? 'Conversa destravada com evidências do transcript atual.'
                      : 'O chat será liberado quando a gravação atingir o estado ready.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          BrandStatusPill(
            label: isReady ? 'Chat habilitado' : 'Aguardando processamento',
            tone: isReady ? BrandStatusTone.success : BrandStatusTone.warning,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final dynamic message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isUser ? BrandColors.shellDark : BrandColors.surfaceMuted,
            borderRadius: BorderRadius.circular(BrandRadius.lg),
            border: Border.all(
              color: isUser ? BrandColors.shellDark : BrandColors.stroke,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUser ? 'Você' : 'Assistente SPOT',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isUser ? Colors.white70 : BrandColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isUser ? Colors.white : BrandColors.text,
                ),
              ),
              if (message.citations.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: message.citations
                      .map<Widget>(
                        (citation) => BrandStatusPill(
                          label: citation.quote,
                          tone: isUser
                              ? BrandStatusTone.neutral
                              : BrandStatusTone.info,
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
  }
}

class _ThreadEmptyState extends StatelessWidget {
  const _ThreadEmptyState({
    required this.recordingTitle,
    required this.enabled,
    required this.onPromptTap,
  });

  final String recordingTitle;
  final bool enabled;
  final ValueChanged<String> onPromptTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pergunte sobre "$recordingTitle"',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          enabled
              ? 'Use o chat para identificar decisões, riscos, responsáveis e próximos passos.'
              : 'Aguarde o processamento concluir para abrir o contexto conversacional.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _PromptChip(
              label: 'Quais são os próximos passos?',
              enabled: enabled,
              onTap: onPromptTap,
            ),
            _PromptChip(
              label: 'Resuma as principais decisões.',
              enabled: enabled,
              onTap: onPromptTap,
            ),
            _PromptChip(
              label: 'Quais riscos foram mencionados?',
              enabled: enabled,
              onTap: onPromptTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _ChatContextPanel extends StatelessWidget {
  const _ChatContextPanel({
    required this.recordingTitle,
    required this.statusLabel,
    required this.summary,
    required this.isReady,
    required this.onPromptTap,
  });

  final String recordingTitle;
  final String statusLabel;
  final String summary;
  final bool isReady;
  final ValueChanged<String> onPromptTap;

  @override
  Widget build(BuildContext context) {
    return BrandPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandWordmark(compact: true),
          const SizedBox(height: 18),
          Text(
            'Contexto da conversa',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          BrandStatusPill(
            label: statusLabel,
            tone: isReady ? BrandStatusTone.success : BrandStatusTone.warning,
          ),
          const SizedBox(height: 12),
          Text(recordingTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(summary, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          Text(
            'Prompts rápidos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PromptChip(
                label: 'Liste responsáveis e entregas',
                enabled: isReady,
                onTap: onPromptTap,
              ),
              _PromptChip(
                label: 'Mostre decisões e contexto',
                enabled: isReady,
                onTap: onPromptTap,
              ),
            ],
          ),
        ],
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
      side: const BorderSide(color: BrandColors.stroke),
      backgroundColor: BrandColors.surfaceMuted,
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
    return BrandPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Pergunte sobre decisões, participantes ou itens de ação',
              ),
              onSubmitted: onSend,
            ),
          ),
          const SizedBox(width: 12),
          BrandButton(
            label: disabled ? 'Indisponível' : 'Enviar',
            onPressed: disabled ? null : () => onSend(controller.text),
          ),
        ],
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
        child: BrandPanel(
          highlight: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chat indisponível',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'A gravação não foi encontrada ou a rota aponta para dados antigos.',
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
