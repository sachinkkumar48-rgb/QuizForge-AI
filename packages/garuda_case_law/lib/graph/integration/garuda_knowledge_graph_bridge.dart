/// Bridge from the legal Precedent & Doctrine Graph to the generic GARUDA
/// Knowledge Graph (TITAN-KO-015.0 P5).
///
/// The legal semantics live in `garuda_case_law` (typed [PrecedentGraphEdge]
/// and [DoctrineGraphEdge]). This bridge maps the same edges onto
/// `garuda_graph`'s generic `KnowledgeLink` model so the legal graph can be
/// exported into the cross-package knowledge graph for integration — reusing
/// the generic graph infrastructure instead of rebuilding it.
///
/// The mapping is deliberately lossy and *integration-only*: relationship
/// types are projected onto the generic vocabulary (e.g. `followed` →
/// `references`, `overruled` → `overrules`, `related` → `relatedTo`). Legal
/// fidelity is preserved by the typed graph this bridge reads from.
library;

import 'package:garuda_graph/garuda_graph.dart'
    show
        InMemoryKnowledgeGraphRepository,
        KnowledgeGraphRepository,
        KnowledgeLink,
        KnowledgeNodeRef,
        KnowledgeRelationshipType,
        LinkStatus,
        NodeType;

import '../../domain/entities/case_enums.dart';
import '../domain/doctrine_relationship_type.dart';
import '../domain/legal_graph.dart';
import '../domain/legal_graph_edge.dart';
import '../domain/legal_graph_node_ref.dart';
import '../domain/legal_graph_node_type.dart';

/// Maps legal nodes/edges onto the generic knowledge-graph model.
class GarudaKnowledgeGraphBridge {
  /// Maps a case node.
  static KnowledgeNodeRef caseNodeToKnowledgeNode(LegalGraphNodeRef node) =>
      KnowledgeNodeRef(
        id: node.id,
        name: node.name,
        nodeType: NodeType.caseLaw,
        category: 'Case Law',
        attributes: node.attributes,
      );

  /// Maps a doctrine node.
  static KnowledgeNodeRef doctrineNodeToKnowledgeNode(LegalGraphNodeRef node) =>
      KnowledgeNodeRef(
        id: node.id,
        name: node.name,
        nodeType: NodeType.concept,
        category: 'Doctrine',
        attributes: node.attributes,
      );

  /// Maps a single legal edge onto a generic [KnowledgeLink].
  static KnowledgeLink toKnowledgeLink(
    LegalGraphEdge edge, {
    required DateTime timestamp,
  }) {
    final source = edge.sourceNodeType == LegalGraphNodeType.caseLaw
        ? KnowledgeNodeRef(
            id: edge.sourceId,
            name: edge.sourceId,
            nodeType: NodeType.caseLaw,
            category: 'Case Law',
          )
        : KnowledgeNodeRef(
            id: edge.sourceId,
            name: edge.sourceId,
            nodeType: NodeType.concept,
            category: 'Doctrine',
          );
    final target = edge.targetNodeType == LegalGraphNodeType.caseLaw
        ? KnowledgeNodeRef(
            id: edge.targetId,
            name: edge.targetId,
            nodeType: NodeType.caseLaw,
            category: 'Case Law',
          )
        : KnowledgeNodeRef(
            id: edge.targetId,
            name: edge.targetId,
            nodeType: NodeType.concept,
            category: 'Doctrine',
          );

    return KnowledgeLink(
      id: 'gkg:${edge.tripleKey}',
      sourceObject: source,
      targetObject: target,
      relationshipType: _mapRelationship(edge),
      confidenceScore: edge.confidence,
      createdBy: 'garuda_case_law:legal_graph_seed',
      createdAt: timestamp,
      updatedAt: timestamp,
      // Evidence-backed derived edges are trusted, not left in review.
      status: LinkStatus.approved,
      evidenceReferences: edge.evidenceIds,
      reason: edge.provenance,
    );
  }

  /// Exports the whole legal graph as generic knowledge links.
  static List<KnowledgeLink> exportLinks(LegalGraph graph) {
    final timestamp = DateTime.now();
    return graph.edges
        .map((e) => toKnowledgeLink(e, timestamp: timestamp))
        .toList(growable: false);
  }

  /// Persists the legal graph into a generic [KnowledgeGraphRepository]
  /// (e.g. [InMemoryKnowledgeGraphRepository]), returning the number of links
  /// saved.
  static Future<int> exportToRepository(
    LegalGraph graph,
    KnowledgeGraphRepository repository,
  ) async {
    var saved = 0;
    for (final link in exportLinks(graph)) {
      await repository.saveLink(link);
      saved++;
    }
    return saved;
  }

  /// Projects a legal relationship onto the generic knowledge-graph
  /// vocabulary. Lossy by design — legal precision stays in the typed graph.
  static KnowledgeRelationshipType _mapRelationship(LegalGraphEdge edge) {
    if (edge is DoctrineGraphEdge) {
      return switch (edge.type) {
        DoctrineRelationshipType.establishes =>
          KnowledgeRelationshipType.derivedFrom,
        DoctrineRelationshipType.applies =>
          KnowledgeRelationshipType.usedIn,
        DoctrineRelationshipType.develops =>
          KnowledgeRelationshipType.leadsTo,
        DoctrineRelationshipType.follows =>
          KnowledgeRelationshipType.references,
        DoctrineRelationshipType.expands =>
          KnowledgeRelationshipType.affects,
        DoctrineRelationshipType.limits =>
          KnowledgeRelationshipType.affects,
        DoctrineRelationshipType.distinguishes =>
          KnowledgeRelationshipType.questionedIn,
        DoctrineRelationshipType.engages =>
          KnowledgeRelationshipType.relatedTo,
      };
    }
    if (edge is PrecedentGraphEdge) {
      return switch (edge.type) {
        PrecedentRelationshipType.followed =>
          KnowledgeRelationshipType.references,
        PrecedentRelationshipType.overruled =>
          KnowledgeRelationshipType.overrules,
        PrecedentRelationshipType.distinguished =>
          KnowledgeRelationshipType.questionedIn,
        PrecedentRelationshipType.related =>
          KnowledgeRelationshipType.relatedTo,
        PrecedentRelationshipType.affirmed =>
          KnowledgeRelationshipType.supportedBy,
        PrecedentRelationshipType.reversed =>
          KnowledgeRelationshipType.affects,
        PrecedentRelationshipType.applied =>
          KnowledgeRelationshipType.usedIn,
        PrecedentRelationshipType.expanded =>
          KnowledgeRelationshipType.affects,
        PrecedentRelationshipType.limited =>
          KnowledgeRelationshipType.affects,
        PrecedentRelationshipType.clarified =>
          KnowledgeRelationshipType.interprets,
        PrecedentRelationshipType.approved =>
          KnowledgeRelationshipType.supportedBy,
      };
    }
    return KnowledgeRelationshipType.relatedTo;
  }
}
