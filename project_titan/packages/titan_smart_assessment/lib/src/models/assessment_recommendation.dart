import 'package:meta/meta.dart';

/// Immutable domain model representing personalized recommendations generated post-assessment.
@immutable
class AssessmentRecommendation {
  final String id;
  final String assessmentId;
  final String title;
  final String description;
  final String actionType; // e.g. Revision, Practice, Video, Note
  final String targetConceptId;
  final double priorityScore; // 0.0 to 1.0

  const AssessmentRecommendation({
    required this.id,
    required this.assessmentId,
    required this.title,
    required this.description,
    this.actionType = 'Practice',
    required this.targetConceptId,
    this.priorityScore = 0.8,
  });

  AssessmentRecommendation copyWith({
    String? id,
    String? assessmentId,
    String? title,
    String? description,
    String? actionType,
    String? targetConceptId,
    double? priorityScore,
  }) {
    return AssessmentRecommendation(
      id: id ?? this.id,
      assessmentId: assessmentId ?? this.assessmentId,
      title: title ?? this.title,
      description: description ?? this.description,
      actionType: actionType ?? this.actionType,
      targetConceptId: targetConceptId ?? this.targetConceptId,
      priorityScore: priorityScore ?? this.priorityScore,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assessmentId': assessmentId,
        'title': title,
        'description': description,
        'actionType': actionType,
        'targetConceptId': targetConceptId,
        'priorityScore': priorityScore,
      };

  factory AssessmentRecommendation.fromJson(Map<String, dynamic> json) =>
      AssessmentRecommendation(
        id: json['id'] as String,
        assessmentId: json['assessmentId'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        actionType: json['actionType'] as String? ?? 'Practice',
        targetConceptId: json['targetConceptId'] as String? ?? '',
        priorityScore: (json['priorityScore'] as num? ?? 0.8).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentRecommendation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          assessmentId == other.assessmentId;

  @override
  int get hashCode => Object.hash(id, assessmentId);
}
