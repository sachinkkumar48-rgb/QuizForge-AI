import 'package:flutter/material.dart';
import '../models/tutor_models.dart';

/// Responsive Material 3 panel displaying accumulated tutor memory and misconceptions.
class TutorMemoryPanel extends StatelessWidget {
  final TutorMemory memory;

  const TutorMemoryPanel({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Tutor Memory & Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text('Strengths:', style: theme.textTheme.labelLarge),
            Wrap(
              spacing: 6,
              children: memory.strengths
                  .map((s) => Chip(
                        avatar: const Icon(Icons.star,
                            size: 14, color: Colors.amber),
                        label: Text(s),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Text('Remembered Misconceptions:',
                style: theme.textTheme.labelLarge),
            Wrap(
              spacing: 6,
              children: memory.rememberedMisconceptions
                  .map((m) => Chip(
                        avatar: const Icon(Icons.warning,
                            size: 14, color: Colors.orange),
                        label: Text(m),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
