import 'package:flutter/material.dart';
import '../models/live_models.dart';

/// Card summarizing student attendance & engagement metrics.
class AttendanceCard extends StatelessWidget {
  final Attendance attendance;

  const AttendanceCard({
    super.key,
    required this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
              attendance.userName.isNotEmpty ? attendance.userName[0] : 'U'),
        ),
        title: Text(attendance.userName),
        subtitle: Text('Status: ${attendance.status.name.toUpperCase()}'),
        trailing: Text(
          '${attendance.watchDurationMinutes} mins watched',
          style: theme.textTheme.labelMedium,
        ),
      ),
    );
  }
}
