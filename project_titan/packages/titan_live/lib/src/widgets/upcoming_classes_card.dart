import 'package:flutter/material.dart';
import '../models/live_models.dart';
import 'live_class_card.dart';

/// Card container displaying a scrollable list of upcoming live classes.
class UpcomingClassesCard extends StatelessWidget {
  final List<LiveClass> upcomingClasses;
  final void Function(LiveClass)? onClassTap;

  const UpcomingClassesCard({
    super.key,
    required this.upcomingClasses,
    this.onClassTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (upcomingClasses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No upcoming live classes scheduled.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Upcoming Live Classes',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...upcomingClasses.map(
          (c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: LiveClassCard(
              liveClass: c,
              onTap: onClassTap != null ? () => onClassTap!(c) : null,
              onJoinTap: onClassTap != null ? () => onClassTap!(c) : null,
            ),
          ),
        ),
      ],
    );
  }
}
