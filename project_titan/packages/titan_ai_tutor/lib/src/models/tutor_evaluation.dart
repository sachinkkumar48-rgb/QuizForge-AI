import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain model representing an evaluation performed by the AI Tutor.
@immutable
class TutorEvaluation {
  final String id;
  final String targetId; // Session ID or Exercise ID
  final double score; // 0.0 to 100.0
  final EvaluationGrade grade;
  final String feedbackText;
  final List<String> masteredConcepts;
  final List<String> weakAreas;
  final List<String> detectedMisconceptions;
  final List<String> recommendations;
  final DateTime evaluatedAt;

  const TutorEvaluation({
    required this.id,
    required this.targetId,
    required this.score,
    required this.grade,
    required this.feedbackText,
    this.masteredConcepts = const [],
    this.weakAreas = const [],
    this.detectedMisconceptions = const [],
    this.recommendations = const [],
    required this.evaluatedAt,
  });

  TutorEvaluation copyWith({
    String? id,
    String? targetId,
    double? score,
    EvaluationGrade? grade,
    String? feedbackText,
    List<String>? masteredConcepts,
    List<String>? weakAreas,
    List<String>? detectedMisconceptions,
    List<String>? recommendations,
    DateTime? evaluatedAt,
  }) {
    return TutorEvaluation(
      id: id ?? this.id,
      targetId: targetId ?? this.targetId,
      score: score ?? this.score,
      grade: grade ?? this.grade,
      feedbackText: feedbackText ?? this.feedbackText,
      masteredConcepts: masteredConcepts ?? this.masteredConcepts,
      weakAreas: weakAreas ?? this.weakAreas,
      detectedMisconceptions:
          detectedMisconceptions ?? this.detectedMisconceptions,
      recommendations: recommendations ?? this.recommendations,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetId': targetId,
        'score': score,
        'grade': grade.name,
        'feedbackText': feedbackText,
        'masteredConcepts': masteredConcepts,
        'weakAreas': weakAreas,
        'detectedMisconceptions': detectedMisconceptions,
        'recommendations': recommendations,
        'evaluatedAt': evaluatedAt.toIso8601String(),
      };

  factory TutorEvaluation.fromJson(Map<String, dynamic> json) =>
      TutorEvaluation(
        id: json['id'] as String,
        targetId: json['targetId'] as String,
        score: (json['score'] as num? ?? 0.0).toDouble(),
        grade: EvaluationGrade.values.firstWhere(
          (e) => e.name == json['grade'],
          orElse: () => EvaluationGrade.satisfactory,
        ),
        feedbackText: json['feedbackText'] as String? ?? '',
        masteredConcepts:
            (json['masteredConcepts'] as List? ?? []).cast<String>(),
        weakAreas: (json['weakAreas'] as List? ?? []).cast<String>(),
        detectedMisconceptions:
            (json['detectedMisconceptions'] as List? ?? []).cast<String>(),
        recommendations:
            (json['recommendations'] as List? ?? []).cast<String>(),
        evaluatedAt: DateTime.parse(json['evaluatedAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorEvaluation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          targetId == other.targetId &&
          score == other.score;

  @override
  int get hashCode => Object.hash(id, targetId, score);
}
