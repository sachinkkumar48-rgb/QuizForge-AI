import 'package:meta/meta.dart';

import '../value_objects/relationship_type.dart';

/// Immutable domain entity representing a directed relationship edge
/// between two Knowledge Objects in the TITAN Knowledge Intelligence Engine.
@immutable
class KnowledgeRelationship {
  /// Unique identifier of the relationship edge.
  final String relationshipId;

  /// Canonical ID of the origin/source knowledge entity.
  final String sourceKnowledgeId;

  /// Canonical ID of the destination/target knowledge entity.
  final String targetKnowledgeId;

  /// Directed semantic type of the relationship edge.
  final RelationshipType relationshipType;

  /// Confidence score of the relationship assertion (0.0 to 1.0).
  final double confidence;

  /// Arbitrary extensible key-value metadata payload.
  final Map<String, dynamic> metadata;

  /// Timestamp when the relationship was constructed.
  final DateTime createdAt;

  /// Constructs an immutable [KnowledgeRelationship].
  KnowledgeRelationship({
    required this.relationshipId,
    required this.sourceKnowledgeId,
    required this.targetKnowledgeId,
    required this.relationshipType,
    this.confidence = 1.0,
    Map<String, dynamic> metadata = const {},
    DateTime? createdAt,
  })  : assert(
            relationshipId.trim().isNotEmpty, 'relationshipId cannot be empty'),
        assert(sourceKnowledgeId.trim().isNotEmpty,
            'sourceKnowledgeId cannot be empty'),
        assert(targetKnowledgeId.trim().isNotEmpty,
            'targetKnowledgeId cannot be empty'),
        assert(
          sourceKnowledgeId != targetKnowledgeId,
          'Self-referential relationships are invalid (sourceKnowledgeId cannot equal targetKnowledgeId)',
        ),
        assert(
          confidence >= 0.0 && confidence <= 1.0,
          'confidence score must be between 0.0 and 1.0',
        ),
        metadata = Map<String, dynamic>.unmodifiable(metadata),
        createdAt = createdAt ?? DateTime.now();

  /// Creates a copy of this [KnowledgeRelationship] with modified fields.
  KnowledgeRelationship copyWith({
    String? relationshipId,
    String? sourceKnowledgeId,
    String? targetKnowledgeId,
    RelationshipType? relationshipType,
    double? confidence,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return KnowledgeRelationship(
      relationshipId: relationshipId ?? this.relationshipId,
      sourceKnowledgeId: sourceKnowledgeId ?? this.sourceKnowledgeId,
      targetKnowledgeId: targetKnowledgeId ?? this.targetKnowledgeId,
      relationshipType: relationshipType ?? this.relationshipType,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this [KnowledgeRelationship] into a JSON-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'relationshipId': relationshipId,
      'sourceKnowledgeId': sourceKnowledgeId,
      'targetKnowledgeId': targetKnowledgeId,
      'relationshipType': relationshipType.name,
      'confidence': confidence,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Deserializes a [KnowledgeRelationship] from a Map.
  factory KnowledgeRelationship.fromMap(Map<String, dynamic> map) {
    return KnowledgeRelationship(
      relationshipId: map['relationshipId'] as String,
      sourceKnowledgeId: map['sourceKnowledgeId'] as String,
      targetKnowledgeId: map['targetKnowledgeId'] as String,
      relationshipType: RelationshipType.values.firstWhere(
        (e) => e.name == map['relationshipType'],
        orElse: () => RelationshipType.relatedTo,
      ),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? const {}),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is KnowledgeRelationship &&
        other.relationshipId == relationshipId &&
        other.sourceKnowledgeId == sourceKnowledgeId &&
        other.targetKnowledgeId == targetKnowledgeId &&
        other.relationshipType == relationshipType &&
        other.confidence == confidence &&
        _mapEquals(other.metadata, metadata) &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      relationshipId,
      sourceKnowledgeId,
      targetKnowledgeId,
      relationshipType,
      confidence,
      Object.hashAll(metadata.keys),
      Object.hashAll(metadata.values),
      createdAt,
    );
  }

  @override
  String toString() {
    return 'KnowledgeRelationship($sourceKnowledgeId -[${relationshipType.name}]-> $targetKnowledgeId, confidence: $confidence)';
  }

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
