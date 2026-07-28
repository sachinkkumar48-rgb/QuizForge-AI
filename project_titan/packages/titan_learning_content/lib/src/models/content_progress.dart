import 'package:meta/meta.dart';

/// Immutable domain model representing progress state for a specific learning content item.
@immutable
class ContentProgress {
  final String contentId;
  final String userId;
  final int lastPositionSeconds;
  final double completionPercentage;
  final int timeSpentSeconds;
  final DateTime lastAccessedAt;
  final bool isCompleted;

  const ContentProgress({
    required this.contentId,
    required this.userId,
    this.lastPositionSeconds = 0,
    required this.completionPercentage,
    required this.timeSpentSeconds,
    required this.lastAccessedAt,
    this.isCompleted = false,
  });

  ContentProgress copyWith({
    String? contentId,
    String? userId,
    int? lastPositionSeconds,
    double? completionPercentage,
    int? timeSpentSeconds,
    DateTime? lastAccessedAt,
    bool? isCompleted,
  }) {
    return ContentProgress(
      contentId: contentId ?? this.contentId,
      userId: userId ?? this.userId,
      lastPositionSeconds: lastPositionSeconds ?? this.lastPositionSeconds,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'userId': userId,
        'lastPositionSeconds': lastPositionSeconds,
        'completionPercentage': completionPercentage,
        'timeSpentSeconds': timeSpentSeconds,
        'lastAccessedAt': lastAccessedAt.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory ContentProgress.fromJson(Map<String, dynamic> json) =>
      ContentProgress(
        contentId: json['contentId'] as String,
        userId: json['userId'] as String,
        lastPositionSeconds: json['lastPositionSeconds'] as int? ?? 0,
        completionPercentage:
            (json['completionPercentage'] as num? ?? 0.0).toDouble(),
        timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
        lastAccessedAt: DateTime.parse(json['lastAccessedAt'] as String),
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentProgress &&
          runtimeType == other.runtimeType &&
          contentId == other.contentId &&
          userId == other.userId &&
          lastPositionSeconds == other.lastPositionSeconds &&
          completionPercentage == other.completionPercentage &&
          timeSpentSeconds == other.timeSpentSeconds &&
          lastAccessedAt == other.lastAccessedAt &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(
        contentId,
        userId,
        lastPositionSeconds,
        completionPercentage,
        timeSpentSeconds,
        lastAccessedAt,
        isCompleted,
      );
}
