import 'package:flutter/material.dart';

/// Dialog requesting confirmation before pausing or abandoning an active study session.
class ExitConfirmationDialog extends StatelessWidget {
  final VoidCallback onPauseAndExit;
  final VoidCallback onAbandon;
  final VoidCallback onCancel;

  const ExitConfirmationDialog({
    super.key,
    required this.onPauseAndExit,
    required this.onAbandon,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exit Study Session?'),
      content: const Text(
          'You can pause and save your current progress to resume later, or abandon the active session.'),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: onAbandon,
          child: const Text('Abandon'),
        ),
        FilledButton(
          onPressed: onPauseAndExit,
          child: const Text('Pause & Save'),
        ),
      ],
    );
  }
}
