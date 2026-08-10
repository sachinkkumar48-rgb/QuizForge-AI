/// CaseExplanation model for the Evidence-Backed Case Explanation layer
/// (TITAN-KO-015.0 P11).
///
/// A deterministic, immutable, provenance-preserving knowledge product for one
/// canonical case. It re-presents existing validated P3–P10 evidence as a
/// structured, human-readable explanation: identity and overview from P3,
/// issues/holdings/reasoning/outcome/significance/UPSC from P4, doctrines and
/// precedent context from P5, related cases from P9, and cross-case context
/// from P10. It never invents legal meaning — every statement traces to an
/// existing validated source (see `P11_CASE_EXPLANATION.md`).
library;

import 'package:meta/meta.dart';

import 'explanation_enums.dart';
import 'explanation_section.dart';

/// An immutable evidence-backed explanation of one canonical case.
@immutable
class CaseExplanation {
  /// Fixed marker of this knowledge-product kind.
  static const String explanationKind = 'evidence-backed-case-explanation';

  /// Canonical corpus case ID.
  final String caseId;

  /// Display case name.
  final String caseName;

  /// Present sections in fixed deterministic order. A section is present only
  /// when validated evidence exists; missing data is represented by an absent
  /// section, never by fabricated content.
  final List<ExplanationSection> sections;

  const CaseExplanation({
    required this.caseId,
    required this.caseName,
    required this.sections,
  });

  /// Whether the explanation carries no presentable sections.
  bool get isEmpty => sections.isEmpty;

  /// The section of [type], or null when absent (missing data).
  ExplanationSection? sectionOf(ExplanationSectionType type) {
    for (final s in sections) {
      if (s.type == type) return s;
    }
    return null;
  }

  /// Whether [type] is present in this explanation.
  bool hasSection(ExplanationSectionType type) => sectionOf(type) != null;

  /// Unique canonical source identifiers referenced anywhere in the
  /// explanation, including the case's own ID, sorted.
  ///
  /// Identifiers are the raw canonical keys carried by statement references —
  /// case IDs, doctrine IDs, edge IDs (`e:...`), holding IDs, evidence IDs and
  /// article keys — so this is NOT a list of case IDs. Consumers that need only
  /// the referenced *cases* must filter against the validated corpus via
  /// `CaseExplanationService.referencedCaseIds` / `otherCaseIds`.
  List<String> get referencedIds {
    final seen = <String>{caseId};
    final out = <String>[caseId];
    for (final s in sections) {
      for (final r in s.references) {
        if (seen.add(r)) out.add(r);
      }
    }
    out.sort();
    return List.unmodifiable(out);
  }

  Map<String, dynamic> toJson() => {
        'explanationKind': explanationKind,
        'caseId': caseId,
        'caseName': caseName,
        'sections': sections.map((s) => s.toJson()).toList(),
      };

  factory CaseExplanation.fromJson(Map<String, dynamic> json) =>
      CaseExplanation(
        caseId: json['caseId'] as String? ?? '',
        caseName: json['caseName'] as String? ?? '',
        sections: (json['sections'] as List<dynamic>? ?? const [])
            .map((e) => ExplanationSection.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseExplanation &&
          caseId == other.caseId &&
          caseName == other.caseName &&
          _listEquals(sections, other.sections);

  @override
  int get hashCode => Object.hash(caseId, caseName);

  @override
  String toString() =>
      'CaseExplanation($caseId, ${sections.map((s) => s.type.name).join(', ')})';

  static bool _listEquals(
      List<ExplanationSection> a, List<ExplanationSection> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
