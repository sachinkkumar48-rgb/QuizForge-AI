import 'package:flutter/material.dart';
import '../models/tutor_models.dart';

/// Responsive Material 3 view for interactive AI Tutor session chat.
class TutorChatView extends StatefulWidget {
  final TutorSession session;
  final void Function(String message)? onSendMessage;
  final void Function(TutorPersona persona)? onPersonaChanged;

  const TutorChatView({
    super.key,
    required this.session,
    this.onSendMessage,
    this.onPersonaChanged,
  });

  @override
  State<TutorChatView> createState() => _TutorChatViewState();
}

class _TutorChatViewState extends State<TutorChatView> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSubmitted() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage?.call(text);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    final padding = isDesktop ? 24.0 : 16.0;

    return Column(
      children: [
        // Mode & Status Bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(Icons.school, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'AI Tutor Mode:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<TutorPersona>(
                initialValue: widget.session.persona,
                onSelected: widget.onPersonaChanged,
                child: Chip(
                  avatar: const Icon(Icons.psychology, size: 18),
                  label: Text(widget.session.persona.displayName),
                ),
                itemBuilder: (context) => TutorPersona.values
                    .map((p) => PopupMenuItem(
                          value: p,
                          child: Text(p.displayName),
                        ))
                    .toList(),
              ),
              const Spacer(),
              Chip(
                backgroundColor: theme.colorScheme.secondaryContainer,
                label: Text(
                  widget.session.status.name.toUpperCase(),
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),

        // Session Exercises & Interaction Feed
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(padding),
            itemCount: widget.session.exercises.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tutoring Session Concept: ${widget.session.conceptId}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Started at: ${widget.session.startedAt.toLocal()}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }
              final exercise = widget.session.exercises[index - 1];
              return Card(
                key: Key('exercise_${exercise.id}'),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(exercise.title),
                  subtitle: Text(exercise.prompt),
                  trailing: Icon(
                    exercise.status == TutorExerciseStatus.completed
                        ? Icons.check_circle
                        : Icons.pending,
                    color: exercise.status == TutorExerciseStatus.completed
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              );
            },
          ),
        ),

        // Input Controls
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Ask AI Tutor or provide your answer...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _handleSubmitted(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.send),
                onPressed: _handleSubmitted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
