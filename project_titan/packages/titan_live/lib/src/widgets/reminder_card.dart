import 'package:flutter/material.dart';
import '../models/live_models.dart';

/// Card displaying session reminder details.
class ReminderCard extends StatelessWidget {
  final SessionReminder reminder;
  final VoidCallback? onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: ListTile(
        leading: Icon(
          Icons.notifications_active,
          color: reminder.isTriggered
              ? theme.colorScheme.outline
              : theme.colorScheme.primary,
        ),
        title: Text(reminder.message, style: theme.textTheme.titleSmall),
        subtitle: Text(
          'Reminder at: ${reminder.reminderTime.hour}:${reminder.reminderTime.minute.toString().padLeft(2, '0')}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
