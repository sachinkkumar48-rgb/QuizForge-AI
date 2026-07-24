import 'package:flutter/material.dart';

import '../models/user.dart';

/// Material 3 User Avatar displaying network image, fallback initials, or guest icon.
class UserAvatar extends StatelessWidget {
  final User? user;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.user,
    this.radius = 20.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget child;
    if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
      child = CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(user!.photoUrl!),
        backgroundColor: colorScheme.primaryContainer,
      );
    } else if (user != null && user!.displayName.isNotEmpty) {
      final initials = user!.displayName
          .trim()
          .split(' ')
          .take(2)
          .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
          .join();
      child = CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          initials,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      child = CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.surfaceContainerHigh,
        child: Icon(
          Icons.person_outline_rounded,
          size: radius * 1.2,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: child,
      );
    }

    return child;
  }
}
