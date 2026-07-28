import 'package:flutter/material.dart';
import '../models/live_models.dart';

/// Responsive Grid displaying participants in a live session.
class ParticipantGrid extends StatelessWidget {
  final List<Participant> participants;

  const ParticipantGrid({
    super.key,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (participants.isEmpty) {
      return Center(
        child: Text(
          'No participants connected.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final p = participants[index];
        return Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: Text(p.name.isNotEmpty ? p.name[0] : '?'),
                  ),
                  if (p.isHandRaised)
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: Text('✋', style: TextStyle(fontSize: 14)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                p.name,
                style: theme.textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
