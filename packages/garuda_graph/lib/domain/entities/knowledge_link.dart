library;

import 'package:meta/meta.dart';
import 'enums.dart';
import 'knowledge_node_ref.dart';

/// Immutable Directed Link representing a semantic relationship between two nodes in GARUDA Knowledge Graph.
@immutable
class KnowledgeLink {
  final String id;
  final KnowledgeNodeRef sourceObject;
  final KnowledgeNodeRef targetObject;
  final KnowledgeRelationshipType relationshipType;
  final double confidenceScore;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LinkStatus status;
  final List<String> evidenceReferences;
  final String reason;

  const KnowledgeLink({
    required this.id,
    required this.sourceObject,
    required this.targetObject,
    required this.relationshipType,
    required this.confidenceScore,
    this.createdBy = 'deterministic_rule_engine',
    required this.createdAt,
    required this.updatedAt,
    this.status = LinkStatus.linkReviewPending,
    this.evidenceReferences = const [],
    this.reason = 'Rule-based matching suggestion',
  });

  KnowledgeLink copyWith({
    String? id,
    KnowledgeNodeRef? sourceObject,
    KnowledgeNodeRef? targetObject,
    KnowledgeRelationshipType? relationshipType,
    double? confidenceScore,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    LinkStatus? status,
    List<String>? evidenceReferences,
    String? reason,
  }) {
    return KnowledgeLink(
      id: id ?? this.id,
      sourceObject: sourceObject ?? this.sourceObject,
      targetObject: targetObject ?? this.targetObject,
      relationshipType: relationshipType ?? this.relationshipType,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      evidenceReferences:
          evidenceReferences ?? List.from(this.evidenceReferences),
      reason: reason ?? this.reason,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceObject': sourceObject.toJson(),
        'targetObject': targetObject.toJson(),
        'relationshipType': relationshipType.name,
        'confidenceScore': confidenceScore,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'status': status.name,
        'evidenceReferences': evidenceReferences,
        'reason': reason,
      };

  factory KnowledgeLink.fromJson(Map<String, dynamic> json) => KnowledgeLink(
        id: json['id'] as String? ?? '',
        sourceObject: KnowledgeNodeRef.fromJson(
            Map<String, dynamic>.from(json['sourceObject'] as Map)),
        targetObject: KnowledgeNodeRef.fromJson(
            Map<String, dynamic>.from(json['targetObject'] as Map)),
        relationshipType: KnowledgeRelationshipType.values.firstWhere(
          (e) => e.name == json['relationshipType'],
          orElse: () => KnowledgeRelationshipType.relatedTo,
        ),
        confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.5,
        createdBy: json['createdBy'] as String? ?? 'deterministic_rule_engine',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        status: LinkStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => LinkStatus.linkReviewPending,
        ),
        evidenceReferences: (json['evidenceReferences'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        reason: json['reason'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KnowledgeLink &&
        other.id == id &&
        other.sourceObject == sourceObject &&
        other.targetObject == targetObject &&
        other.relationshipType == relationshipType;
  }

  @override
  int get hashCode =>
      Object.hash(id, sourceObject, targetObject, relationshipType);

  @override
  String toString() =>
      'KnowledgeLink(id: $id, ${sourceObject.id} -[${relationshipType.name}]-> ${targetObject.id}, status: ${status.name})';
}
