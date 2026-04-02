import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/brand_design_system.dart';
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

    return PopScope(
      canPop: !interceptBackToPrimary,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && interceptBackToPrimary && onNavigationSelected != null) {
          onNavigationSelected!(0);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1100;
          final medium = constraints.maxWidth >= 760;

          return Scaffold(
            extendBody: true,
            backgroundColor: Colors.transparent,
            floatingActionButton: showCaptureFab
                ? _CaptureFab(controller: controller)
                : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            body: BrandBackground(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (wide) ...[
                        _DesktopRail(
                          controller: controller,
                          selectedIndex: navigationIndex,
                          onDestinationSelected: onNavigationSelected,
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: Column(
                          children: [
                            _ShellHeader(
                              title: title,
                              subtitle:
                                  subtitle ??
                                  'Projeto ativo: ${controller.activeProject?.name ?? 'nenhum projeto selecionado'}',
                              actions: actions,
                              compact: !medium,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: TweenAnimationBuilder<double>(
                                duration: BrandMotion.medium,
                                curve: BrandMotion.standardCurve,
                                tween: Tween(begin: 0.94, end: 1),
                                builder: (context, value, _) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Opacity(
                                      opacity: value.clamp(0.88, 1),
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: wide
                ? null
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: BrandPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: NavigationBar(
                        selectedIndex: navigationIndex,
                        labelBehavior:
                            NavigationDestinationLabelBehavior.alwaysShow,
                        destinations: const [
                          NavigationDestination(
                            icon: Icon(Icons.dashboard_rounded),
                            label: 'Cockpit',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.library_books_rounded),
                            label: 'Biblioteca',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.tune_rounded),
                            label: 'Sistema',
                          ),
                        ],
                        onDestinationSelected: onNavigationSelected,
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _ShellHeader extends StatelessWidget {
  const _ShellHeader({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BrandPanel(
      highlight: true,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 22,
        vertical: compact ? 16 : 20,
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandWordmark(compact: true),
                const SizedBox(height: 18),
                _HeaderCopy(title: title, subtitle: subtitle),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(spacing: 10, runSpacing: 10, children: actions),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: BrandWordmark()),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: _HeaderCopy(title: title, subtitle: subtitle),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: 18),
                  Flexible(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.end,
                      children: actions,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _HeaderCopy extends StatelessWidget {
  const _HeaderCopy({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandBadge(
          label: 'SPOT endorsed workflow',
          leading: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: BrandColors.accent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({
    required this.controller,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final PlaudeController controller;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 308,
      child: BrandPanel(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandWordmark(showSpot: true),
            const SizedBox(height: 18),
            Text(
              'SPOT conectando estratégia, gravação e execução operacional.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            BrandPanel(
              padding: const EdgeInsets.all(18),
              backgroundColor: BrandColors.surfaceMuted,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Projeto ativo',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    controller.activeProject?.name ?? 'Selecione um projeto',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: NavigationRail(
                selectedIndex: selectedIndex,
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_rounded),
                    label: Text('Cockpit'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.library_books_rounded),
                    label: Text('Biblioteca'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.tune_rounded),
                    label: Text('Sistema'),
                  ),
                ],
                onDestinationSelected: onDestinationSelected,
              ),
            ),
            const SizedBox(height: 10),
            const SpotEndorsement(),
          ],
        ),
      ),
    );
  }
}

class _CaptureFab extends StatelessWidget {
  const _CaptureFab({required this.controller});

  final PlaudeController controller;

  @override
  Widget build(BuildContext context) {
    final cupertino =
        Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;

    return FloatingActionButton.extended(
      onPressed: () => _openCaptureSheet(context),
      icon: Icon(
        controller.isRecording
            ? Icons.stop_circle_outlined
            : (cupertino ? CupertinoIcons.mic_fill : Icons.mic_rounded),
      ),
      label: Text(controller.isRecording ? 'Parar captação' : 'Nova captação'),
    );
  }

  Future<void> _openCaptureSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: BrandPanel(
            highlight: true,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandWordmark(compact: true),
                  const SizedBox(height: 16),
                  Text(
                    'Captação rápida',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.activeProject == null
                        ? 'Selecione um projeto para gravar ou enviar áudio.'
                        : 'Projeto ativo: ${controller.activeProject!.name}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  BrandButton(
                    label: controller.isRecording
                        ? 'Parar gravação'
                        : 'Iniciar gravação',
                    icon: controller.isRecording
                        ? Icons.stop_circle_outlined
                        : Icons.mic_none_rounded,
                    onPressed: controller.isRecording
                        ? () {
                            Navigator.of(context).pop();
                            controller.stopRecordingAndProcess();
                          }
                        : () {
                            Navigator.of(context).pop();
                            controller.startRecording();
                          },
                    expanded: true,
                  ),
                  const SizedBox(height: 12),
                  BrandButton(
                    label: 'Enviar áudio',
                    icon: Icons.upload_file_rounded,
                    variant: BrandButtonVariant.secondary,
                    onPressed: () {
                      Navigator.of(context).pop();
                      controller.pickAudioFile();
                    },
                    expanded: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
