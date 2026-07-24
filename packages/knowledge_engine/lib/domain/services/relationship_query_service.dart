import '../entities/knowledge_relationship.dart';
import '../repositories/relationship_repository.dart';
import '../value_objects/relationship_type.dart';

/// Domain service executing directional graph relationship queries against
/// the [RelationshipRepository] in the TITAN Knowledge Intelligence Engine.
class RelationshipQueryService {
  final RelationshipRepository _repository;

  /// Constructs a [RelationshipQueryService] with the specified [_repository].
  const RelationshipQueryService(this._repository);

  /// Retrieves all outgoing relationship edges originating from [nodeId].
  Future<List<KnowledgeRelationship>> getOutgoingRelationships(
      String nodeId) async {
    if (nodeId.trim().isEmpty) return const [];
    return await _repository.getOutgoingRelationships(nodeId);
  }

  /// Retrieves all incoming relationship edges pointing to [nodeId].
  Future<List<KnowledgeRelationship>> getIncomingRelationships(
      String nodeId) async {
    if (nodeId.trim().isEmpty) return const [];
    return await _repository.getIncomingRelationships(nodeId);
  }

  /// Retrieves all relationship edges connected to [nodeId] matching the specified [type].
  ///
  /// If [outgoingOnly] is true, only outgoing edges originating from [nodeId] are returned.
  /// Otherwise, both incoming and outgoing edges matching [type] are evaluated.
  Future<List<KnowledgeRelationship>> getRelationshipsByType(
    String nodeId,
    RelationshipType type, {
    bool outgoingOnly = false,
  }) async {
    if (nodeId.trim().isEmpty) return const [];

    final outgoing = await _repository.getOutgoingRelationships(nodeId);
    final filteredOutgoing =
        outgoing.where((r) => r.relationshipType == type).toList();

    if (outgoingOnly) {
      return filteredOutgoing;
    }

    final incoming = await _repository.getIncomingRelationships(nodeId);
    final filteredIncoming =
        incoming.where((r) => r.relationshipType == type).toList();

    final merged = <String, KnowledgeRelationship>{};
    for (final rel in filteredOutgoing) {
      merged[rel.relationshipId] = rel;
    }
    for (final rel in filteredIncoming) {
      merged[rel.relationshipId] = rel;
    }

    return merged.values.toList();
  }

  /// Retrieves all relationship edges (outgoing and incoming) associated with [nodeId].
  Future<List<KnowledgeRelationship>> getAllRelationships(String nodeId) async {
    if (nodeId.trim().isEmpty) return const [];

    final outgoing = await _repository.getOutgoingRelationships(nodeId);
    final incoming = await _repository.getIncomingRelationships(nodeId);

    final merged = <String, KnowledgeRelationship>{};
    for (final rel in outgoing) {
      merged[rel.relationshipId] = rel;
    }
    for (final rel in incoming) {
      merged[rel.relationshipId] = rel;
    }

    return merged.values.toList();
  }
}
