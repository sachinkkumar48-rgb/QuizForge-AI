import 'package:flutter/material.dart';
import '../models/live_models.dart';

/// Material 3 Live Stream Video Player widget placeholder & container.
class LivePlayer extends StatelessWidget {
  final LiveSession session;
  final VoidCallback? onPlayPause;

  const LivePlayer({
    super.key,
    required this.session,
    this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                session.status == LiveSessionStatus.live
                    ? Icons.live_tv
                    : Icons.play_circle_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                session.status == LiveSessionStatus.live
                    ? 'LIVE CLASS IN PROGRESS'
                    : 'Stream Ready',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: session.status == LiveSessionStatus.live
                    ? Colors.red
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record,
                      size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    session.status == LiveSessionStatus.live
                        ? 'LIVE'
                        : 'OFFLINE',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
