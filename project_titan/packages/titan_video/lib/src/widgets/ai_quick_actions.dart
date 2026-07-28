import 'package:flutter/material.dart';

/// Material 3 AI Quick Actions bar for video learning.
class AIQuickActions extends StatelessWidget {
  final VoidCallback onExplainTimestamp;
  final VoidCallback onGenerateSummary;
  final VoidCallback onCreateFlashcards;
  final VoidCallback onGenerateQuiz;

  const AIQuickActions({
    super.key,
    required this.onExplainTimestamp,
    required this.onGenerateSummary,
    required this.onCreateFlashcards,
    required this.onGenerateQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: const Text('Explain Timestamp'),
            onPressed: onExplainTimestamp,
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.summarize_rounded, size: 16),
            label: const Text('AI Summary'),
            onPressed: onGenerateSummary,
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.style_rounded, size: 16),
            label: const Text('Create Flashcards'),
            onPressed: onCreateFlashcards,
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.quiz_rounded, size: 16),
            label: const Text('Generate Quiz'),
            onPressed: onGenerateQuiz,
          ),
        ],
      ),
    );
  }
}
