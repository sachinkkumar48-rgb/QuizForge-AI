import 'package:flutter/material.dart';

import '../models/user_session.dart';
import 'session_status_chip.dart';
import 'user_avatar.dart';

/// Material 3 Card rendering active user profile, session details, and action triggers.
class ProfileCard extends StatelessWidget {
  final UserSession? session;
  final VoidCallback? onSignOutPressed;
  final VoidCallback? onEditProfilePressed;

  const ProfileCard({
    super.key,
    this.session,
    this.onSignOutPressed,
    this.onEditProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = session?.user;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(user: user, radius: 28.0),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Guest User',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        user?.email ?? 'Offline Mode',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SessionStatusChip(session: session),
              ],
            ),
            const Divider(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Auth Provider: ${user?.providerType.name ?? 'None'}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    if (onEditProfilePressed != null)
                      IconButton(
                        onPressed: onEditProfilePressed,
                        icon: const Icon(Icons.edit_outlined, size: 20.0),
                        tooltip: 'Edit Profile',
                      ),
                    if (onSignOutPressed != null && session != null)
                      TextButton.icon(
                        onPressed: onSignOutPressed,
                        icon: const Icon(Icons.logout_rounded, size: 18.0),
                        label: const Text('Sign Out'),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
