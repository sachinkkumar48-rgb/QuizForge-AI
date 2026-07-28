import 'package:flutter/material.dart';

/// Material 3 action button for manually retrying sync operations.
class RetryButton extends StatelessWidget {
  final bool isSyncing;
  final VoidCallback onPressed;

  const RetryButton({
    super.key,
    required this.isSyncing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isSyncing ? null : onPressed,
      icon: isSyncing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync_rounded, size: 18),
      label: Text(isSyncing ? 'Syncing...' : 'Retry Sync'),
    );
  }
}
