import 'package:flutter/material.dart';
import '../models/live_models.dart';

/// Material 3 Card displaying live class details, status, and join trigger.
class LiveClassCard extends StatelessWidget {
  final LiveClass liveClass;
  final VoidCallback? onTap;
  final VoidCallback? onJoinTap;

  const LiveClassCard({
    super.key,
    required this.liveClass,
    this.onTap,
    this.onJoinTap,
  });

  @override
  Widget build(BuildContext me) {
    final theme = Theme.of(me);
    final status =
        liveClass.activeSession?.status ?? LiveSessionStatus.scheduled;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == LiveSessionStatus.live
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: status == LiveSessionStatus.live
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    liveClass.subjectCategory,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                liveClass.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                liveClass.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    liveClass.instructorName,
                    style: theme.textTheme.labelLarge,
                  ),
                  const Spacer(),
                  if (onJoinTap != null)
                    FilledButton.icon(
                      onPressed: onJoinTap,
                      icon: Icon(
                        status == LiveSessionStatus.live
                            ? Icons.videocam
                            : Icons.play_arrow,
                        size: 18,
                      ),
                      label: Text(
                        status == LiveSessionStatus.live ? 'Join LIVE' : 'View',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
