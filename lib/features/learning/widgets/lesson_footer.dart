import 'package:flutter/material.dart';

class LessonFooter extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onAiMentor;
  final int completionPercentage;
  final bool hasPrevious;
  final bool hasNext;

  const LessonFooter({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.onAiMentor,
    required this.completionPercentage,
    this.hasPrevious = true,
    this.hasNext = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(128),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8.0,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasPrevious ? onPrevious : null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18.0),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                // AI Mentor Button
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onAiMentor,
                    icon: Icon(
                      Icons.auto_awesome_rounded,
                      size: 18.0,
                      color: theme.colorScheme.primary,
                    ),
                    label: const Text('AI Mentor'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                // Next Button
                Expanded(
                  child: FilledButton.icon(
                    onPressed: hasNext ? onNext : null,
                    icon: Icon(
                      hasNext ? Icons.arrow_forward_rounded : Icons.check_circle_rounded,
                      size: 18.0,
                    ),
                    label: Text(hasNext ? 'Next' : 'Finish'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              'Journey Progress: $completionPercentage% Completed',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
