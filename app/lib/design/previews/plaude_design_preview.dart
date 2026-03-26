import 'package:flutter/material.dart';

import '../components/plaude_background.dart';
import '../components/plaude_badge.dart';
import '../components/plaude_button.dart';
import '../components/plaude_card.dart';
import '../components/plaude_stat_tile.dart';
import '../components/plaude_status_chip.dart';
import '../components/plaude_transcript_block.dart';

class PlaudeDesignPreview extends StatelessWidget {
  const PlaudeDesignPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaudeBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PlaudeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PlaudeBadge(label: 'Plaude Design System'),
                      SizedBox(height: 16),
                      Text(
                        'Warm, tactile, note-first interface language',
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Built for dense voice-note workflows, grounded chat, and quick scanning across mobile and web.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: const [
                    SizedBox(
                      width: 248,
                      child: PlaudeStatTile(
                        label: 'Notes ready',
                        value: '12',
                        caption: 'Processing stays visible',
                        icon: Icons.auto_awesome_rounded,
                      ),
                    ),
                    SizedBox(
                      width: 248,
                      child: PlaudeStatTile(
                        label: 'Transcript coverage',
                        value: '94%',
                        caption: 'Speaker blocks stay readable',
                        icon: Icons.graphic_eq_rounded,
                      ),
                    ),
                    SizedBox(
                      width: 248,
                      child: PlaudeStatTile(
                        label: 'Chat grounded',
                        value: 'Yes',
                        caption: 'Answer only from note context',
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const PlaudeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PlaudeStatusChip(label: 'Ready', tone: PlaudeStatusTone.success),
                          SizedBox(width: 10),
                          PlaudeStatusChip(label: 'Indexed', tone: PlaudeStatusTone.info),
                          SizedBox(width: 10),
                          PlaudeStatusChip(label: 'Needs retry', tone: PlaudeStatusTone.warning),
                        ],
                      ),
                      SizedBox(height: 18),
                      PlaudeTranscriptBlock(
                        speaker: 'Speaker 1',
                        timestamp: '00:42',
                        text: 'We need the launch branch stable before inviting the test group.',
                        highlight: true,
                      ),
                      SizedBox(height: 12),
                      PlaudeTranscriptBlock(
                        speaker: 'Speaker 2',
                        timestamp: '01:08',
                        text: 'I will wire the upload path and make the error states obvious.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    PlaudeButton(
                      label: 'Primary action',
                      onPressed: () {},
                      icon: Icons.mic_none_rounded,
                    ),
                    PlaudeButton(
                      label: 'Secondary action',
                      onPressed: () {},
                      variant: PlaudeButtonVariant.secondary,
                    ),
                    PlaudeButton(
                      label: 'Ghost action',
                      onPressed: () {},
                      variant: PlaudeButtonVariant.ghost,
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
