import 'package:flutter/material.dart';
import '../models/tutor_models.dart';

/// Responsive Material 3 card presenting structured AI Tutor lessons.
class TutorLessonCard extends StatelessWidget {
  final TutorLesson lesson;
  final VoidCallback? onStartPractice;

  const TutorLessonCard({
    super.key,
    required this.lesson,
    this.onStartPractice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lesson.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(lesson.difficulty.name.toUpperCase()),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Explanation',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lesson.explanation,
              style: theme.textTheme.bodyMedium,
            ),
            if (lesson.analogy.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Analogy: ${lesson.analogy}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (lesson.mnemonic.isNotEmpty) ...[
              const SizedBox(height: 8),
              Chip(
                avatar: const Icon(Icons.memory, size: 16),
                label: Text('Mnemonic: ${lesson.mnemonic}'),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onStartPractice,
                icon: const Icon(Icons.fitness_center),
                label: const Text('Start Practice'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
