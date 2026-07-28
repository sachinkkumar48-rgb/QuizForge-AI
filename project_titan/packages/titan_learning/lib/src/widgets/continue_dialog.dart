import 'package:flutter/material.dart';

/// Dialog prompting the learner to transition to the next chapter or assessment.
class ContinueDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  const ContinueDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onContinue,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: onContinue,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
