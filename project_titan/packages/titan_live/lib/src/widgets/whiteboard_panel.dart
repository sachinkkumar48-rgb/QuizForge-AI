import 'package:flutter/material.dart';
import '../models/live_models.dart';

/// Material 3 Panel displaying captured whiteboard snapshots during a live class.
class WhiteboardPanel extends StatelessWidget {
  final List<WhiteboardSnapshot> snapshots;
  final void Function(WhiteboardSnapshot)? onSnapshotTap;

  const WhiteboardPanel({
    super.key,
    required this.snapshots,
    this.onSnapshotTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (snapshots.isEmpty) {
      return Center(
        child: Text(
          'No whiteboard snapshots captured yet.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      itemCount: snapshots.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final wb = snapshots[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.gesture),
            title: Text(wb.title),
            subtitle: Text('Captured by ${wb.capturedBy}'),
            trailing: IconButton(
              icon: const Icon(Icons.download_outlined),
              onPressed:
                  onSnapshotTap != null ? () => onSnapshotTap!(wb) : null,
            ),
          ),
        );
      },
    );
  }
}
