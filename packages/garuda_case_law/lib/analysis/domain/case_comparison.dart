/// Case-comparison models for the Evidence-Bounded Cross-Case Analysis layer
/// (TITAN-KO-015.0 P10).
///
/// A comparison of two or more existing cases separates *factual source data*
/// ([CaseComparisonItem] — what each validated P3/P4 record says) from
/// *structural observation* ([SharedAttribute] and [StructuralObservation] —
/// what deterministic comparison can safely derive). P10 never claims legal
/// similarity; shared structured attributes are exposed explicitly, never as a
/// "legally similar" verdict.
library;

import 'package:meta/meta.dart';

import '../../domain/entities/case_knowledge_object.dart';
import 'analysis_enums.dart';
import 'structural_observation.dart';

/// A structured attribute that at least two compared cases share, recorded
/// explicitly with the cases that carry it and the provenance that establishes
/// it.
@immutable
class SharedAttribute {
  /// Kind of shared attribute (article / act / doctrine / judge).
  final SharedAttributeKind kind;

  /// Canonical comparable value (normalized article key `21`, normalized Act
  /// name, canonical doctrine ID, or judge name).
  final String value;

  /// Human-readable original form (e.g. `Article 21`,
  /// `Indian Penal Code, 1860`, `Basic Structure`).
  final String displayValue;

  /// Canonical IDs of the cases that carry this attribute, sorted ascending.
  final List<String> caseIds;

  /// Provenance of the shared attribute (e.g. `corpus:relatedArticles`,
  /// `corpus:relatedActs`, `doctrine:BASIC_STRUCTURE.landmarkCases`).
  final String provenance;

  const SharedAttribute({
    required this.kind,
    required this.value,
    required this.displayValue,
    required this.caseIds,
    required this.provenance,
  }) : assert(caseIds.length >= 2,
            'a shared attribute requires at least two cases');

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'value': value,
        'displayValue': displayValue,
        'caseIds': caseIds,
        'provenance': provenance,
      };

  factory SharedAttribute.fromJson(Map<String, dynamic> json) =>
      SharedAttribute(
        kind: SharedAttributeKind.values.firstWhere(
          (e) => e.name == json['kind'],
          orElse: () => SharedAttributeKind.article,
        ),
        value: json['value'] as String? ?? '',
        displayValue: json['displayValue'] as String? ?? '',
        caseIds: (json['caseIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        provenance: json['provenance'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedAttribute &&
          kind == other.kind &&
          value == other.value &&
          _listEquals(caseIds, other.caseIds) &&
          provenance == other.provenance;

  @override
  int get hashCode =>
      Object.hash(kind, value, provenance, Object.hashAll(caseIds));

  @override
  String toString() => 'SharedAttribute(${kind.name}: $value)';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The factual source data of one case participating in a comparison — what
/// the validated P3 corpus record and P4 Judgment Intelligence actually say.
///
/// Text fields are extracted from P4 where present and never regenerated;
/// P3 fields stand in only as the recorded record when P4 intelligence is
/// absent (see [hasIntelligence]).
@immutable
class CaseComparisonItem {
  /// Canonical corpus case ID.
  final String caseId;

  /// Display case name.
  final String caseName;

  /// Reporter citation of the record.
  final String citation;

  /// Judgment year.
  final int year;

  /// Bench description from the P3 record.
  final String bench;

  /// Judge names from the P3 record (sorted, de-duplicated).
  final List<String> judges;

  /// P4 holding texts (`JudgmentHolding.holding`). Empty when no P4
  /// intelligence.
  final List<String> holdings;

  /// P4 ratio texts (`JudgmentRatio.ratio`). Empty when no P4 intelligence.
  final List<String> ratios;

  /// P4 issue texts (`JudgmentIssue.issue`). Empty when no P4 intelligence.
  final List<String> issues;

  /// P4 outcome disposition name (`JudgmentOutcome.disposition`). Empty when
  /// no P4 outcome.
  final String outcome;

  /// P4 constitutional significance; falls back to the P3 record field.
  final String significance;

  /// Normalized constitutional-article keys from P3 `relatedArticles`, sorted.
  final List<String> articles;

  /// Normalized Act names from P3 `relatedActs`, sorted.
  final List<String> acts;

  /// Canonical doctrine IDs engaged by the case (P5 case → doctrine edges),
  /// sorted.
  final List<String> doctrines;

  /// Whether P4 Judgment Intelligence was present on the record.
  final bool hasIntelligence;

  /// Evidence IDs on the validated record.
  final List<String> evidenceIds;

  /// Provenance of the extracted data (which P3/P4 sources were read).
  final String provenance;

  /// The full validated case record (never fabricated).
  final CaseKnowledgeObject caseObject;

  const CaseComparisonItem({
    required this.caseId,
    required this.caseName,
    required this.citation,
    required this.year,
    required this.bench,
    required this.judges,
    required this.holdings,
    required this.ratios,
    required this.issues,
    required this.outcome,
    required this.significance,
    required this.articles,
    required this.acts,
    required this.doctrines,
    required this.hasIntelligence,
    required this.evidenceIds,
    required this.provenance,
    required this.caseObject,
  });

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'caseName': caseName,
        'citation': citation,
        'year': year,
        'bench': bench,
        'judges': judges,
        'holdings': holdings,
        'ratios': ratios,
        'issues': issues,
        'outcome': outcome,
        'significance': significance,
        'articles': articles,
        'acts': acts,
        'doctrines': doctrines,
        'hasIntelligence': hasIntelligence,
        'evidenceIds': evidenceIds,
        'provenance': provenance,
        'caseObject': caseObject.toJson(),
      };

  factory CaseComparisonItem.fromJson(Map<String, dynamic> json) =>
      CaseComparisonItem(
        caseId: json['caseId'] as String? ?? '',
        caseName: json['caseName'] as String? ?? '',
        citation: json['citation'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? 0,
        bench: json['bench'] as String? ?? '',
        judges: (json['judges'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
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
        articles: (json['articles'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        acts: (json['acts'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        doctrines: (json['doctrines'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        hasIntelligence: json['hasIntelligence'] as bool? ?? false,
        evidenceIds: (json['evidenceIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        provenance: json['provenance'] as String? ?? '',
        caseObject: CaseKnowledgeObject.fromJson(
            json['caseObject'] as Map<String, dynamic>),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseComparisonItem && caseId == other.caseId;

  @override
  int get hashCode => caseId.hashCode;
}

/// The deterministic result of comparing two or more existing cases.
///
/// [items] carry each case's factual source data; [sharedAttributes] and
/// [observations] carry only structural, evidence-bounded derivations. The
/// boundary between *what the evidence says* and *what the system observes
/// structurally* is explicit.
@immutable
class CaseComparisonResult {
  /// Canonical IDs of the compared cases, in input order (de-duplicated).
  final List<String> caseIds;

  /// One factual source-data item per compared case, in [caseIds] order.
  final List<CaseComparisonItem> items;

  /// Structured attributes shared by at least two compared cases, in a
  /// deterministic order.
  final List<SharedAttribute> sharedAttributes;

  /// Structural observations (chronology, graph edges, differences), in a
  /// deterministic order.
  final List<StructuralObservation> observations;

  /// Input identifiers that did not resolve to a corpus case (never
  /// fabricated into a comparison).
  final List<String> unresolvedCaseIds;

  const CaseComparisonResult({
    required this.caseIds,
    required this.items,
    required this.sharedAttributes,
    required this.observations,
    required this.unresolvedCaseIds,
  });

  /// True when no case could be resolved for comparison.
  bool get isEmpty => caseIds.isEmpty;

  Map<String, dynamic> toJson() => {
        'caseIds': caseIds,
        'items': items.map((i) => i.toJson()).toList(),
        'sharedAttributes': sharedAttributes.map((s) => s.toJson()).toList(),
        'observations': observations.map((o) => o.toJson()).toList(),
        'unresolvedCaseIds': unresolvedCaseIds,
      };

  factory CaseComparisonResult.fromJson(Map<String, dynamic> json) =>
      CaseComparisonResult(
        caseIds: (json['caseIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => CaseComparisonItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        sharedAttributes:
            (json['sharedAttributes'] as List<dynamic>? ?? const [])
                .map((e) => SharedAttribute.fromJson(e as Map<String, dynamic>))
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
  String toString() => 'CaseComparisonResult(${caseIds.length} case(s), '
      '${sharedAttributes.length} shared, ${observations.length} observations)';
}
