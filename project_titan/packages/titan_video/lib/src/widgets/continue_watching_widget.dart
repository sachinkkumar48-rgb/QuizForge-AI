import 'package:flutter/material.dart';
import '../models/continue_watching.dart';

/// Material 3 Continue Watching Card widget.
class ContinueWatchingWidget extends StatelessWidget {
  final ContinueWatching item;
  final VoidCallback onResumeTap;

  const ContinueWatchingWidget({
    super.key,
    required this.item,
    required this.onResumeTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onResumeTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.play_circle_fill_rounded,
                    color: colorScheme.primary, size: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.videoTitle,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: item.progressPercentage / 100.0,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.lastPositionSeconds}s / ${item.totalDurationSeconds}s (${item.progressPercentage.toStringAsFixed(0)}%)',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: onResumeTap,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
