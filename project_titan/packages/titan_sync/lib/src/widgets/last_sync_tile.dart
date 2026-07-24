import 'package:flutter/material.dart';

/// Material 3 Widget displaying the formatted timestamp of the last successful sync.
class LastSyncTile extends StatelessWidget {
  final DateTime? lastSyncTime;

  const LastSyncTile({
    super.key,
    this.lastSyncTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String text;
    if (lastSyncTime == null) {
      text = 'Never synced';
    } else {
      final diff = DateTime.now().difference(lastSyncTime!);
      if (diff.inSeconds < 60) {
        text = 'Synced just now';
      } else if (diff.inMinutes < 60) {
        text = 'Synced ${diff.inMinutes}m ago';
      } else {
        text = 'Synced ${diff.inHours}h ago';
      }
    }

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
