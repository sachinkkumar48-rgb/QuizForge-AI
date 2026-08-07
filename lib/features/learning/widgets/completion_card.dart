import 'package:flutter/material.dart';

class CompletionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int progressPercentage;
  final String buttonText;
  final VoidCallback? onContinue;
  final String lessonsCompletedToday;
  final String learningStreak;
  final String nextJourneyTitle;

  const CompletionCard({
    super.key,
    this.title = '✓ Journey Complete',
    this.subtitle = 'Excellent work! You have mastered this module.',
    this.progressPercentage = 100,
    this.buttonText = 'Start Next Journey',
    this.onContinue,
    this.lessonsCompletedToday = '1 Lesson',
    this.learningStreak = '3 Days 🔥',
    this.nextJourneyTitle = 'Articles 12 & 13',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: BorderSide(
          color: Colors.green.withAlpha(100),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Trophy Header Badge
            Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(30),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.withAlpha(100), width: 2),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 52.0,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 18.0),
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6.0),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),

            // Stat Badges Row (Lessons Completed Today & Learning Streak)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(100),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: theme.colorScheme.primary.withAlpha(60),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 22.0,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'Completed Today',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          lessonsCompletedToday,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer.withAlpha(100),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: theme.colorScheme.tertiary.withAlpha(60),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 22.0,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'Learning Streak',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          learningStreak,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20.0),

            // Next Journey Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: theme.colorScheme.onPrimary,
                      size: 24.0,
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UP NEXT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          nextJourneyTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24.0),

            // Start Next Journey Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.rocket_launch_rounded),
                label: Text(buttonText),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
