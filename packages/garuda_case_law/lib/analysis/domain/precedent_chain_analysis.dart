/// Precedent-chain models for the Evidence-Bounded Cross-Case Analysis layer
/// (TITAN-KO-015.0 P10).
///
/// A chain analysis reuses the P5 `LegalGraphTraversalService`
/// `predecessorChain` / `successorChain` paths verbatim and enriches each node
/// with its P4 case intelligence and its authoritative chronology. P5
/// relationship semantics are preserved exactly: edge types are exposed as-is
/// and are never reinterpreted as citations, overruling, refinement or
/// extension (see `P10_CROSS_CASE_ANALYSIS.md`).
library;

import 'package:meta/meta.dart';

import '../../domain/entities/case_knowledge_object.dart';
import 'analysis_enums.dart';

/// The P5 edge traversed to reach an entry, recorded verbatim so the
/// relationship vocabulary, direction and provenance stay authoritative.
@immutable
class PrecedentRelationshipStep {
  /// Stable P5 edge identifier (`e:<source>|<type>|<target>`).
  final String edgeId;

  /// P5 relationship type name, exactly as recorded (e.g. `followed`).
  final String typeLabel;

  /// Source node ID of the edge (P5 semantics).
  final String sourceId;

  /// Target node ID of the edge (P5 semantics).
  final String targetId;

  /// Provenance recorded on the edge (e.g. `corpus:precedentsFollowed`).
  final String provenance;

  /// Evidence references recorded on the edge.
  final List<String> evidenceIds;

  const PrecedentRelationshipStep({
    required this.edgeId,
    required this.typeLabel,
    required this.sourceId,
    required this.targetId,
    required this.provenance,
    required this.evidenceIds,
  });

  Map<String, dynamic> toJson() => {
        'edgeId': edgeId,
        'typeLabel': typeLabel,
        'sourceId': sourceId,
        'targetId': targetId,
        'provenance': provenance,
        'evidenceIds': evidenceIds,
      };

  factory PrecedentRelationshipStep.fromJson(Map<String, dynamic> json) =>
      PrecedentRelationshipStep(
        edgeId: json['edgeId'] as String? ?? '',
        typeLabel: json['typeLabel'] as String? ?? '',
        sourceId: json['sourceId'] as String? ?? '',
        targetId: json['targetId'] as String? ?? '',
        provenance: json['provenance'] as String? ?? '',
        evidenceIds: (json['evidenceIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrecedentRelationshipStep &&
          edgeId == other.edgeId &&
          typeLabel == other.typeLabel &&
          sourceId == other.sourceId &&
          targetId == other.targetId &&
          provenance == other.provenance &&
          _listEquals(evidenceIds, other.evidenceIds);

  @override
  int get hashCode =>
      Object.hash(edgeId, typeLabel, sourceId, targetId, provenance);

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// One node of a precedent chain with its P4 case intelligence and the edge
/// that reached it from the previous node.
@immutable
class PrecedentChainEntry {
  /// Canonical corpus case ID.
  final String caseId;

  /// Display case name.
  final String caseName;

  /// Judgment year (authoritative chronology).
  final int year;

  /// Judgment date from the record.
  final DateTime judgmentDate;

  /// P4 holding texts (empty when no P4 intelligence).
  final List<String> holdings;

  /// P4 ratio texts (empty when no P4 intelligence).
  final List<String> ratios;

  /// P4 issue texts (empty when no P4 intelligence).
  final List<String> issues;

  /// The P5 edge traversed from the previous entry, or null for the anchor.
  final PrecedentRelationshipStep? relationshipFromPrevious;

  /// The full validated case record (never fabricated).
  final CaseKnowledgeObject caseObject;

  const PrecedentChainEntry({
    required this.caseId,
    required this.caseName,
    required this.year,
    required this.judgmentDate,
    required this.holdings,
    required this.ratios,
    required this.issues,
    required this.relationshipFromPrevious,
    required this.caseObject,
  });

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'caseName': caseName,
        'year': year,
        'judgmentDate': judgmentDate.toIso8601String(),
        'holdings': holdings,
        'ratios': ratios,
        'issues': issues,
        if (relationshipFromPrevious != null)
          'relationshipFromPrevious': relationshipFromPrevious!.toJson(),
        'caseObject': caseObject.toJson(),
      };

  factory PrecedentChainEntry.fromJson(Map<String, dynamic> json) =>
      PrecedentChainEntry(
        caseId: json['caseId'] as String? ?? '',
        caseName: json['caseName'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? 0,
        judgmentDate:
            DateTime.tryParse(json['judgmentDate'] as String? ?? '') ??
                DateTime(0),
        holdings: (json['holdings'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        ratios: (json['ratios'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        issues: (json['issues'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        relationshipFromPrevious: json['relationshipFromPrevious'] == null
            ? null
            : PrecedentRelationshipStep.fromJson(
                json['relationshipFromPrevious'] as Map<String, dynamic>),
        caseObject: CaseKnowledgeObject.fromJson(
            json['caseObject'] as Map<String, dynamic>),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrecedentChainEntry && caseId == other.caseId;

  @override
  int get hashCode => caseId.hashCode;
}

/// A deterministic precedent-chain analysis over the P5 graph.
///
/// The chain reuses the P5 traversal path exactly ([direction] maps to
/// `predecessorChain` / `successorChain`); no edge is created, modified or
/// reinterpreted.
@immutable
class PrecedentChainAnalysis {
  /// Canonical ID of the anchor (root) case.
  final String anchorCaseId;

  /// Direction of the chain relative to the anchor.
  final PrecedentChainDirection direction;

  /// Entries in traversal order, the anchor first.
  final List<PrecedentChainEntry> entries;

  const PrecedentChainAnalysis({
    required this.anchorCaseId,
    required this.direction,
    required this.entries,
  }) : assert(entries.length > 0, 'a chain analysis needs at least the anchor');

  /// Number of hops in the chain (0 when it is a single-node chain).
  int get length => entries.length - 1;

  /// Canonical case IDs in traversal order.
  List<String> get caseIds =>
      entries.map((e) => e.caseId).toList(growable: false);

  Map<String, dynamic> toJson() => {
        'anchorCaseId': anchorCaseId,
        'direction': direction.name,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory PrecedentChainAnalysis.fromJson(Map<String, dynamic> json) =>
      PrecedentChainAnalysis(
        anchorCaseId: json['anchorCaseId'] as String? ?? '',
        direction: PrecedentChainDirection.values.firstWhere(
          (e) => e.name == json['direction'],
          orElse: () => PrecedentChainDirection.predecessor,
        ),
        entries: (json['entries'] as List<dynamic>? ?? const [])
            .map((e) => PrecedentChainEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  String toString() => 'PrecedentChainAnalysis($anchorCaseId, '
      '${direction.name}, $length hop(s))';
}
