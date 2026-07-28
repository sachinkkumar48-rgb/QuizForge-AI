import 'package:flutter/material.dart';

/// Material 3 banner notifying users when sync conflicts are detected.
class ConflictNotificationBanner extends StatelessWidget {
  final int conflictCount;
  final VoidCallback? onResolvePressed;

  const ConflictNotificationBanner({
    super.key,
    required this.conflictCount,
    this.onResolvePressed,
  });

  @override
  Widget build(BuildContext context) {
    if (conflictCount <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$conflictCount sync conflict${conflictCount > 1 ? 's' : ''} detected across devices.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onResolvePressed != null)
            TextButton(
              onPressed: onResolvePressed,
              child: Text(
                'Review & Resolve',
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
        ],
      ),
    );
  }
}
