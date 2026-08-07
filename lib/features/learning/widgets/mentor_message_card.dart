import 'package:flutter/material.dart';

class MentorMessageCard extends StatelessWidget {
  final String mentorName;
  final String message;
  final String? greeting;

  const MentorMessageCard({
    super.key,
    this.mentorName = 'SARTHI',
    required this.message,
    this.greeting = 'Hello! I\'m your AI Learning Mentor.',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
        side: BorderSide(
          color: theme.colorScheme.primary.withAlpha(60),
          width: 1.2,
        ),
      ),
      color: theme.colorScheme.primaryContainer.withAlpha(90),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mentor Avatar Badge
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(70),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: theme.colorScheme.onPrimary,
                size: 22.0,
              ),
            ),
            const SizedBox(width: 14.0),
            // Message Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        mentorName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(35),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          'AI MENTOR',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (greeting != null && greeting!.isNotEmpty) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      greeting!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8.0),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
