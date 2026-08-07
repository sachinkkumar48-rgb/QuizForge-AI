import 'package:flutter/material.dart';

enum NodeState { completed, current, locked }

class KnowledgeNode extends StatelessWidget {
  final String lessonId;
  final String title;
  final String estimatedTime;
  final String difficulty;
  final NodeState state;
  final VoidCallback? onTap;

  const KnowledgeNode({
    super.key,
    required this.lessonId,
    required this.title,
    required this.estimatedTime,
    required this.difficulty,
    required this.state,
    this.onTap,
  });

  Color _getBadgeColor(ThemeData theme) {
    switch (state) {
      case NodeState.completed:
        return Colors.green.shade700;
      case NodeState.current:
        return theme.colorScheme.primary;
      case NodeState.locked:
        return theme.colorScheme.outline;
    }
  }

  Color _getCardBackgroundColor(ThemeData theme) {
    switch (state) {
      case NodeState.completed:
        return Colors.green.withAlpha(20);
      case NodeState.current:
        return theme.colorScheme.primaryContainer.withAlpha(50);
      case NodeState.locked:
        return theme.colorScheme.surfaceContainerHighest.withAlpha(50);
    }
  }

  IconData _getStateIcon() {
    switch (state) {
      case NodeState.completed:
        return Icons.check_circle_rounded;
      case NodeState.current:
        return Icons.play_circle_fill_rounded;
      case NodeState.locked:
        return Icons.lock_rounded;
    }
  }

  String _getStateLabel() {
    switch (state) {
      case NodeState.completed:
        return 'COMPLETED';
      case NodeState.current:
        return 'IN PROGRESS';
      case NodeState.locked:
        return 'LOCKED';
    }
  }

  Color _getDifficultyColor(ThemeData theme) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.teal;
      case 'intermediate':
        return Colors.orange.shade800;
      case 'advanced':
        return Colors.deepPurple;
      default:
        return theme.colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = _getBadgeColor(theme);
    final isInteractive = state != NodeState.locked;

    return Card(
      elevation: state == NodeState.current ? 3 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: state == NodeState.current
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: state == NodeState.current ? 2.0 : 1.0,
        ),
      ),
      color: _getCardBackgroundColor(theme),
      child: InkWell(
        onTap: isInteractive ? onTap : null,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left State Avatar / Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeColor, width: 2),
                ),
                child: Icon(
                  _getStateIcon(),
                  color: badgeColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16.0),

              // Node Content Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Lesson ID & Status Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            lessonId,
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: badgeColor.withAlpha(80)),
                          ),
                          child: Text(
                            _getStateLabel(),
                            style: TextStyle(
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),

                    // Title
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: state == NodeState.locked
                            ? theme.colorScheme.onSurface.withAlpha(140)
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8.0),

                    // Metadata Row: Estimated Time & Difficulty
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14.0,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          estimatedTime,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(theme),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          difficulty,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getDifficultyColor(theme),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Trailing Action Indicator
              if (isInteractive)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.0,
                  color: badgeColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
