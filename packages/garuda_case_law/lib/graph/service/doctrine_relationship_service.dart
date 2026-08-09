/// Doctrine Relationship service (TITAN-KO-015.0 P5).
///
/// Case ↔ doctrine navigation: which doctrines a case engages, and — the
/// reverse direction — which cases establish, apply, develop, follow, expand,
/// limit or distinguish a doctrine. Doctrine nodes use the canonical
/// `garuda_doctrine` `doctrineId`s; no doctrine records are duplicated inside
/// `garuda_case_law`.
library;

import '../data/legal_graph_seed.dart';
import '../domain/doctrine_relationship_type.dart';
import '../domain/legal_graph.dart';
import '../domain/legal_graph_edge.dart';
import '../domain/legal_graph_node_ref.dart';
import '../domain/legal_graph_node_type.dart';

/// Read-side service over case ↔ doctrine edges.
class DoctrineRelationshipService {
  final LegalGraph graph;

  DoctrineRelationshipService({LegalGraph? graph})
      : graph = graph ?? LegalGraphSeed.fromCorpus().build();

  // -------------------------------------------------------------------------
  // Node access
  // -------------------------------------------------------------------------

  bool hasDoctrine(String doctrineId) => graph.hasDoctrine(doctrineId);

  LegalGraphNodeRef? doctrineNode(String doctrineId) =>
      graph.nodeFor(doctrineId, LegalGraphNodeType.doctrine);

  List<LegalGraphNodeRef> get allDoctrines => graph.doctrineNodes;

  /// The graph snapshot this service reads from.
  LegalGraph get snapshot => graph;

  // -------------------------------------------------------------------------
  // Case → doctrine
  // -------------------------------------------------------------------------

  /// The doctrines engaged by [caseId], with their evidence-backed roles.
  List<DoctrineGraphEdge> getDoctrinesForCase(String caseId) => graph
      .edgesFrom(caseId, LegalGraphNodeType.caseLaw)
      .whereType<DoctrineGraphEdge>()
      .toList(growable: false);

  // -------------------------------------------------------------------------
  // Doctrine → case (reverse navigation)
  // -------------------------------------------------------------------------

  /// Every case meaningfully related to [doctrineId], with roles.
  List<DoctrineGraphEdge> getCasesForDoctrine(String doctrineId) => graph
      .edgesTo(doctrineId, LegalGraphNodeType.doctrine)
      .whereType<DoctrineGraphEdge>()
      .toList(growable: false);

  /// Cases that establish [doctrineId].
  List<DoctrineGraphEdge> getCasesEstablishing(String doctrineId) =>
      _casesWithRole(doctrineId, DoctrineRelationshipType.establishes);

  /// Cases that apply [doctrineId].
  List<DoctrineGraphEdge> getCasesApplying(String doctrineId) =>
      _casesWithRole(doctrineId, DoctrineRelationshipType.applies);

  /// Cases that develop [doctrineId].
  List<DoctrineGraphEdge> getCasesDeveloping(String doctrineId) =>
      _casesWithRole(doctrineId, DoctrineRelationshipType.develops);

  /// Cases that follow [doctrineId].
  List<DoctrineGraphEdge> getCasesFollowing(String doctrineId) =>
      _casesWithRole(doctrineId, DoctrineRelationshipType.follows);

  /// Cases that expand [doctrineId].
  List<DoctrineGraphEdge> getCasesExpanding(String doctrineId) =>
      _casesWithRole(doctrineId, DoctrineRelationshipType.expands);

  /// Cases that limit [doctrineId].
  List<DoctrineGraphEdge> getCasesLimiting(String doctrineId) =>
      _casesWithRole(doctrineId, DoctrineRelationshipType.limits);

  /// Cases that distinguish [doctrineId].
  List<DoctrineGraphEdge> getCasesDistinguishing(String doctrineId) =>
      _casesWithRole(doctrineId, DoctrineRelationshipType.distinguishes);

  /// Cases that merely engage [doctrineId].
  List<DoctrineGraphEdge> getCasesEngaging(String doctrineId) =>
      _casesWithRole(doctrineId, DoctrineRelationshipType.engages);

  /// Cases related to [doctrineId] through a specific role.
  List<DoctrineGraphEdge> _casesWithRole(
          String doctrineId, DoctrineRelationshipType role) =>
      getCasesForDoctrine(doctrineId)
          .where((e) => e.type == role)
          .toList(growable: false);
}
