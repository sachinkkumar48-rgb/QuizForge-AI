import 'package:flutter/material.dart';
import '../models/tutor_models.dart';

/// Responsive Material 3 card presenting practice exercises.
class TutorExerciseCard extends StatefulWidget {
  final TutorExercise exercise;
  final void Function(String response)? onSubmit;
  final VoidCallback? onRequestHint;

  const TutorExerciseCard({
    super.key,
    required this.exercise,
    this.onSubmit,
    this.onRequestHint,
  });

  @override
  State<TutorExerciseCard> createState() => _TutorExerciseCardState();
}

class _TutorExerciseCardState extends State<TutorExerciseCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.exercise.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(widget.exercise.status.name),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.exercise.prompt,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Type your explanation or response...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.onRequestHint,
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Hint'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      widget.onSubmit?.call(text);
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Answer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
