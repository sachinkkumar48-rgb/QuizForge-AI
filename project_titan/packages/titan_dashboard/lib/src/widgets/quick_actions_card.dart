import 'package:flutter/material.dart';

/// Section 12: Quick Actions Card.
/// Displays quick action buttons for:
/// - Continue Learning
/// - Ask Tutor
/// - Take Assessment
/// - Revise
/// - Planner
/// - Search
class QuickActionsCard extends StatelessWidget {
  final Function(String actionRoute)? onActionSelected;

  const QuickActionsCard({
    super.key,
    this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final actions = [
      _QuickActionItem(
        label: 'Continue Learning',
        icon: Icons.play_circle_fill_rounded,
        color: colorScheme.primary,
        route: '/learning',
      ),
      _QuickActionItem(
        label: 'Ask Tutor',
        icon: Icons.auto_awesome_rounded,
        color: colorScheme.tertiary,
        route: '/tutor',
      ),
      _QuickActionItem(
        label: 'Take Assessment',
        icon: Icons.quiz_rounded,
        color: colorScheme.secondary,
        route: '/assessment',
      ),
      const _QuickActionItem(
        label: 'Revise',
        icon: Icons.published_with_changes_rounded,
        color: Colors.orange,
        route: '/revision',
      ),
      const _QuickActionItem(
        label: 'Planner',
        icon: Icons.calendar_month_rounded,
        color: Colors.teal,
        route: '/planner',
      ),
      const _QuickActionItem(
        label: 'Search',
        icon: Icons.search_rounded,
        color: Colors.indigo,
        route: '/search',
      ),
    ];

    return Semantics(
      label: 'Quick Actions Navigation Card',
      container: true,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUICK ACTIONS',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.4,
                ),
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return InkWell(
                    onTap: () => onActionSelected?.call(action.route),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: action.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: action.color.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(action.icon, color: action.color, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            action.label,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });
}
