import 'package:meta/meta.dart';

/// Immutable entity referencing evidence assets from garuda_evidence without duplicating data.
@immutable
class KnowledgeEvidenceReference {
  final String evidenceId;
  final String evidenceType;
  final double confidenceScore;
  final String? verifiedBy;
  final DateTime? verifiedAt;

  const KnowledgeEvidenceReference({
    required this.evidenceId,
    required this.evidenceType,
    this.confidenceScore = 1.0,
    this.verifiedBy,
    this.verifiedAt,
  });

  Map<String, dynamic> toJson() => {
        'evidenceId': evidenceId,
        'evidenceType': evidenceType,
        'confidenceScore': confidenceScore,
        'verifiedBy': verifiedBy,
        'verifiedAt': verifiedAt?.toIso8601String(),
      };

  factory KnowledgeEvidenceReference.fromJson(Map<String, dynamic> json) {
    return KnowledgeEvidenceReference(
      evidenceId: json['evidenceId'] as String? ?? '',
      evidenceType: json['evidenceType'] as String? ?? 'General',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 1.0,
      verifiedBy: json['verifiedBy'] as String?,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeEvidenceReference &&
          runtimeType == other.runtimeType &&
          evidenceId == other.evidenceId;

  @override
  int get hashCode => evidenceId.hashCode;
}
