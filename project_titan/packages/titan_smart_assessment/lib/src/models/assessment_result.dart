import 'package:meta/meta.dart';
import 'assessment_analysis.dart';
import 'assessment_feedback.dart';
import 'assessment_recommendation.dart';
import 'enums.dart';

/// Immutable domain model representing overall result of an assessment.
@immutable
class AssessmentResult {
  final String id;
  final String assessmentId;
  final String userId;
  final double score;
  final double totalPossibleScore;
  final double percentage;
  final GradeLevel gradeLevel;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final int durationSeconds;
  final DateTime completedAt;
  final AssessmentAnalysis? analysis;
  final AssessmentFeedback? feedback;
  final List<AssessmentRecommendation> recommendations;

  const AssessmentResult({
    required this.id,
    required this.assessmentId,
    required this.userId,
    required this.score,
    this.totalPossibleScore = 100.0,
    required this.percentage,
    this.gradeLevel = GradeLevel.proficient,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.skippedCount = 0,
    this.durationSeconds = 0,
    required this.completedAt,
    this.analysis,
    this.feedback,
    this.recommendations = const [],
  });

  AssessmentResult copyWith({
    String? id,
    String? assessmentId,
    String? userId,
    double? score,
    double? totalPossibleScore,
    double? percentage,
    GradeLevel? gradeLevel,
    int? correctCount,
    int? wrongCount,
    int? skippedCount,
    int? durationSeconds,
    DateTime? completedAt,
    AssessmentAnalysis? analysis,
    AssessmentFeedback? feedback,
    List<AssessmentRecommendation>? recommendations,
  }) {
    return AssessmentResult(
      id: id ?? this.id,
      assessmentId: assessmentId ?? this.assessmentId,
      userId: userId ?? this.userId,
      score: score ?? this.score,
      totalPossibleScore: totalPossibleScore ?? this.totalPossibleScore,
      percentage: percentage ?? this.percentage,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      skippedCount: skippedCount ?? this.skippedCount,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completedAt: completedAt ?? this.completedAt,
      analysis: analysis ?? this.analysis,
      feedback: feedback ?? this.feedback,
      recommendations: recommendations ?? this.recommendations,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assessmentId': assessmentId,
        'userId': userId,
        'score': score,
        'totalPossibleScore': totalPossibleScore,
        'percentage': percentage,
        'gradeLevel': gradeLevel.name,
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'skippedCount': skippedCount,
        'durationSeconds': durationSeconds,
        'completedAt': completedAt.toIso8601String(),
        'analysis': analysis?.toJson(),
        'feedback': feedback?.toJson(),
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
      };

  factory AssessmentResult.fromJson(Map<String, dynamic> json) =>
      AssessmentResult(
        id: json['id'] as String,
        assessmentId: json['assessmentId'] as String,
        userId: json['userId'] as String,
        score: (json['score'] as num? ?? 0.0).toDouble(),
        totalPossibleScore:
            (json['totalPossibleScore'] as num? ?? 100.0).toDouble(),
        percentage: (json['percentage'] as num? ?? 0.0).toDouble(),
        gradeLevel: GradeLevel.values.firstWhere(
          (e) => e.name == json['gradeLevel'],
          orElse: () => GradeLevel.proficient,
        ),
        correctCount: json['correctCount'] as int? ?? 0,
        wrongCount: json['wrongCount'] as int? ?? 0,
        skippedCount: json['skippedCount'] as int? ?? 0,
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        completedAt: DateTime.parse(json['completedAt'] as String),
        analysis: json['analysis'] != null
            ? AssessmentAnalysis.fromJson(
                json['analysis'] as Map<String, dynamic>)
            : null,
        feedback: json['feedback'] != null
            ? AssessmentFeedback.fromJson(
                json['feedback'] as Map<String, dynamic>)
            : null,
        recommendations: (json['recommendations'] as List? ?? [])
            .map((e) =>
                AssessmentRecommendation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          assessmentId == other.assessmentId &&
          score == other.score;

  @override
  int get hashCode => Object.hash(id, assessmentId, score);
}
