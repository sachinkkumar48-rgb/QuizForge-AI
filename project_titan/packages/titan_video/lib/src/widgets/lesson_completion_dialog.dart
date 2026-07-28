import 'package:flutter/material.dart';
import '../models/video_content.dart';

/// Material 3 Lesson Completion Dialog shown upon 100% video completion.
class LessonCompletionDialog extends StatelessWidget {
  final VideoContent video;
  final VoidCallback onStartQuiz;
  final VoidCallback onCreateFlashcards;
  final VoidCallback onNextLesson;

  const LessonCompletionDialog({
    super.key,
    required this.video,
    required this.onStartQuiz,
    required this.onCreateFlashcards,
    required this.onNextLesson,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(Icons.stars_rounded, size: 48, color: colorScheme.primary),
      title: const Text('Lesson Completed!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Great job completing "${video.title}"!',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Reinforce your learning with AI quizzes or flashcards.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: onCreateFlashcards,
          icon: const Icon(Icons.style_rounded),
          label: const Text('Flashcards'),
        ),
        ElevatedButton.icon(
          onPressed: onStartQuiz,
          icon: const Icon(Icons.quiz_rounded),
          label: const Text('Take Quiz'),
        ),
        FilledButton.icon(
          onPressed: onNextLesson,
          icon: const Icon(Icons.skip_next_rounded),
          label: const Text('Next Lesson'),
        ),
      ],
    );
  }
}
