import 'package:flutter/material.dart';

/// Material 3 typing indicator widget shown while AI Mentor generates a response.
class MentorTypingIndicator extends StatelessWidget {
  final bool isThinking;

  const MentorTypingIndicator({
    super.key,
    this.isThinking = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isThinking) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14.0,
            backgroundColor: colorScheme.primary,
            child:
                Icon(Icons.smart_toy, size: 16.0, color: colorScheme.onPrimary),
          ),
          const SizedBox(width: 8.0),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12.0,
                  height: 12.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  'TITAN Mentor is thinking...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
