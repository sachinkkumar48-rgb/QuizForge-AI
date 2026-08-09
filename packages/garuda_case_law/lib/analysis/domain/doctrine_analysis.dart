/// Doctrine-oriented analysis models for the Evidence-Bounded Cross-Case
/// Analysis layer (TITAN-KO-015.0 P10).
///
/// Deterministic analysis of the cases belonging to a validated doctrine using
/// the existing P5 case → doctrine edges and P4 intelligence. The doctrine's
/// *roles* (`establishes`, `applies`, `develops`, ...) come verbatim from the
/// P5 edge — they are recorded evidence, not a P10 inference. P10 never claims
/// that "the doctrine evolved from X to Y"; the consumer observes the
/// progression from the underlying chronological evidence.
library;

import 'package:meta/meta.dart';

import '../../domain/entities/case_knowledge_object.dart';
import '../../graph/domain/legal_graph_edge.dart';
import 'chronology.dart';
import 'structural_observation.dart';

/// One case associated with a doctrine, with its P5 role and P4 intelligence.
@immutable
class DoctrineCaseEntry {
  /// Canonical corpus case ID.
  final String caseId;

  /// Display case name.
  final String caseName;

  /// Judgment year (authoritative chronology).
  final int year;

  /// Judgment date from the record.
  final DateTime judgmentDate;

  /// P5 doctrine-relationship role name, verbatim (e.g. `establishes`,
  /// `applies`, `develops`, `follows`, `expands`, `limits`, `distinguishes`,
  /// `engages`).
  final String role;

  /// Human-readable role label (P5 display name).
  final String roleLabel;

  /// P5 case → doctrine edge identifier.
  final String edgeId;

  /// Provenance recorded on the edge (e.g. `doctrine:BASIC_STRUCTURE.originatingCase`).
  final String provenance;

  /// P4 holding texts (empty when no P4 intelligence).
  final List<String> holdings;

  /// P4 ratio texts (empty when no P4 intelligence).
  final List<String> ratios;

  /// P4 issue texts (empty when no P4 intelligence).
  final List<String> issues;

  /// P4 outcome disposition name (empty when no P4 outcome).
  final String outcome;

  /// The full validated case record (never fabricated).
  final CaseKnowledgeObject caseObject;

  const DoctrineCaseEntry({
    required this.caseId,
    required this.caseName,
    required this.year,
    required this.judgmentDate,
    required this.role,
    required this.roleLabel,
    required this.edgeId,
    required this.provenance,
    required this.holdings,
    required this.ratios,
    required this.issues,
    required this.outcome,
    required this.caseObject,
  });

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'caseName': caseName,
        'year': year,
        'judgmentDate': judgmentDate.toIso8601String(),
        'role': role,
        'roleLabel': roleLabel,
        'edgeId': edgeId,
        'provenance': provenance,
        'holdings': holdings,
        'ratios': ratios,
        'issues': issues,
        'outcome': outcome,
        'caseObject': caseObject.toJson(),
      };

  factory DoctrineCaseEntry.fromJson(Map<String, dynamic> json) =>
      DoctrineCaseEntry(
        caseId: json['caseId'] as String? ?? '',
        caseName: json['caseName'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? 0,
        judgmentDate:
            DateTime.tryParse(json['judgmentDate'] as String? ?? '') ??
                DateTime(0),
        role: json['role'] as String? ?? '',
        roleLabel: json['roleLabel'] as String? ?? '',
        edgeId: json['edgeId'] as String? ?? '',
        provenance: json['provenance'] as String? ?? '',
        holdings: (json['holdings'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        ratios: (json['ratios'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        issues: (json['issues'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        outcome: json['outcome'] as String? ?? '',
        caseObject: CaseKnowledgeObject.fromJson(
            json['caseObject'] as Map<String, dynamic>),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctrineCaseEntry && caseId == other.caseId;

  @override
  int get hashCode => caseId.hashCode;
}

/// The deterministic result of a doctrine-oriented cross-case analysis.
@immutable
class DoctrineAnalysisResult {
  /// Canonical doctrine ID (empty when the doctrine could not be resolved).
  final String doctrineId;

  /// Doctrine display name (empty when unresolved).
  final String doctrineName;

  /// Cases associated with the doctrine, ordered chronologically.
  final List<DoctrineCaseEntry> cases;

  /// Chronological sequence over the member cases (empty when none).
  final ChronologyAnalysis chronology;

  /// P5 precedent (case → case) edges among the member cases, in a
  /// deterministic order. Relationship types are verbatim P5.
  final List<PrecedentGraphEdge> graphRelationships;

  /// Structural observations (e.g. the chronological span of the doctrine's
  /// corpus cases).
  final List<StructuralObservation> observations;

  const DoctrineAnalysisResult({
    required this.doctrineId,
    required this.doctrineName,
    required this.cases,
    required this.chronology,
    required this.graphRelationships,
    required this.observations,
  });

  /// True when no corpus case is associated with the doctrine.
  bool get isEmpty => cases.isEmpty;

  /// Canonical case IDs of the doctrine's member cases, in chronological order.
  List<String> get caseIds =>
      cases.map((c) => c.caseId).toList(growable: false);

  Map<String, dynamic> toJson() => {
        'doctrineId': doctrineId,
        'doctrineName': doctrineName,
        'cases': cases.map((c) => c.toJson()).toList(),
        'chronology': chronology.toJson(),
        'graphRelationships':
            graphRelationships.map((e) => e.toJson()).toList(),
        'observations': observations.map((o) => o.toJson()).toList(),
      };

  factory DoctrineAnalysisResult.fromJson(Map<String, dynamic> json) =>
      DoctrineAnalysisResult(
        doctrineId: json['doctrineId'] as String? ?? '',
        doctrineName: json['doctrineName'] as String? ?? '',
        cases: (json['cases'] as List<dynamic>? ?? const [])
            .map((e) => DoctrineCaseEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        chronology: ChronologyAnalysis.fromJson(
            json['chronology'] as Map<String, dynamic>? ?? const {}),
        graphRelationships:
            (json['graphRelationships'] as List<dynamic>? ?? const [])
                .map((e) => LegalGraphEdge.fromJson(e as Map<String, dynamic>))
                .whereType<PrecedentGraphEdge>()
                .toList(),
        observations: (json['observations'] as List<dynamic>? ?? const [])
            .map((e) =>
                StructuralObservation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  String toString() => 'DoctrineAnalysisResult($doctrineId, '
      '${cases.length} case(s))';
}
