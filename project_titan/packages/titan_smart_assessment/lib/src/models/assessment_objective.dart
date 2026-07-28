import 'package:meta/meta.dart';

/// Immutable domain model representing an objective of an assessment.
@immutable
class AssessmentObjective {
  final String id;
  final String title;
  final String description;
  final double targetScorePercentage;
  final String topicId;

  const AssessmentObjective({
    required this.id,
    required this.title,
    required this.description,
    this.targetScorePercentage = 70.0,
    this.topicId = '',
  });

  AssessmentObjective copyWith({
    String? id,
    String? title,
    String? description,
    double? targetScorePercentage,
    String? topicId,
  }) {
    return AssessmentObjective(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetScorePercentage:
          targetScorePercentage ?? this.targetScorePercentage,
      topicId: topicId ?? this.topicId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'targetScorePercentage': targetScorePercentage,
        'topicId': topicId,
      };

  factory AssessmentObjective.fromJson(Map<String, dynamic> json) =>
      AssessmentObjective(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        targetScorePercentage:
            (json['targetScorePercentage'] as num? ?? 70.0).toDouble(),
        topicId: json['topicId'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentObjective &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => Object.hash(id, title);
}
