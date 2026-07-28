import 'package:meta/meta.dart';
import 'skill_gap.dart';
import 'topic_statistics.dart';

/// Immutable domain model representing in-depth performance analysis for an assessment attempt.
@immutable
class AssessmentAnalysis {
  final String id;
  final String assessmentId;
  final double readinessScore; // 0.0 to 100.0
  final String
      examPrediction; // e.g. High Probability, Moderate, Needs Practice
  final double overallAccuracyPercentage;
  final List<TopicStatistics> topicStats;
  final List<SkillGap> skillGaps;
  final double speedQuestionsPerMinute;

  const AssessmentAnalysis({
    required this.id,
    required this.assessmentId,
    this.readinessScore = 0.0,
    this.examPrediction = 'Moderate',
    this.overallAccuracyPercentage = 0.0,
    this.topicStats = const [],
    this.skillGaps = const [],
    this.speedQuestionsPerMinute = 1.0,
  });

  AssessmentAnalysis copyWith({
    String? id,
    String? assessmentId,
    double? readinessScore,
    String? examPrediction,
    double? overallAccuracyPercentage,
    List<TopicStatistics>? topicStats,
    List<SkillGap>? skillGaps,
    double? speedQuestionsPerMinute,
  }) {
    return AssessmentAnalysis(
      id: id ?? this.id,
      assessmentId: assessmentId ?? this.assessmentId,
      readinessScore: readinessScore ?? this.readinessScore,
      examPrediction: examPrediction ?? this.examPrediction,
      overallAccuracyPercentage:
          overallAccuracyPercentage ?? this.overallAccuracyPercentage,
      topicStats: topicStats ?? this.topicStats,
      skillGaps: skillGaps ?? this.skillGaps,
      speedQuestionsPerMinute:
          speedQuestionsPerMinute ?? this.speedQuestionsPerMinute,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assessmentId': assessmentId,
        'readinessScore': readinessScore,
        'examPrediction': examPrediction,
        'overallAccuracyPercentage': overallAccuracyPercentage,
        'topicStats': topicStats.map((t) => t.toJson()).toList(),
        'skillGaps': skillGaps.map((s) => s.toJson()).toList(),
        'speedQuestionsPerMinute': speedQuestionsPerMinute,
      };

  factory AssessmentAnalysis.fromJson(Map<String, dynamic> json) =>
      AssessmentAnalysis(
        id: json['id'] as String,
        assessmentId: json['assessmentId'] as String,
        readinessScore: (json['readinessScore'] as num? ?? 0.0).toDouble(),
        examPrediction: json['examPrediction'] as String? ?? 'Moderate',
        overallAccuracyPercentage:
            (json['overallAccuracyPercentage'] as num? ?? 0.0).toDouble(),
        topicStats: (json['topicStats'] as List? ?? [])
            .map((e) => TopicStatistics.fromJson(e as Map<String, dynamic>))
            .toList(),
        skillGaps: (json['skillGaps'] as List? ?? [])
            .map((e) => SkillGap.fromJson(e as Map<String, dynamic>))
            .toList(),
        speedQuestionsPerMinute:
            (json['speedQuestionsPerMinute'] as num? ?? 1.0).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentAnalysis &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          assessmentId == other.assessmentId &&
          readinessScore == other.readinessScore;

  @override
  int get hashCode => Object.hash(id, assessmentId, readinessScore);
}
