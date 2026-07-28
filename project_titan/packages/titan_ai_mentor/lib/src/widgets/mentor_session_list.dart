import 'package:flutter/material.dart';

import '../models/mentor_session.dart';

/// Material 3 list view displaying historical AI Mentor chat sessions.
class MentorSessionList extends StatelessWidget {
  final List<MentorSession> sessions;
  final ValueChanged<MentorSession> onSessionSelected;
  final ValueChanged<String>? onDeleteSession;

  const MentorSessionList({
    super.key,
    required this.sessions,
    required this.onSessionSelected,
    this.onDeleteSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No previous mentor sessions.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const Divider(height: 1.0),
      itemBuilder: (context, index) {
        final session = sessions[index];
        return ListTile(
          leading: const Icon(Icons.chat_bubble_outline_rounded),
          title: Text(
            session.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: session.summary != null
              ? Text(
                  session.summary!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Text('${session.messages.length} messages'),
          trailing: onDeleteSession != null
              ? IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20.0),
                  onPressed: () => onDeleteSession!(session.id),
                )
              : null,
          onTap: () => onSessionSelected(session),
        );
      },
    );
  }
}
