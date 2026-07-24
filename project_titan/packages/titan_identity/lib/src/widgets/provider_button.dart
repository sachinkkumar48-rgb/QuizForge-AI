import 'package:flutter/material.dart';

import '../auth/auth_provider.dart';

/// Material 3 button for authenticating with a specific AuthProviderType.
class ProviderButton extends StatelessWidget {
  final AuthProviderType providerType;
  final VoidCallback onPressed;
  final bool isLoading;

  const ProviderButton({
    super.key,
    required this.providerType,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String label;
    IconData icon;
    ButtonStyle style;

    switch (providerType) {
      case AuthProviderType.guest:
        label = 'Continue as Guest';
        icon = Icons.person_outline_rounded;
        style = OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        );
      case AuthProviderType.google:
        label = 'Sign in with Google';
        icon = Icons.g_mobiledata_rounded;
        style = FilledButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerHigh,
          foregroundColor: colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        );
      case AuthProviderType.emailPassword:
        label = 'Sign in with Email';
        icon = Icons.email_outlined;
        style = FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        );
    }

    if (isLoading) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
      );
    }

    if (providerType == AuthProviderType.guest) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20.0),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: style,
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20.0),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: style,
    );
  }
}
