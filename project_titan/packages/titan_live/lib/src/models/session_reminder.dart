import 'package:meta/meta.dart';

/// Immutable domain model representing a reminder for an upcoming live class.
@immutable
class SessionReminder {
  final String id;
  final String sessionId;
  final String userId;
  final DateTime reminderTime;
  final String message;
  final bool isTriggered;

  const SessionReminder({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.reminderTime,
    required this.message,
    this.isTriggered = false,
  });

  SessionReminder copyWith({
    String? id,
    String? sessionId,
    String? userId,
    DateTime? reminderTime,
    String? message,
    bool? isTriggered,
  }) {
    return SessionReminder(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      reminderTime: reminderTime ?? this.reminderTime,
      message: message ?? this.message,
      isTriggered: isTriggered ?? this.isTriggered,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'userId': userId,
        'reminderTime': reminderTime.toIso8601String(),
        'message': message,
        'isTriggered': isTriggered,
      };

  factory SessionReminder.fromJson(Map<String, dynamic> json) =>
      SessionReminder(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        userId: json['userId'] as String,
        reminderTime: DateTime.parse(json['reminderTime'] as String),
        message: json['message'] as String,
        isTriggered: json['isTriggered'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionReminder &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          userId == other.userId &&
          isTriggered == other.isTriggered;

  @override
  int get hashCode => Object.hash(id, sessionId, userId, isTriggered);
}
