import 'package:meta/meta.dart';
import '../concepts/confidence_score.dart';
import '../concepts/mapping_method.dart';

enum ReviewStatus {
  pending,
  approved,
  rejected,
  flagged,
}

@immutable
class QuestionConceptMapping {
  final String questionId;
  final String conceptId;
  final double confidenceScore;
  final MappingMethod mappingMethod;
  final ReviewStatus reviewStatus;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? remarks;

  const QuestionConceptMapping({
    required this.questionId,
    required this.conceptId,
    required this.confidenceScore,
    required this.mappingMethod,
    this.reviewStatus = ReviewStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
    this.remarks,
  });

  ConfidenceScore get scoreObject => ConfidenceScore(confidenceScore);
  ConfidenceCategory get confidenceCategory => scoreObject.category;

  bool get isAutoRejected => confidenceScore < 0.50;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'conceptId': conceptId,
        'confidenceScore': confidenceScore,
        'mappingMethod': mappingMethod.name,
        'reviewStatus': reviewStatus.name,
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt?.toIso8601String(),
        'remarks': remarks,
      };

  factory QuestionConceptMapping.fromJson(Map<String, dynamic> json) =>
      QuestionConceptMapping(
        questionId: json['questionId'] as String,
        conceptId: json['conceptId'] as String,
        confidenceScore: (json['confidenceScore'] as num).toDouble(),
        mappingMethod: MappingMethod.values.firstWhere(
          (e) => e.name == json['mappingMethod'],
          orElse: () => MappingMethod.manual,
        ),
        reviewStatus: ReviewStatus.values.firstWhere(
          (e) => e.name == json['reviewStatus'],
          orElse: () => ReviewStatus.pending,
        ),
        reviewedBy: json['reviewedBy'] as String?,
        reviewedAt: json['reviewedAt'] != null
            ? DateTime.parse(json['reviewedAt'] as String)
            : null,
        remarks: json['remarks'] as String?,
      );

  QuestionConceptMapping copyWith({
    String? questionId,
    String? conceptId,
    double? confidenceScore,
    MappingMethod? mappingMethod,
    ReviewStatus? reviewStatus,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? remarks,
  }) {
    return QuestionConceptMapping(
      questionId: questionId ?? this.questionId,
      conceptId: conceptId ?? this.conceptId,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      mappingMethod: mappingMethod ?? this.mappingMethod,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      remarks: remarks ?? this.remarks,
    );
  }
}
