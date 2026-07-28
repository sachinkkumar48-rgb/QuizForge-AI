import 'package:flutter/material.dart';

/// Material 3 banner alerting users of offline status and queued requests.
class OfflineIndicatorBanner extends StatelessWidget {
  final bool isOffline;
  final int pendingQueueCount;
  final VoidCallback? onRetrySync;

  const OfflineIndicatorBanner({
    super.key,
    required this.isOffline,
    this.pendingQueueCount = 0,
    this.onRetrySync,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && pendingQueueCount == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.secondaryContainer,
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.wifi_off : Icons.cloud_upload_outlined,
            size: 18,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOffline
                  ? 'Offline Mode • $pendingQueueCount AI requests queued'
                  : 'Syncing $pendingQueueCount queued AI requests...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetrySync != null)
            TextButton(
              onPressed: onRetrySync,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Sync Now'),
            ),
        ],
      ),
    );
  }
}
