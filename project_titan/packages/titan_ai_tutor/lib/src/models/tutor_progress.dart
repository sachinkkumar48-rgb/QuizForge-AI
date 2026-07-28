import 'package:meta/meta.dart';

/// Immutable domain model representing progress and mastery metrics for a concept.
@immutable
class TutorProgress {
  final String conceptId;
  final double masteryLevel; // 0.0 to 100.0
  final double confidenceLevel; // 0.0 to 1.0
  final int exercisesAttempted;
  final int exercisesPassed;
  final int consecutiveSuccesses;
  final DateTime lastAttemptAt;

  const TutorProgress({
    required this.conceptId,
    this.masteryLevel = 0.0,
    this.confidenceLevel = 0.5,
    this.exercisesAttempted = 0,
    this.exercisesPassed = 0,
    this.consecutiveSuccesses = 0,
    required this.lastAttemptAt,
  });

  TutorProgress copyWith({
    String? conceptId,
    double? masteryLevel,
    double? confidenceLevel,
    int? exercisesAttempted,
    int? exercisesPassed,
    int? consecutiveSuccesses,
    DateTime? lastAttemptAt,
  }) {
    return TutorProgress(
      conceptId: conceptId ?? this.conceptId,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      exercisesAttempted: exercisesAttempted ?? this.exercisesAttempted,
      exercisesPassed: exercisesPassed ?? this.exercisesPassed,
      consecutiveSuccesses: consecutiveSuccesses ?? this.consecutiveSuccesses,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'conceptId': conceptId,
        'masteryLevel': masteryLevel,
        'confidenceLevel': confidenceLevel,
        'exercisesAttempted': exercisesAttempted,
        'exercisesPassed': exercisesPassed,
        'consecutiveSuccesses': consecutiveSuccesses,
        'lastAttemptAt': lastAttemptAt.toIso8601String(),
      };

  factory TutorProgress.fromJson(Map<String, dynamic> json) => TutorProgress(
        conceptId: json['conceptId'] as String,
        masteryLevel: (json['masteryLevel'] as num? ?? 0.0).toDouble(),
        confidenceLevel: (json['confidenceLevel'] as num? ?? 0.5).toDouble(),
        exercisesAttempted: json['exercisesAttempted'] as int? ?? 0,
        exercisesPassed: json['exercisesPassed'] as int? ?? 0,
        consecutiveSuccesses: json['consecutiveSuccesses'] as int? ?? 0,
        lastAttemptAt: DateTime.parse(json['lastAttemptAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorProgress &&
          runtimeType == other.runtimeType &&
          conceptId == other.conceptId &&
          masteryLevel == other.masteryLevel;

  @override
  int get hashCode => Object.hash(conceptId, masteryLevel);
}
