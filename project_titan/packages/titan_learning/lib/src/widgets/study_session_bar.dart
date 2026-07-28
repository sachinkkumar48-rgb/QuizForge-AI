import 'package:flutter/material.dart';

import '../models/learning_session_models.dart';

/// Top bar widget displaying live study session timer, pause/resume controls, and current lesson title.
class StudySessionBar extends StatelessWidget {
  final LearningSession session;
  final VoidCallback? onPauseTap;
  final VoidCallback? onResumeTap;
  final VoidCallback? onExitTap;

  const StudySessionBar({
    super.key,
    required this.session,
    this.onPauseTap,
    this.onResumeTap,
    this.onExitTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isPaused = session.status == LearningSessionStatus.paused;

    return Semantics(
      label: 'Study Session Header Bar',
      container: true,
      child: Container(
        color: colorScheme.surfaceContainerHigh,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: onExitTap,
              tooltip: 'Exit Session',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    session.lessonTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    session.courseTitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isPaused)
              FilledButton.icon(
                onPressed: onResumeTap,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Resume'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: onPauseTap,
                icon: const Icon(Icons.pause_rounded, size: 18),
                label: const Text('Pause'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
