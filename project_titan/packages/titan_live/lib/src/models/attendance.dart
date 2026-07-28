import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain model representing attendance of a student in a live session.
@immutable
class Attendance {
  final String id;
  final String sessionId;
  final String userId;
  final String userName;
  final AttendanceStatus status;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final int watchDurationMinutes;

  const Attendance({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.userName,
    this.status = AttendanceStatus.present,
    required this.joinedAt,
    this.leftAt,
    this.watchDurationMinutes = 0,
  });

  Attendance copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? userName,
    AttendanceStatus? status,
    DateTime? joinedAt,
    DateTime? leftAt,
    int? watchDurationMinutes,
  }) {
    return Attendance(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      watchDurationMinutes: watchDurationMinutes ?? this.watchDurationMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'userId': userId,
        'userName': userName,
        'status': status.name,
        'joinedAt': joinedAt.toIso8601String(),
        'leftAt': leftAt?.toIso8601String(),
        'watchDurationMinutes': watchDurationMinutes,
      };

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        status: AttendanceStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => AttendanceStatus.present,
        ),
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        leftAt: json['leftAt'] != null
            ? DateTime.parse(json['leftAt'] as String)
            : null,
        watchDurationMinutes: json['watchDurationMinutes'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Attendance &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          userId == other.userId &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, sessionId, userId, status);
}
