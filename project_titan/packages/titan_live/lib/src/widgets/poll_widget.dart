import 'package:flutter/material.dart';
import '../models/live_models.dart';

/// Interactive poll widget for live voting during class.
class PollWidget extends StatelessWidget {
  final Poll poll;
  final void Function(String optionId)? onVote;

  const PollWidget({
    super.key,
    required this.poll,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.poll, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('LIVE POLL', style: theme.textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              poll.question,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...poll.options.map((opt) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: OutlinedButton(
                  onPressed: onVote != null ? () => onVote!(opt.id) : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(opt.optionText),
                      Text('${opt.voteCount} votes'),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
