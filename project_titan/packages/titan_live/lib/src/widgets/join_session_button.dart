import 'package:flutter/material.dart';
import '../models/live_models.dart';

/// Interactive Join Session Button with live status indicator.
class JoinSessionButton extends StatelessWidget {
  final LiveSessionStatus status;
  final VoidCallback? onPressed;

  const JoinSessionButton({
    super.key,
    required this.status,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = status == LiveSessionStatus.live;

    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: isLive ? Colors.red : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: Icon(isLive ? Icons.videocam : Icons.meeting_room),
      label: Text(
        isLive
            ? 'JOIN LIVE CLASS'
            : status == LiveSessionStatus.waitingRoomOpen
                ? 'ENTER WAITING ROOM'
                : 'JOIN SESSION',
      ),
    );
  }
}
