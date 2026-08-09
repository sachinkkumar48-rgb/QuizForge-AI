/// Multi-case synthesis models for the Evidence-Bounded Cross-Case Analysis
/// layer (TITAN-KO-015.0 P10).
///
/// A synthesis is an *evidence-preserving aggregation* of a selected set of
/// cases: it re-presents each case's identity, chronology, P4 intelligence,
/// doctrine/article/Act membership, P5 graph relationships and P9 discovery
/// context, and aggregates only deterministic structural facts (distinct
/// attributes, year span, counts, attributes common to all). It never invents
/// a legal conclusion or narrative.
library;

import 'package:meta/meta.dart';

import '../../discovery/domain/discovery_reason.dart';
import '../../domain/entities/case_knowledge_object.dart';
import '../../graph/domain/legal_graph_edge.dart';
import 'structural_observation.dart';

/// One case of a multi-case synthesis with its aggregated source data.
@immutable
class SynthesisCaseEntry {
  /// Canonical corpus case ID.
  final String caseId;

  /// Display case name.
  final String caseName;

  /// Reporter citation.
  final String citation;

  /// Judgment year.
  final int year;

  /// Judgment date from the record.
  final DateTime judgmentDate;

  /// P4 holding texts (empty when no P4 intelligence).
  final List<String> holdings;

  /// P4 ratio texts (empty when no P4 intelligence).
  final List<String> ratios;

  /// P4 issue texts (empty when no P4 intelligence).
  final List<String> issues;

  /// P4 outcome disposition name (empty when no P4 outcome).
  final String outcome;

  /// P4 constitutional significance.
  final String significance;

  /// Canonical doctrine IDs engaged by the case (P5 edges), sorted.
  final List<String> doctrines;

  /// Normalized constitutional-article keys, sorted.
  final List<String> articles;

  /// Normalized Act names, sorted.
  final List<String> acts;

  /// Evidence IDs on the validated record.
  final List<String> evidenceIds;

  /// P5 case → case edges touching this case whose other endpoint is also in
  /// the selection, in a deterministic order.
  final List<PrecedentGraphEdge> graphRelationships;

  /// The full validated case record (never fabricated).
  final CaseKnowledgeObject caseObject;

  const SynthesisCaseEntry({
    required this.caseId,
    required this.caseName,
    required this.citation,
    required this.year,
    required this.judgmentDate,
    required this.holdings,
    required this.ratios,
    required this.issues,
    required this.outcome,
    required this.significance,
    required this.doctrines,
    required this.articles,
    required this.acts,
    required this.evidenceIds,
    required this.graphRelationships,
    required this.caseObject,
  });

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'caseName': caseName,
        'citation': citation,
        'year': year,
        'judgmentDate': judgmentDate.toIso8601String(),
        'holdings': holdings,
        'ratios': ratios,
        'issues': issues,
        'outcome': outcome,
        'significance': significance,
        'doctrines': doctrines,
        'articles': articles,
        'acts': acts,
        'evidenceIds': evidenceIds,
        'graphRelationships':
            graphRelationships.map((e) => e.toJson()).toList(),
        'caseObject': caseObject.toJson(),
      };

  factory SynthesisCaseEntry.fromJson(Map<String, dynamic> json) =>
      SynthesisCaseEntry(
        caseId: json['caseId'] as String? ?? '',
        caseName: json['caseName'] as String? ?? '',
        citation: json['citation'] as String? ?? '',
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
        outcome: json['outcome'] as String? ?? '',
        significance: json['significance'] as String? ?? '',
        doctrines: (json['doctrines'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        articles: (json['articles'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        acts: (json['acts'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        evidenceIds: (json['evidenceIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        graphRelationships:
            (json['graphRelationships'] as List<dynamic>? ?? const [])
                .map((e) => LegalGraphEdge.fromJson(e as Map<String, dynamic>))
                .whereType<PrecedentGraphEdge>()
                .toList(),
        caseObject: CaseKnowledgeObject.fromJson(
            json['caseObject'] as Map<String, dynamic>),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SynthesisCaseEntry && caseId == other.caseId;

  @override
  int get hashCode => caseId.hashCode;
}

/// Deterministic aggregate facts over a synthesis selection.
@immutable
class SynthesisAggregate {
  /// Distinct canonical doctrine IDs across the selection, sorted.
  final List<String> doctrines;

  /// Distinct normalized article keys across the selection, sorted.
  final List<String> articles;

  /// Distinct normalized Act names across the selection, sorted.
  final List<String> acts;

  /// Earliest judgment year in the selection (null when empty).
  final int? earliestYear;

  /// Latest judgment year in the selection (null when empty).
  final int? latestYear;

  /// Total holding texts across the selection.
  final int totalHoldings;

  /// Total ratio texts across the selection.
  final int totalRatios;

  /// Total issue texts across the selection.
  final int totalIssues;

  /// Normalized article keys present in EVERY selection case, sorted.
  final List<String> commonArticles;

  /// Normalized Act names present in EVERY selection case, sorted.
  final List<String> commonActs;

  /// Canonical doctrine IDs engaged by EVERY selection case, sorted.
  final List<String> commonDoctrines;

  const SynthesisAggregate({
    required this.doctrines,
    required this.articles,
    required this.acts,
    required this.earliestYear,
    required this.latestYear,
    required this.totalHoldings,
    required this.totalRatios,
    required this.totalIssues,
    required this.commonArticles,
    required this.commonActs,
    required this.commonDoctrines,
  });

  /// Number of years between the latest and earliest judgment year, or null
  /// when fewer than two cases.
  int? get yearSpan {
    if (earliestYear == null || latestYear == null) return null;
    return latestYear! - earliestYear!;
  }

  Map<String, dynamic> toJson() => {
        'doctrines': doctrines,
        'articles': articles,
        'acts': acts,
        'earliestYear': earliestYear,
        'latestYear': latestYear,
        'totalHoldings': totalHoldings,
        'totalRatios': totalRatios,
        'totalIssues': totalIssues,
        'commonArticles': commonArticles,
        'commonActs': commonActs,
        'commonDoctrines': commonDoctrines,
      };

  factory SynthesisAggregate.fromJson(Map<String, dynamic> json) =>
      SynthesisAggregate(
        doctrines: (json['doctrines'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        articles: (json['articles'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        acts: (json['acts'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        earliestYear: (json['earliestYear'] as num?)?.toInt(),
        latestYear: (json['latestYear'] as num?)?.toInt(),
        totalHoldings: (json['totalHoldings'] as num?)?.toInt() ?? 0,
        totalRatios: (json['totalRatios'] as num?)?.toInt() ?? 0,
        totalIssues: (json['totalIssues'] as num?)?.toInt() ?? 0,
        commonArticles: (json['commonArticles'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        commonActs: (json['commonActs'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        commonDoctrines: (json['commonDoctrines'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  @override
  String toString() => 'SynthesisAggregate(${doctrines.length} doctrine(s), '
      '${articles.length} article(s), ${acts.length} act(s), '
      'span $earliestYear–$latestYear)';
}

/// A P9 discovery link between two synthesis members, with the P9 reasons that
/// establish it (reused verbatim from the discovery layer).
@immutable
class SynthesisDiscoveryLink {
  /// Source case of the discovery.
  final String sourceCaseId;

  /// Discovered (target) case, always within the synthesis selection.
  final String targetCaseId;

  /// P9 evidence-backed reasons for the discovery.
  final List<DiscoveryReason> reasons;

  const SynthesisDiscoveryLink({
    required this.sourceCaseId,
    required this.targetCaseId,
    required this.reasons,
  });

  Map<String, dynamic> toJson() => {
        'sourceCaseId': sourceCaseId,
        'targetCaseId': targetCaseId,
        'reasons': reasons.map((r) => r.toJson()).toList(),
      };

  factory SynthesisDiscoveryLink.fromJson(Map<String, dynamic> json) =>
      SynthesisDiscoveryLink(
        sourceCaseId: json['sourceCaseId'] as String? ?? '',
        targetCaseId: json['targetCaseId'] as String? ?? '',
        reasons: (json['reasons'] as List<dynamic>? ?? const [])
            .map((e) => DiscoveryReason.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SynthesisDiscoveryLink &&
          sourceCaseId == other.sourceCaseId &&
          targetCaseId == other.targetCaseId;

  @override
  int get hashCode => Object.hash(sourceCaseId, targetCaseId);
}

/// The deterministic, evidence-preserving synthesis of a selected set of
/// cases.
@immutable
class CaseSynthesis {
  /// Canonical IDs of the selection, in input order (de-duplicated).
  final List<String> caseIds;

  /// One entry per selection case, in [caseIds] order.
  final List<SynthesisCaseEntry> entries;

  /// Deterministic aggregate facts over the selection.
  final SynthesisAggregate aggregate;

  /// P5 case → case edges among the selection, in a deterministic order.
  final List<PrecedentGraphEdge> graphRelationships;

  /// P9 discovery links among the selection (reasons reused from P9).
  final List<SynthesisDiscoveryLink> discoveryLinks;

  /// Structural observations over the selection (e.g. chronological span).
  final List<StructuralObservation> observations;

  /// Input identifiers that did not resolve to a corpus case.
  final List<String> unresolvedCaseIds;

  const CaseSynthesis({
    required this.caseIds,
    required this.entries,
    required this.aggregate,
    required this.graphRelationships,
    required this.discoveryLinks,
    required this.observations,
    required this.unresolvedCaseIds,
  });

  /// True when no case could be resolved for synthesis.
  bool get isEmpty => caseIds.isEmpty;

  Map<String, dynamic> toJson() => {
        'caseIds': caseIds,
        'entries': entries.map((e) => e.toJson()).toList(),
        'aggregate': aggregate.toJson(),
        'graphRelationships':
            graphRelationships.map((e) => e.toJson()).toList(),
        'discoveryLinks': discoveryLinks.map((l) => l.toJson()).toList(),
        'observations': observations.map((o) => o.toJson()).toList(),
        'unresolvedCaseIds': unresolvedCaseIds,
      };

  factory CaseSynthesis.fromJson(Map<String, dynamic> json) => CaseSynthesis(
        caseIds: (json['caseIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        entries: (json['entries'] as List<dynamic>? ?? const [])
            .map((e) => SynthesisCaseEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        aggregate: SynthesisAggregate.fromJson(
            json['aggregate'] as Map<String, dynamic>? ?? const {}),
        graphRelationships:
            (json['graphRelationships'] as List<dynamic>? ?? const [])
                .map((e) => LegalGraphEdge.fromJson(e as Map<String, dynamic>))
                .whereType<PrecedentGraphEdge>()
                .toList(),
        discoveryLinks: (json['discoveryLinks'] as List<dynamic>? ?? const [])
            .map((e) =>
                SynthesisDiscoveryLink.fromJson(e as Map<String, dynamic>))
            .toList(),
        observations: (json['observations'] as List<dynamic>? ?? const [])
            .map((e) =>
                StructuralObservation.fromJson(e as Map<String, dynamic>))
            .toList(),
        unresolvedCaseIds:
            (json['unresolvedCaseIds'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
      );

  @override
  String toString() => 'CaseSynthesis(${caseIds.length} case(s), '
      '${graphRelationships.length} graph edge(s), '
      '${discoveryLinks.length} discovery link(s))';
}
