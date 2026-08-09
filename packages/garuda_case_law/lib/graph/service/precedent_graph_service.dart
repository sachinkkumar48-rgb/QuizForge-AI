/// Precedent Graph service (TITAN-KO-015.0 P5).
///
/// Owns the aggregated [LegalGraph] and exposes the case → case queries:
/// direct precedents, cases following/overruling/distinguishing a case,
/// related cases, and the raw outgoing/incoming relationship sets. Every
/// returned edge carries its evidence and provenance.
///
/// Queries against an unknown case ID return empty results — nothing is
/// fabricated, and missing nodes are surfaced by the validator, not invented
/// here.
library;

import '../../domain/entities/case_enums.dart';
import '../data/legal_graph_seed.dart';
import '../domain/legal_graph.dart';
import '../domain/legal_graph_edge.dart';
import '../domain/legal_graph_node_ref.dart';
import '../domain/legal_graph_node_type.dart';

/// Read-side service over the case → case legal graph.
class PrecedentGraphService {
  final LegalGraph graph;

  PrecedentGraphService({LegalGraph? graph})
      : graph = graph ?? LegalGraphSeed.fromCorpus().build();

  // -------------------------------------------------------------------------
  // Node access
  // -------------------------------------------------------------------------

  bool hasCase(String caseId) => graph.hasCase(caseId);

  LegalGraphNodeRef? caseNode(String caseId) =>
      graph.nodeFor(caseId, LegalGraphNodeType.caseLaw);

  List<LegalGraphNodeRef> get allCases => graph.caseNodes;

  /// The graph snapshot this service reads from.
  LegalGraph get snapshot => graph;

  // -------------------------------------------------------------------------
  // Case → case queries
  // -------------------------------------------------------------------------

  /// Types of edges that express reliance on an earlier authority.
  static const Set<PrecedentRelationshipType> _authorityTypes = {
    PrecedentRelationshipType.followed,
    PrecedentRelationshipType.applied,
    PrecedentRelationshipType.affirmed,
    PrecedentRelationshipType.approved,
    PrecedentRelationshipType.clarified,
    PrecedentRelationshipType.expanded,
  };

  /// The direct precedent authorities of a case — the cases it follows,
  /// applies or affirms (outgoing authority edges).
  List<PrecedentGraphEdge> directPrecedents(String caseId) => graph
      .edgesFrom(caseId, LegalGraphNodeType.caseLaw)
      .whereType<PrecedentGraphEdge>()
      .where((e) => _authorityTypes.contains(e.type))
      .toList(growable: false);

  /// Cases that follow [caseId] (incoming `followed` edges).
  List<PrecedentGraphEdge> casesFollowing(String caseId) => graph
      .edgesTo(caseId, LegalGraphNodeType.caseLaw)
      .whereType<PrecedentGraphEdge>()
      .where((e) => e.type == PrecedentRelationshipType.followed)
      .toList(growable: false);

  /// Cases that overrule [caseId] (incoming `overruled` edges).
  List<PrecedentGraphEdge> casesOverruling(String caseId) => graph
      .edgesTo(caseId, LegalGraphNodeType.caseLaw)
      .whereType<PrecedentGraphEdge>()
      .where((e) => e.type == PrecedentRelationshipType.overruled)
      .toList(growable: false);

  /// Cases that distinguish [caseId] (incoming `distinguished` edges).
  List<PrecedentGraphEdge> casesDistinguishing(String caseId) => graph
      .edgesTo(caseId, LegalGraphNodeType.caseLaw)
      .whereType<PrecedentGraphEdge>()
      .where((e) => e.type == PrecedentRelationshipType.distinguished)
      .toList(growable: false);

  /// Cases related to [caseId]. The corpus stores `related` edges
  /// directionally, so relatedness is treated symmetrically here.
  List<PrecedentGraphEdge> relatedCases(String caseId) => [
        ...graph
            .edgesFrom(caseId, LegalGraphNodeType.caseLaw)
            .whereType<PrecedentGraphEdge>()
            .where((e) => e.type == PrecedentRelationshipType.related),
        ...graph
            .edgesTo(caseId, LegalGraphNodeType.caseLaw)
            .whereType<PrecedentGraphEdge>()
            .where((e) => e.type == PrecedentRelationshipType.related),
      ];

  /// Every relationship established by [caseId] onto other cases.
  List<PrecedentGraphEdge> outgoingRelationships(String caseId) =>
      graph
          .edgesFrom(caseId, LegalGraphNodeType.caseLaw)
          .whereType<PrecedentGraphEdge>()
          .toList(growable: false);

  /// Every relationship other cases direct at [caseId].
  List<PrecedentGraphEdge> incomingRelationships(String caseId) =>
      graph
          .edgesTo(caseId, LegalGraphNodeType.caseLaw)
          .whereType<PrecedentGraphEdge>()
          .toList(growable: false);

  /// All relationship edges between two cases (either direction).
  List<PrecedentGraphEdge> relationshipsBetween(String a, String b) => [
        ...graph.edgesBetween(a, b).whereType<PrecedentGraphEdge>(),
        ...graph.edgesBetween(b, a).whereType<PrecedentGraphEdge>(),
      ];
}
