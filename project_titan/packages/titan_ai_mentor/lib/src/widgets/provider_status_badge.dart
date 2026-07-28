import 'package:flutter/material.dart';

/// Material 3 status badge displaying active AI provider, status, and latency.
class ProviderStatusBadge extends StatelessWidget {
  final String providerName;
  final bool isOnline;
  final int? latencyMs;
  final VoidCallback? onTap;

  const ProviderStatusBadge({
    super.key,
    required this.providerName,
    this.isOnline = true,
    this.latencyMs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusColor = isOnline ? Colors.green : colorScheme.error;
    final statusText = isOnline
        ? '${providerName.toUpperCase()}${latencyMs != null ? ' • ${latencyMs}ms' : ''}'
        : '${providerName.toUpperCase()} (OFFLINE)';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isOnline
              ? colorScheme.surfaceContainerHigh
              : colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isOnline
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
