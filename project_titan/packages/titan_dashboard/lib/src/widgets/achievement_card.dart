import 'package:flutter/material.dart';

import '../orchestrator/unified_dashboard_state.dart';

/// Section 11: Achievements Card.
/// Displays badges, milestones, and certificates earned. Reuses titan_learning_journey.
class AchievementCard extends StatelessWidget {
  final AchievementsData data;
  final VoidCallback? onAchievementsTap;

  const AchievementCard({
    super.key,
    required this.data,
    this.onAchievementsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Learner Achievements & Badges Card',
      container: true,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.military_tech_rounded,
                            color: colorScheme.tertiary, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'ACHIEVEMENTS',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.tertiary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onAchievementsTap,
                    child: Text('View All (${data.totalBadges})'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: data.badges.map((badge) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        avatar: const Icon(Icons.stars_rounded, size: 16),
                        label: Text(badge),
                        backgroundColor: colorScheme.tertiaryContainer
                            .withValues(alpha: 0.5),
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.workspace_premium_rounded,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${data.certificateCount} Verified Certificates Earned',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
