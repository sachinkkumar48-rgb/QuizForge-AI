import 'package:flutter/material.dart';

/// Material 3 card rendering AI Mentor recommendations and tips.
class MentorInsightCard extends StatelessWidget {
  final String mentorTip;
  final VoidCallback? onAskMentor;

  const MentorInsightCard({
    super.key,
    required this.mentorTip,
    this.onAskMentor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0.0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14.0,
                  backgroundColor: colorScheme.primary,
                  child: Icon(Icons.smart_toy,
                      size: 16.0, color: colorScheme.onPrimary),
                ),
                const SizedBox(width: 8.0),
                Text(
                  'AI Mentor Insight',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Text(
              mentorTip,
              style: theme.textTheme.bodyMedium,
            ),
            if (onAskMentor != null) ...[
              const SizedBox(height: 10.0),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onAskMentor,
                  icon: const Icon(Icons.chat, size: 16.0),
                  label: const Text('Consult Mentor'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
