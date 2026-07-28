import 'package:flutter/material.dart';
import '../models/learning_content_models.dart';

/// Reusable Material 3 list tile widget rendering a single [LearningContent] item.
class LearningContentTile extends StatelessWidget {
  final LearningContent content;
  final bool isSelected;
  final VoidCallback? onTap;

  const LearningContentTile({
    super.key,
    required this.content,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompleted = content.progress?.isCompleted ?? false;

    return Card(
      elevation: 0.0,
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.4)
          : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            _getContentIcon(content.type),
            size: 20.0,
            color: isCompleted
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          content.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${content.type.name.toUpperCase()} • ${content.metadata.estimatedDurationMinutes} mins • ${content.metadata.author}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: isCompleted
            ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
            : Icon(Icons.arrow_forward_ios_rounded,
                size: 14.0, color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  IconData _getContentIcon(ContentType type) {
    switch (type) {
      case ContentType.video:
        return Icons.play_circle_outline_rounded;
      case ContentType.pdf:
        return Icons.picture_as_pdf_outlined;
      case ContentType.notes:
        return Icons.article_outlined;
      case ContentType.audio:
        return Icons.headset_outlined;
      case ContentType.liveClass:
        return Icons.live_tv_rounded;
      case ContentType.quiz:
      case ContentType.pyq:
        return Icons.quiz_outlined;
      case ContentType.flashcards:
        return Icons.style_outlined;
      case ContentType.mindMap:
        return Icons.hub_outlined;
      case ContentType.interactive:
        return Icons.touch_app_outlined;
      case ContentType.aiConversation:
        return Icons.auto_awesome_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }
}
