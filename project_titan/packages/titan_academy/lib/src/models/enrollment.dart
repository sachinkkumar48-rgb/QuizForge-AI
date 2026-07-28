import 'package:meta/meta.dart';
import 'learning_progress.dart';

/// Immutable domain model representing a student's enrollment in a course.
@immutable
class Enrollment {
  final String id;
  final String userId;
  final String courseId;
  final DateTime enrolledAt;
  final LearningProgress progress;
  final String status; // 'active', 'completed', 'paused'

  const Enrollment({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.enrolledAt,
    required this.progress,
    this.status = 'active',
  });

  Enrollment copyWith({
    String? id,
    String? userId,
    String? courseId,
    DateTime? enrolledAt,
    LearningProgress? progress,
    String? status,
  }) {
    return Enrollment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      progress: progress ?? this.progress,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Enrollment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          courseId == other.courseId &&
          enrolledAt == other.enrolledAt &&
          progress == other.progress &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        courseId,
        enrolledAt,
        progress,
        status,
      );
}
