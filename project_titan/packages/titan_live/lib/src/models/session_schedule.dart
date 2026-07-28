import 'package:meta/meta.dart';

/// Immutable domain model representing a live class schedule entry.
@immutable
class SessionSchedule {
  final String id;
  final String liveClassId;
  final DateTime scheduledStartTime;
  final DateTime scheduledEndTime;
  final String timeZone;
  final String? recurrencePattern;

  const SessionSchedule({
    required this.id,
    required this.liveClassId,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    this.timeZone = 'IST',
    this.recurrencePattern,
  });

  bool get isUpcoming => DateTime.now().isBefore(scheduledStartTime);
  bool get isInProgress =>
      DateTime.now().isAfter(scheduledStartTime) &&
      DateTime.now().isBefore(scheduledEndTime);

  SessionSchedule copyWith({
    String? id,
    String? liveClassId,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    String? timeZone,
    String? recurrencePattern,
  }) {
    return SessionSchedule(
      id: id ?? this.id,
      liveClassId: liveClassId ?? this.liveClassId,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      timeZone: timeZone ?? this.timeZone,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'liveClassId': liveClassId,
        'scheduledStartTime': scheduledStartTime.toIso8601String(),
        'scheduledEndTime': scheduledEndTime.toIso8601String(),
        'timeZone': timeZone,
        'recurrencePattern': recurrencePattern,
      };

  factory SessionSchedule.fromJson(Map<String, dynamic> json) =>
      SessionSchedule(
        id: json['id'] as String,
        liveClassId: json['liveClassId'] as String,
        scheduledStartTime:
            DateTime.parse(json['scheduledStartTime'] as String),
        scheduledEndTime: DateTime.parse(json['scheduledEndTime'] as String),
        timeZone: json['timeZone'] as String? ?? 'IST',
        recurrencePattern: json['recurrencePattern'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionSchedule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          liveClassId == other.liveClassId &&
          scheduledStartTime == other.scheduledStartTime &&
          scheduledEndTime == other.scheduledEndTime;

  @override
  int get hashCode =>
      Object.hash(id, liveClassId, scheduledStartTime, scheduledEndTime);
}
