/// Graph integrity validation (TITAN-KO-015.0 P5).
///
/// Validates a legal graph (or the raw edge set proposed for it) for:
/// - missing nodes (edges referencing a node that is not present),
/// - duplicate edges (same source, type, target recorded more than once),
/// - self-loops (a legal edge must never connect a node to itself),
/// - invalid relationship types / non-canonical IDs,
/// - missing or unregistered evidence,
/// - unknown case / doctrine IDs.
///
/// Validation is evidence-gated: an edge without a registered evidence
/// reference is flagged, mirroring the P4 intelligence validator's posture.
library;

import 'package:meta/meta.dart';

import '../../domain/entities/case_enums.dart';
import '../data/legal_graph_seed.dart';
import '../domain/doctrine_relationship_type.dart';
import '../domain/legal_graph.dart';
import '../domain/legal_graph_edge.dart';
import '../domain/legal_graph_node_ref.dart';
import '../domain/legal_graph_node_type.dart';

/// Severity of a graph validation issue.
enum GraphIssueSeverity { error, warning }

@immutable
class LegalGraphValidationIssue {
  final String code;
  final String message;

  /// The edge (or node) the issue concerns; empty for global issues.
  final String subject;
  final GraphIssueSeverity severity;

  const LegalGraphValidationIssue({
    required this.code,
    required this.message,
    this.subject = '',
    this.severity = GraphIssueSeverity.error,
  });

  @override
  String toString() =>
      '[$code] ${subject.isEmpty ? message : '($subject) $message'} (${severity.name})';
}

@immutable
class LegalGraphValidationResult {
  final bool isValid;
  final List<LegalGraphValidationIssue> issues;

  const LegalGraphValidationResult({required this.isValid, this.issues = const []});

  factory LegalGraphValidationResult.success() =>
      const LegalGraphValidationResult(isValid: true);

  factory LegalGraphValidationResult.failure(
          List<LegalGraphValidationIssue> issues) =>
      LegalGraphValidationResult(isValid: false, issues: issues);

  List<LegalGraphValidationIssue> get errors => issues
      .where((i) => i.severity == GraphIssueSeverity.error)
      .toList(growable: false);

  List<LegalGraphValidationIssue> get warnings => issues
      .where((i) => i.severity == GraphIssueSeverity.warning)
      .toList(growable: false);

  @override
  String toString() => 'LegalGraphValidationResult(isValid: $isValid, '
      'issues: ${issues.length})';
}

/// Integrity validator for the Precedent & Doctrine Graph.
class LegalGraphValidator {
  /// Validates a whole graph aggregate.
  static LegalGraphValidationResult validateGraph(LegalGraph graph) {
    return validateEdges(
      graph.edges,
      caseIds: graph.caseNodes.map((n) => n.id).toSet(),
      doctrineIds: graph.doctrineNodes.map((n) => n.id).toSet(),
      nodes: graph.nodes,
    );
  }

  /// Validates an arbitrary edge set against canonical node ID sets.
  static LegalGraphValidationResult validateEdges(
    List<LegalGraphEdge> edges, {
    required Set<String> caseIds,
    required Set<String> doctrineIds,
    List<LegalGraphNodeRef>? nodes,
  }) {
    final issues = <LegalGraphValidationIssue>[];

    final nodeKeys = <String>{for (final n in nodes ?? const []) n.nodeKey};
    final seenTriples = <String>{};

    for (final edge in edges) {
      final subject = edge.edgeId;

      // Canonical source node.
      if (!_nodeKnown(nodeKeys, edge.sourceId, edge.sourceNodeType,
          caseIds: caseIds, doctrineIds: doctrineIds)) {
        issues.add(LegalGraphValidationIssue(
          code: 'missing_source_node',
          message: 'edge source "${edge.sourceId}" is not a known '
              '${edge.sourceNodeType.name} node',
          subject: subject,
        ));
      }
      // Canonical target node.
      if (!_nodeKnown(nodeKeys, edge.targetId, edge.targetNodeType,
          caseIds: caseIds, doctrineIds: doctrineIds)) {
        issues.add(LegalGraphValidationIssue(
          code: 'missing_target_node',
          message: 'edge target "${edge.targetId}" is not a known '
              '${edge.targetNodeType.name} node',
          subject: subject,
        ));
      }

      // Self-loop.
      if (edge.sourceId == edge.targetId) {
        issues.add(LegalGraphValidationIssue(
          code: 'self_loop',
          message: 'a legal edge cannot connect a node to itself',
          subject: subject,
        ));
      }

      // Unknown case / doctrine IDs on the endpoints.
      if (edge.sourceNodeType == LegalGraphNodeType.caseLaw &&
          !caseIds.contains(edge.sourceId)) {
        issues.add(LegalGraphValidationIssue(
          code: 'unknown_case_id',
          message: '"${edge.sourceId}" is not a canonical case ID',
          subject: subject,
        ));
      }
      if (edge.targetNodeType == LegalGraphNodeType.caseLaw &&
          !caseIds.contains(edge.targetId)) {
        issues.add(LegalGraphValidationIssue(
          code: 'unknown_case_id',
          message: '"${edge.targetId}" is not a canonical case ID',
          subject: subject,
        ));
      }
      if (edge.targetNodeType == LegalGraphNodeType.doctrine &&
          !doctrineIds.contains(edge.targetId)) {
        issues.add(LegalGraphValidationIssue(
          code: 'unknown_doctrine_id',
          message: '"${edge.targetId}" is not a canonical doctrine ID',
          subject: subject,
        ));
      }

      // Invalid relationship type for the edge category.
      if (edge is PrecedentGraphEdge &&
          !PrecedentRelationshipType.values.contains(edge.type)) {
        issues.add(LegalGraphValidationIssue(
          code: 'invalid_relationship_type',
          message: 'unknown precedent relationship type "${edge.typeLabel}"',
          subject: subject,
        ));
      }
      if (edge is DoctrineGraphEdge &&
          !DoctrineRelationshipType.values.contains(edge.type)) {
        issues.add(LegalGraphValidationIssue(
          code: 'invalid_relationship_type',
          message: 'unknown doctrine relationship type "${edge.typeLabel}"',
          subject: subject,
        ));
      }

      // Evidence must be registered.
      if (edge.evidenceIds.isEmpty) {
        issues.add(LegalGraphValidationIssue(
          code: 'missing_evidence',
          message: 'edge carries no evidence reference',
          subject: subject,
        ));
      } else {
        for (final evidenceId in edge.evidenceIds) {
          if (!LegalGraphSeed.isRegisteredEvidence(evidenceId)) {
            issues.add(LegalGraphValidationIssue(
              code: 'unregistered_evidence',
              message: 'evidence reference "$evidenceId" is not registered',
              subject: subject,
            ));
          }
        }
      }

      // Duplicate (source, type, target).
      if (!seenTriples.add(edge.tripleKey)) {
        issues.add(LegalGraphValidationIssue(
          code: 'duplicate_edge',
          message: 'duplicate edge (${edge.sourceId} ${edge.typeLabel} '
              '${edge.targetId})',
          subject: subject,
        ));
      }
    }

    return issues.isEmpty
        ? LegalGraphValidationResult.success()
        : LegalGraphValidationResult.failure(issues);
  }

  static bool _nodeKnown(
    Set<String> nodeKeys,
    String id,
    LegalGraphNodeType type, {
    required Set<String> caseIds,
    required Set<String> doctrineIds,
  }) {
    if (nodeKeys.isNotEmpty) {
      return nodeKeys.contains(
          type == LegalGraphNodeType.caseLaw ? 'case:$id' : 'doctrine:$id');
    }
    // No explicit node list supplied — fall back to the canonical ID sets.
    return type == LegalGraphNodeType.caseLaw
        ? caseIds.contains(id)
        : doctrineIds.contains(id);
  }
}
