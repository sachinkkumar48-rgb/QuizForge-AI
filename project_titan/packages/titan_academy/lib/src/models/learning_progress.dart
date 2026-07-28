import 'package:meta/meta.dart';

/// Immutable domain model tracking user's learning progress for a specific course.
@immutable
class LearningProgress {
  final String courseId;
  final String userId;
  final Set<String> completedLessonIds;
  final String? lastAccessedLessonId;
  final double overallProgressPercentage;
  final int timeSpentMinutes;
  final DateTime lastAccessedAt;
  final bool isCompleted;

  LearningProgress({
    required this.courseId,
    required this.userId,
    required Set<String> completedLessonIds,
    this.lastAccessedLessonId,
    required this.overallProgressPercentage,
    required this.timeSpentMinutes,
    required this.lastAccessedAt,
    this.isCompleted = false,
  }) : completedLessonIds = Set<String>.unmodifiable(completedLessonIds);

  LearningProgress copyWith({
    String? courseId,
    String? userId,
    Set<String>? completedLessonIds,
    String? lastAccessedLessonId,
    double? overallProgressPercentage,
    int? timeSpentMinutes,
    DateTime? lastAccessedAt,
    bool? isCompleted,
  }) {
    return LearningProgress(
      courseId: courseId ?? this.courseId,
      userId: userId ?? this.userId,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      lastAccessedLessonId: lastAccessedLessonId ?? this.lastAccessedLessonId,
      overallProgressPercentage:
          overallProgressPercentage ?? this.overallProgressPercentage,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningProgress &&
          runtimeType == other.runtimeType &&
          courseId == other.courseId &&
          userId == other.userId &&
          lastAccessedLessonId == other.lastAccessedLessonId &&
          overallProgressPercentage == other.overallProgressPercentage &&
          timeSpentMinutes == other.timeSpentMinutes &&
          lastAccessedAt == other.lastAccessedAt &&
          isCompleted == other.isCompleted &&
          _setEquals(completedLessonIds, other.completedLessonIds);

  @override
  int get hashCode => Object.hash(
        courseId,
        userId,
        lastAccessedLessonId,
        overallProgressPercentage,
        timeSpentMinutes,
        lastAccessedAt,
        isCompleted,
        Object.hashAll(completedLessonIds),
      );
}

bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (a.length != b.length) return false;
  return a.containsAll(b);
}
