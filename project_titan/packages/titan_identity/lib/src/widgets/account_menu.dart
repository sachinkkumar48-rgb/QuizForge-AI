import 'package:flutter/material.dart';

import '../models/user_session.dart';
import 'user_avatar.dart';

/// Popup Account Menu widget providing quick profile overview and account action shortcuts.
class AccountMenu extends StatelessWidget {
  final UserSession? session;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onSignOutPressed;

  const AccountMenu({
    super.key,
    this.session,
    this.onProfilePressed,
    this.onSettingsPressed,
    this.onSignOutPressed,
  });

  @override
  Widget build(BuildContext context) {
    final user = session?.user;

    return PopupMenuButton<String>(
      tooltip: 'Account Settings',
      icon: UserAvatar(user: user, radius: 18.0),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            onProfilePressed?.call();
          case 'settings':
            onSettingsPressed?.call();
          case 'sign_out':
            onSignOutPressed?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.displayName ?? 'Guest User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                user?.email ?? 'Offline',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Divider(),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18),
              SizedBox(width: 8),
              Text('My Profile'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 18),
              SizedBox(width: 8),
              Text('Account Settings'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'sign_out',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Sign Out', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
