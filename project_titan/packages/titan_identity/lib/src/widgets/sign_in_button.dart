import 'package:flutter/material.dart';

/// Reusable Material 3 action button for initiating sign-in flows.
class SignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const SignInButton({
    super.key,
    required this.onPressed,
    this.label = 'Sign In',
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.login_rounded, size: 18.0),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }
}
