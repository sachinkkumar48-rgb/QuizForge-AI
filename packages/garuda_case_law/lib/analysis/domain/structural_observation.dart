/// Structural observation model for the Evidence-Bounded Cross-Case Analysis
/// layer (TITAN-KO-015.0 P10).
///
/// A [StructuralObservation] is a *derived* statement over existing validated
/// data: it records what deterministic comparison safely shows (chronology,
/// graph edges, holding/ratio/issue/outcome differences) and always carries the
/// canonical references and provenance that establish it. It is never a legal
/// verdict — no similarity, overruling, refinement or extension claim is ever
/// emitted as an observation (see `P10_CROSS_CASE_ANALYSIS.md`).
library;

import 'package:meta/meta.dart';

import 'analysis_enums.dart';

/// An immutable, evidence-bounded structural observation.
@immutable
class StructuralObservation {
  /// Kind of deterministic observation.
  final StructuralObservationType type;

  /// Short human-readable statement (e.g. `KESAVANANDA (1973) precedes
  /// MINERVA_MILLS (1980)`).
  final String label;

  /// Canonical identifiers that establish the observation. Never empty.
  final List<String> references;

  /// Provenance of the derivation — which validated corpus field, graph edge
  /// or derived structural signal establishes it (e.g. `corpus:year`,
  /// `corpus:precedentsFollowed`, `p4:holdings`, `structural:comparison`).
  final String provenance;

  const StructuralObservation({
    required this.type,
    required this.label,
    required this.references,
    required this.provenance,
  }) : assert(
            references.length > 0, 'a structural observation needs references');

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'label': label,
        'references': references,
        'provenance': provenance,
      };

  factory StructuralObservation.fromJson(Map<String, dynamic> json) =>
      StructuralObservation(
        type: StructuralObservationType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => StructuralObservationType.chronologicalOrder,
        ),
        label: json['label'] as String? ?? '',
        references: (json['references'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        provenance: json['provenance'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StructuralObservation &&
          type == other.type &&
          label == other.label &&
          provenance == other.provenance &&
          _listEquals(references, other.references);

  @override
  int get hashCode =>
      Object.hash(type, label, provenance, Object.hashAll(references));

  @override
  String toString() => '[$type] $label (provenance: $provenance)';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
