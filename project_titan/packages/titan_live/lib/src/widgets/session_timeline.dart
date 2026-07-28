import 'package:flutter/material.dart';
import '../models/live_models.dart';

/// Timeline widget visualizing session events (Start, Polls, Whiteboards, End).
class SessionTimeline extends StatelessWidget {
  final LiveSession session;

  const SessionTimeline({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        ListTile(
          leading: const Icon(Icons.start, color: Colors.green),
          title: const Text('Session Scheduled / Started'),
          subtitle: Text(session.actualStartTime != null
              ? session.actualStartTime!.toIso8601String()
              : 'Pending'),
        ),
        if (session.activePoll != null)
          ListTile(
            leading: const Icon(Icons.poll, color: Colors.blue),
            title: Text('Poll Launched: ${session.activePoll!.question}'),
            subtitle: Text('Status: ${session.activePoll!.status.name}'),
          ),
        ...session.whiteboardSnapshots.map(
          (wb) => ListTile(
            leading: const Icon(Icons.gesture, color: Colors.purple),
            title: Text('Whiteboard: ${wb.title}'),
            subtitle: Text('Captured by ${wb.capturedBy}'),
          ),
        ),
        if (session.status == LiveSessionStatus.ended)
          ListTile(
            leading: const Icon(Icons.stop_circle, color: Colors.red),
            title: const Text('Session Ended'),
            subtitle: Text(session.actualEndTime?.toIso8601String() ?? ''),
          ),
      ],
    );
  }
}
