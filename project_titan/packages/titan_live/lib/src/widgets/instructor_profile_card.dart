import 'package:flutter/material.dart';
import '../models/live_models.dart';

/// Card displaying instructor profile & bio.
class InstructorProfileCard extends StatelessWidget {
  final InstructorSession instructor;

  const InstructorProfileCard({
    super.key,
    required this.instructor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                instructor.instructorName.isNotEmpty
                    ? instructor.instructorName[0]
                    : 'I',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instructor.instructorName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    instructor.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  if (instructor.bio != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      instructor.bio!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
