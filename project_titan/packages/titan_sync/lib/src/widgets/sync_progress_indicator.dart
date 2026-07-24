import 'package:flutter/material.dart';

import '../engine/sync_manager.dart';

/// Material 3 Progress Indicator for displaying ongoing cloud synchronization progress.
class SyncProgressIndicator extends StatelessWidget {
  final SyncEngineStatus status;
  final double? progress;

  const SyncProgressIndicator({
    super.key,
    required this.status,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (status != SyncEngineStatus.syncing) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 4.0,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
    );
  }
}
