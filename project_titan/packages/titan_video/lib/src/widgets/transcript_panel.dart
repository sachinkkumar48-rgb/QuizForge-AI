import 'package:flutter/material.dart';
import '../models/transcript_segment.dart';

/// Material 3 Transcript Panel displaying searchable video transcript segments.
class TranscriptPanel extends StatelessWidget {
  final List<TranscriptSegment> segments;
  final int currentTimestampSeconds;
  final ValueChanged<TranscriptSegment> onSegmentTap;
  final ValueChanged<TranscriptSegment>? onExplainSegment;

  const TranscriptPanel({
    super.key,
    required this.segments,
    required this.currentTimestampSeconds,
    required this.onSegmentTap,
    this.onExplainSegment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (segments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No transcript available.',
              style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return ListView.builder(
      itemCount: segments.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final seg = segments[index];
        final isActive = currentTimestampSeconds >= seg.startSeconds &&
            currentTimestampSeconds <= seg.endSeconds;

        return Card(
          color: isActive ? colorScheme.primaryContainer : colorScheme.surface,
          elevation: isActive ? 2 : 0,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHigh,
              child: Text(
                '${seg.startSeconds}s',
                style: theme.textTheme.labelSmall?.copyWith(
                  color:
                      isActive ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
            ),
            title: Text(seg.text, style: theme.textTheme.bodyMedium),
            subtitle: seg.speakerName != null
                ? Text('Speaker: ${seg.speakerName}',
                    style: theme.textTheme.labelSmall)
                : null,
            trailing: onExplainSegment != null
                ? IconButton(
                    icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                    onPressed: () => onExplainSegment!(seg),
                    tooltip: 'AI Explain Segment',
                  )
                : null,
            onTap: () => onSegmentTap(seg),
          ),
        );
      },
    );
  }
}
