import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/plaude_controller.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.navigationIndex = 0,
    this.onNavigationSelected,
    this.showCaptureFab = false,
    this.interceptBackToPrimary = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final int navigationIndex;
  final ValueChanged<int>? onNavigationSelected;
  final bool showCaptureFab;
  final bool interceptBackToPrimary;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaudeController>();
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 980;

    return PopScope(
      canPop: !interceptBackToPrimary,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && interceptBackToPrimary && onNavigationSelected != null) {
          onNavigationSelected!(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        floatingActionButton: showCaptureFab
            ? _CaptureFab(
                controller: controller,
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFFAF4),
                Color(0xFFF7F0E5),
                Color(0xFFE9DECD),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (wide)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
                    child: _DesktopRail(
                      selectedIndex: navigationIndex,
                      onDestinationSelected: onNavigationSelected,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(wide ? 18 : 16, 16, 16, wide ? 16 : 88),
                    child: Column(
                      children: [
                        _ShellHeader(
                          title: title,
                          subtitle: subtitle ??
                              'Projeto ativo: ${controller.activeProject?.name ?? 'nenhum projeto selecionado'}',
                          actions: actions,
                        ),
                        const SizedBox(height: 16),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: navigationIndex,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
                  NavigationDestination(icon: Icon(Icons.library_books_rounded), label: 'Biblioteca'),
                  NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'Ajustes'),
                ],
                onDestinationSelected: onNavigationSelected,
              ),
      ),
    );
  }
}

class _ShellHeader extends StatelessWidget {
  const _ShellHeader({
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 20,
        vertical: compact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(compact ? 24 : 28),
        border: Border.all(color: const Color(0xFFDCCDBA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCopy(title: title, subtitle: subtitle),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 10, runSpacing: 10, children: actions),
                ],
              ],
            )
          : Row(
              children: [
                Expanded(child: _HeaderCopy(title: title, subtitle: subtitle)),
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Wrap(spacing: 12, runSpacing: 12, children: actions),
                ],
              ],
            ),
    );
  }
}

class _HeaderCopy extends StatelessWidget {
  const _HeaderCopy({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: compact
              ? Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)
              : Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: compact ? 13 : null,
              ),
        ),
      ],
    );
  }
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaudeController>();

    return Container(
      width: 272,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFDCCDBA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Plaude', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            controller.activeProject?.name ?? 'Operação de notas por projeto',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: NavigationRail(
              selectedIndex: selectedIndex,
              backgroundColor: Colors.transparent,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.home_rounded), label: Text('Home')),
                NavigationRailDestination(icon: Icon(Icons.library_books_rounded), label: Text('Biblioteca')),
                NavigationRailDestination(icon: Icon(Icons.tune_rounded), label: Text('Ajustes')),
              ],
              onDestinationSelected: onDestinationSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureFab extends StatelessWidget {
  const _CaptureFab({
    required this.controller,
  });

  final PlaudeController controller;

  @override
  Widget build(BuildContext context) {
    final cupertino = Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;

    return FloatingActionButton.extended(
      onPressed: () => _openCaptureSheet(context),
      icon: Icon(controller.isRecording ? Icons.stop_circle_outlined : (cupertino ? CupertinoIcons.mic_fill : Icons.mic_rounded)),
      label: Text(controller.isRecording ? 'Parar' : 'Capturar'),
    );
  }

  Future<void> _openCaptureSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFBF6),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Captura rápida', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  controller.activeProject == null
                      ? 'Selecione um projeto para gravar ou enviar áudio.'
                      : 'Projeto ativo: ${controller.activeProject!.name}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: controller.isRecording
                      ? () {
                          Navigator.of(context).pop();
                          controller.stopRecordingAndProcess();
                        }
                      : () {
                          Navigator.of(context).pop();
                          controller.startRecording();
                        },
                  icon: Icon(controller.isRecording ? Icons.stop_circle_outlined : Icons.mic_none_rounded),
                  label: Text(controller.isRecording ? 'Parar gravação' : 'Iniciar gravação'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    controller.pickAudioFile();
                  },
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Enviar áudio'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
