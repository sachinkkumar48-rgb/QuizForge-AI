import 'package:flutter/material.dart';

import '../models/user_session.dart';

/// Material 3 status badge displaying session state (Active, Guest, Offline, Expired).
class SessionStatusChip extends StatelessWidget {
  final UserSession? session;

  const SessionStatusChip({
    super.key,
    this.session,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String label;
    Color bg;
    Color fg;
    IconData icon;

    if (session == null || !session!.isActive) {
      label = 'Signed Out';
      bg = colorScheme.errorContainer;
      fg = colorScheme.onErrorContainer;
      icon = Icons.no_accounts_outlined;
    } else if (session!.user.isGuest) {
      label = 'Guest Mode';
      bg = colorScheme.tertiaryContainer;
      fg = colorScheme.onTertiaryContainer;
      icon = Icons.person_outline;
    } else if (session!.isOffline) {
      label = 'Offline Mode';
      bg = colorScheme.surfaceContainerHigh;
      fg = colorScheme.onSurfaceVariant;
      icon = Icons.wifi_off_outlined;
    } else {
      label = 'Active Session';
      bg = colorScheme.primaryContainer;
      fg = colorScheme.onPrimaryContainer;
      icon = Icons.verified_user_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: fg),
          const SizedBox(width: 4.0),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
