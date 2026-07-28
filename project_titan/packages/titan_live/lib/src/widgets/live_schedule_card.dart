import 'package:flutter/material.dart';
import '../models/live_models.dart';

/// Material 3 Card displaying schedule details for upcoming live classes.
class LiveScheduleCard extends StatelessWidget {
  final SessionSchedule schedule;
  final String title;
  final String instructorName;
  final VoidCallback? onReminderTap;

  const LiveScheduleCard({
    super.key,
    required this.schedule,
    required this.title,
    required this.instructorName,
    this.onReminderTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startTimeStr =
        '${schedule.scheduledStartTime.hour}:${schedule.scheduledStartTime.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${schedule.scheduledStartTime.day}/${schedule.scheduledStartTime.month}/${schedule.scheduledStartTime.year}';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.calendar_today,
              color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$instructorName • $dateStr @ $startTimeStr ${schedule.timeZone}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.notifications_active_outlined),
          onPressed: onReminderTap,
          tooltip: 'Set Reminder',
        ),
      ),
    );
  }
}
