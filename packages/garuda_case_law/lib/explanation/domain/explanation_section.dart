/// Section models for the Evidence-Backed Case Explanation layer
/// (TITAN-KO-015.0 P11).
///
/// An explanation is a list of [ExplanationSection]s; each section is a list of
/// [ExplanationStatement]s. Every statement carries the canonical source
/// references and the provenance that establish it — nothing is presented
/// without a traceable origin, and nothing is invented (see
/// `P11_CASE_EXPLANATION.md`).
library;

import 'package:meta/meta.dart';

import 'explanation_enums.dart';

/// One presented, evidence-backed item within an explanation section.
///
/// [label] is a deterministic presentation label (e.g. `Holding 1`,
/// `Article 21`); [text] is the verbatim validated content; [sourceRefs] are
/// the canonical identifiers that establish the statement (never empty); and
/// [provenance] records which validated corpus/graph field the content traces
/// to (e.g. `p4:holdings`, `corpus:relatedArticles`).
@immutable
class ExplanationStatement {
  /// Deterministic presentation label (e.g. `Holding 1`, `Related case`).
  final String label;

  /// The presented content, verbatim from validated source data.
  final String text;

  /// Canonical identifiers that establish the statement. Never empty.
  final List<String> sourceRefs;

  /// Provenance of the content (e.g. `p4:holdings`, `graph:edgeId`).
  final String provenance;

  const ExplanationStatement({
    required this.label,
    required this.text,
    required this.sourceRefs,
    required this.provenance,
  }) : assert(sourceRefs.length > 0,
            'an explanation statement needs source references');

  Map<String, dynamic> toJson() => {
        'label': label,
        'text': text,
        'sourceRefs': sourceRefs,
        'provenance': provenance,
      };

  factory ExplanationStatement.fromJson(Map<String, dynamic> json) =>
      ExplanationStatement(
        label: json['label'] as String? ?? '',
        text: json['text'] as String? ?? '',
        sourceRefs: (json['sourceRefs'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        provenance: json['provenance'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExplanationStatement &&
          label == other.label &&
          text == other.text &&
          _listEquals(sourceRefs, other.sourceRefs) &&
          provenance == other.provenance;

  @override
  int get hashCode => Object.hash(label, text, provenance);

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// One section of a [CaseExplanation].
///
/// A section has a fixed [type] and a deterministic [title]. It is only
/// constructed from existing validated evidence; a section with no statements
/// is omitted rather than emitted empty. The aggregated [provenance] and
/// [references] are derived deterministically from the contained statements
/// (unique, sorted), so a consumer can validate traceability without walking
/// the statements.
@immutable
class ExplanationSection {
  /// Kind of section.
  final ExplanationSectionType type;

  /// Deterministic human-readable heading.
  final String title;

  /// The presented, evidence-backed statements.
  final List<ExplanationStatement> statements;

  const ExplanationSection({
    required this.type,
    required this.title,
    required this.statements,
  });

  /// Whether the section carries no presentable evidence.
  bool get isEmpty => statements.isEmpty;

  /// Unique provenance strings across the statements, sorted, joined by `;`.
  String get provenance {
    final seen = <String>{};
    final parts = <String>[];
    for (final s in statements) {
      for (final p in s.provenance.split(';')) {
        final t = p.trim();
        if (t.isNotEmpty && seen.add(t)) parts.add(t);
      }
    }
    parts.sort();
    return parts.join(';');
  }

  /// Unique canonical references across the statements, sorted.
  List<String> get references {
    final seen = <String>{};
    final refs = <String>[];
    for (final s in statements) {
      for (final r in s.sourceRefs) {
        if (r.isNotEmpty && seen.add(r)) refs.add(r);
      }
    }
    refs.sort();
    return List.unmodifiable(refs);
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        'statements': statements.map((s) => s.toJson()).toList(),
      };

  factory ExplanationSection.fromJson(Map<String, dynamic> json) =>
      ExplanationSection(
        type: ExplanationSectionTypeExtension.fromName(json['type'] as String?),
        title: json['title'] as String? ?? '',
        statements: (json['statements'] as List<dynamic>? ?? const [])
            .map((e) => ExplanationStatement.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExplanationSection &&
          type == other.type &&
          title == other.title &&
          _listEqualsStatements(statements, other.statements);

  @override
  int get hashCode => Object.hash(type, title);

  static bool _listEqualsStatements(
      List<ExplanationStatement> a, List<ExplanationStatement> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
