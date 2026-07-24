import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../entities/knowledge_relationship.dart';
import '../value_objects/relationship_type.dart';

/// Factory responsible for constructing and validating [KnowledgeRelationship] domain entities.
class RelationshipFactory {
  /// Creates a validated [KnowledgeRelationship] edge.
  ///
  /// Throws [ArgumentError] if invalid parameters are provided.
  KnowledgeRelationship createRelationship({
    required String sourceKnowledgeId,
    required String targetKnowledgeId,
    required RelationshipType relationshipType,
    double confidence = 1.0,
    Map<String, dynamic> metadata = const {},
    String? relationshipId,
    DateTime? createdAt,
  }) {
    final cleanSource = sourceKnowledgeId.trim();
    final cleanTarget = targetKnowledgeId.trim();

    if (cleanSource.isEmpty) {
      throw ArgumentError('sourceKnowledgeId cannot be empty');
    }
    if (cleanTarget.isEmpty) {
      throw ArgumentError('targetKnowledgeId cannot be empty');
    }
    if (cleanSource == cleanTarget) {
      throw ArgumentError(
        'Self-referential relationships are invalid (sourceKnowledgeId cannot equal targetKnowledgeId)',
      );
    }
    if (confidence < 0.0 || confidence > 1.0) {
      throw ArgumentError('confidence score must be between 0.0 and 1.0');
    }

    final computedId = relationshipId ??
        _generateDeterministicId(cleanSource, cleanTarget, relationshipType);

    return KnowledgeRelationship(
      relationshipId: computedId,
      sourceKnowledgeId: cleanSource,
      targetKnowledgeId: cleanTarget,
      relationshipType: relationshipType,
      confidence: confidence,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  String _generateDeterministicId(
    String sourceId,
    String targetId,
    RelationshipType type,
  ) {
    final rawKey = '$sourceId::${type.name}::$targetId';
    final bytes = utf8.encode(rawKey);
    final hash = sha256.convert(bytes);
    return 'rel_${hash.toString().substring(0, 16)}';
  }
}
