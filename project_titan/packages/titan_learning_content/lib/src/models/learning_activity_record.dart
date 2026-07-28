import 'package:meta/meta.dart';
import 'learning_activity.dart';

/// Immutable aggregate record summarizing learning activities performed on content.
@immutable
class LearningActivityRecord {
  final String userId;
  final String contentId;
  final List<LearningActivity> activities;
  final int totalDurationSeconds;
  final int activityCount;
  final DateTime lastActivityAt;
  final Map<String, int> activityBreakdown;

  LearningActivityRecord({
    required this.userId,
    required this.contentId,
    required List<LearningActivity> activities,
    required this.totalDurationSeconds,
    required this.activityCount,
    required this.lastActivityAt,
    required Map<String, int> activityBreakdown,
  })  : activities = List<LearningActivity>.unmodifiable(activities),
        activityBreakdown = Map<String, int>.unmodifiable(activityBreakdown);

  LearningActivityRecord copyWith({
    String? userId,
    String? contentId,
    List<LearningActivity>? activities,
    int? totalDurationSeconds,
    int? activityCount,
    DateTime? lastActivityAt,
    Map<String, int>? activityBreakdown,
  }) {
    return LearningActivityRecord(
      userId: userId ?? this.userId,
      contentId: contentId ?? this.contentId,
      activities: activities ?? this.activities,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      activityCount: activityCount ?? this.activityCount,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      activityBreakdown: activityBreakdown ?? this.activityBreakdown,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'contentId': contentId,
        'activities': activities.map((a) => a.toJson()).toList(),
        'totalDurationSeconds': totalDurationSeconds,
        'activityCount': activityCount,
        'lastActivityAt': lastActivityAt.toIso8601String(),
        'activityBreakdown': activityBreakdown,
      };

  factory LearningActivityRecord.fromJson(Map<String, dynamic> json) =>
      LearningActivityRecord(
        userId: json['userId'] as String,
        contentId: json['contentId'] as String,
        activities: (json['activities'] as List? ?? [])
            .map((a) =>
                LearningActivity.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList(),
        totalDurationSeconds: json['totalDurationSeconds'] as int? ?? 0,
        activityCount: json['activityCount'] as int? ?? 0,
        lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
        activityBreakdown: (json['activityBreakdown'] as Map? ?? {})
            .map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningActivityRecord &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          contentId == other.contentId &&
          totalDurationSeconds == other.totalDurationSeconds &&
          activityCount == other.activityCount &&
          lastActivityAt == other.lastActivityAt &&
          _listEquals(activities, other.activities);

  @override
  int get hashCode => Object.hash(
        userId,
        contentId,
        totalDurationSeconds,
        activityCount,
        lastActivityAt,
        Object.hashAll(activities),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
