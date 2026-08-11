/// Section models for the Evidence-Backed Statute / Article Knowledge Product
/// layer (TITAN-KO-015.0 P13).
///
/// A statute product is a list of [StatuteSection]s; each section is a list of
/// [StatuteStatement]s. Every statement carries the canonical source references
/// and the provenance that establish it — nothing is presented without a
/// traceable origin, and nothing is invented (see
/// `P13_STATUTE_KNOWLEDGE_PRODUCT.md`).
///
/// These models mirror the P12 `DoctrineSection` / `DoctrineStatement` shape
/// exactly; the section vocabulary is provision-shaped, so a distinct section
/// model (with [StatuteSectionType]) is used rather than forcing statute
/// content into the doctrine vocabulary.
library;

import 'package:meta/meta.dart';

import 'statute_product_enums.dart';

/// One presented, evidence-backed item within a statute-product section.
///
/// [label] is a deterministic presentation label (e.g. `Associated case 1`,
/// `Article 21A`); [text] is the verbatim validated content; [sourceRefs] are
/// the canonical identifiers that establish the statement (never empty); and
/// [provenance] records which validated corpus/graph field the content traces
/// to (e.g. `corpus:relatedArticles`, `p5:caseDoctrineEdges`,
/// `p10:chronology`, `constitution:ArticleKnowledgeObject`).
@immutable
class StatuteStatement {
  /// Deterministic presentation label (e.g. `Associated case 1`).
  final String label;

  /// The presented content, verbatim from validated source data.
  final String text;

  /// Canonical identifiers that establish the statement. Never empty.
  final List<String> sourceRefs;

  /// Provenance of the content (e.g. `corpus:relatedArticles`).
  final String provenance;

  const StatuteStatement({
    required this.label,
    required this.text,
    required this.sourceRefs,
    required this.provenance,
  }) : assert(sourceRefs.length > 0,
            'a statute statement needs source references');

  Map<String, dynamic> toJson() => {
        'label': label,
        'text': text,
        'sourceRefs': sourceRefs,
        'provenance': provenance,
      };

  factory StatuteStatement.fromJson(Map<String, dynamic> json) =>
      StatuteStatement(
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
      other is StatuteStatement &&
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

/// One section of a [StatuteKnowledgeProduct].
///
/// A section has a fixed [type] and a deterministic [title]. It is only
/// constructed from existing validated evidence; a section with no statements
/// is omitted rather than emitted empty. The aggregated [provenance] and
/// [references] are derived deterministically from the contained statements
/// (unique, sorted), so a consumer can validate traceability without walking
/// the statements.
@immutable
class StatuteSection {
  /// Kind of section.
  final StatuteSectionType type;

  /// Deterministic heading for the section.
  final String title;

  /// The evidence-backed statements of the section, in fixed deterministic
  /// order.
  final List<StatuteStatement> statements;

  const StatuteSection({
    required this.type,
    required this.title,
    required this.statements,
  }) : assert(statements.length > 0,
            'a statute section needs at least one statement');

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

  /// Whether the section contains a statement whose label equals [label].
  bool hasLabel(String label) {
    for (final s in statements) {
      if (s.label == label) return true;
    }
    return false;
  }

  /// The first statement with label [label], or null when absent.
  StatuteStatement? statementOf(String label) {
    for (final s in statements) {
      if (s.label == label) return s;
    }
    return null;
  }

  /// The statement text with label [label], or '' when absent.
  String textOf(String label) => statementOf(label)?.text ?? '';

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        'statements': statements.map((s) => s.toJson()).toList(),
      };

  factory StatuteSection.fromJson(Map<String, dynamic> json) =>
      StatuteSection(
        type: StatuteSectionTypeExtension.fromName(json['type'] as String?),
        title: json['title'] as String? ?? '',
        statements: (json['statements'] as List<dynamic>? ?? const [])
            .map((e) => StatuteStatement.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatuteSection &&
          type == other.type &&
          title == other.title &&
          _statementListsEqual(statements, other.statements);

  @override
  int get hashCode => Object.hash(type, title);

  static bool _statementListsEqual(
      List<StatuteStatement> a, List<StatuteStatement> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
