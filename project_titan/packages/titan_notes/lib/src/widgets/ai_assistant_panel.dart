import 'package:flutter/material.dart';

/// Material 3 AI Assistant Panel for smart note enhancement.
class AIAssistantPanel extends StatelessWidget {
  final VoidCallback onExplainNote;
  final VoidCallback onImproveNote;
  final VoidCallback onSimplifyNote;
  final VoidCallback onGenerateSummary;
  final VoidCallback onConvertToFlashcards;

  const AIAssistantPanel({
    super.key,
    required this.onExplainNote,
    required this.onImproveNote,
    required this.onSimplifyNote,
    required this.onGenerateSummary,
    required this.onConvertToFlashcards,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.purple),
                const SizedBox(width: 8),
                Text('AI Note Assistant', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                  label: const Text('Explain Note'),
                  onPressed: onExplainNote,
                ),
                ActionChip(
                  avatar: const Icon(Icons.auto_fix_high_rounded, size: 16),
                  label: const Text('Improve Structure'),
                  onPressed: onImproveNote,
                ),
                ActionChip(
                  avatar: const Icon(Icons.compress_rounded, size: 16),
                  label: const Text('Simplify'),
                  onPressed: onSimplifyNote,
                ),
                ActionChip(
                  avatar: const Icon(Icons.summarize_rounded, size: 16),
                  label: const Text('AI Summary'),
                  onPressed: onGenerateSummary,
                ),
                ActionChip(
                  avatar: const Icon(Icons.style_rounded, size: 16),
                  label: const Text('Flashcards'),
                  onPressed: onConvertToFlashcards,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
