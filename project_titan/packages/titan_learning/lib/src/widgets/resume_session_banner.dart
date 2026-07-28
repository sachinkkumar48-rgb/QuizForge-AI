import 'package:flutter/material.dart';

import '../models/learning_session_models.dart';

/// Banner prompting the learner to resume an interrupted study session.
class ResumeSessionBanner extends StatelessWidget {
  final LearningSession session;
  final VoidCallback onResume;
  final VoidCallback onDismiss;

  const ResumeSessionBanner({
    super.key,
    required this.session,
    required this.onResume,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Resume Session Prompt Banner',
      container: true,
      child: MaterialBanner(
        elevation: 2,
        backgroundColor: colorScheme.primaryContainer,
        leading: Icon(Icons.history_rounded, color: colorScheme.primary),
        content: Text(
          'Resume study session for "${session.lessonTitle}"?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: onDismiss,
            child: const Text('Dismiss'),
          ),
          FilledButton(
            onPressed: onResume,
            child: const Text('Resume Session'),
          ),
        ],
      ),
    );
  }
}
