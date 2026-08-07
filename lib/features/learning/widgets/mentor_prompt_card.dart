import 'package:flutter/material.dart';

class MentorPromptCard extends StatelessWidget {
  final String promptQuestion;
  final String mentorName;
  final VoidCallback? onRespond;

  const MentorPromptCard({
    super.key,
    required this.promptQuestion,
    this.mentorName = 'SARTHI',
    this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: theme.colorScheme.tertiary.withAlpha(76),
          width: 1.5,
        ),
      ),
      color: theme.colorScheme.tertiaryContainer.withAlpha(60),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_rounded,
                  color: theme.colorScheme.tertiary,
                  size: 22.0,
                ),
                const SizedBox(width: 8.0),
                Text(
                  '$mentorName asks:',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Text(
              promptQuestion,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
            if (onRespond != null) ...[
              const SizedBox(height: 14.0),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: onRespond,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16.0),
                  label: const Text('Continue'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
