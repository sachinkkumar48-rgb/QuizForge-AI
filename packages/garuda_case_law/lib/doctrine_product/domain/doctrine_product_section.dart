/// Section models for the Evidence-Backed Doctrine Knowledge Product layer
/// (TITAN-KO-015.0 P12).
///
/// A doctrine product is a list of [DoctrineSection]s; each section is a list
/// of [DoctrineStatement]s. Every statement carries the canonical source
/// references and the provenance that establish it — nothing is presented
/// without a traceable origin, and nothing is invented (see
/// `P12_DOCTRINE_KNOWLEDGE_PRODUCT.md`).
///
/// These models mirror the P11 `ExplanationSection` / `ExplanationStatement`
/// shape exactly; the section vocabulary is doctrine-shaped, so a distinct
/// section model (with [DoctrineSectionType]) is used rather than forcing
/// doctrine content into the case-explanation vocabulary.
library;

import 'package:meta/meta.dart';

import 'doctrine_product_enums.dart';

/// One presented, evidence-backed item within a doctrine section.
///
/// [label] is a deterministic presentation label (e.g. `Constituent case 1`,
/// `Article 21`); [text] is the verbatim validated content; [sourceRefs] are
/// the canonical identifiers that establish the statement (never empty); and
/// [provenance] records which validated corpus/graph field the content traces
/// to (e.g. `doctrine:BASIC_STRUCTURE.officialDefinition`,
/// `corpus:relatedArticles`, `p10:chronology`, `p5:caseDoctrineEdges`).
@immutable
class DoctrineStatement {
  /// Deterministic presentation label (e.g. `Constituent case 1`).
  final String label;

  /// The presented content, verbatim from validated source data.
  final String text;

  /// Canonical identifiers that establish the statement. Never empty.
  final List<String> sourceRefs;

  /// Provenance of the content (e.g. `doctrine:BASIC_STRUCTURE.originatingCase`).
  final String provenance;

  const DoctrineStatement({
    required this.label,
    required this.text,
    required this.sourceRefs,
    required this.provenance,
  }) : assert(sourceRefs.length > 0,
            'a doctrine statement needs source references');

  Map<String, dynamic> toJson() => {
        'label': label,
        'text': text,
        'sourceRefs': sourceRefs,
        'provenance': provenance,
      };

  factory DoctrineStatement.fromJson(Map<String, dynamic> json) =>
      DoctrineStatement(
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
      other is DoctrineStatement &&
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

/// One section of a [DoctrineKnowledgeProduct].
///
/// A section has a fixed [type] and a deterministic [title]. It is only
/// constructed from existing validated evidence; a section with no statements
/// is omitted rather than emitted empty. The aggregated [provenance] and
/// [references] are derived deterministically from the contained statements
/// (unique, sorted), so a consumer can validate traceability without walking
/// the statements.
@immutable
class DoctrineSection {
  /// Kind of section.
  final DoctrineSectionType type;

  /// Deterministic human-readable heading.
  final String title;

  /// The presented, evidence-backed statements.
  final List<DoctrineStatement> statements;

  const DoctrineSection({
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

  factory DoctrineSection.fromJson(Map<String, dynamic> json) =>
      DoctrineSection(
        type: DoctrineSectionTypeExtension.fromName(json['type'] as String?),
        title: json['title'] as String? ?? '',
        statements: (json['statements'] as List<dynamic>? ?? const [])
            .map((e) =>
                DoctrineStatement.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctrineSection &&
          type == other.type &&
          title == other.title &&
          _listEqualsStatements(statements, other.statements);

  @override
  int get hashCode => Object.hash(type, title);

  static bool _listEqualsStatements(
      List<DoctrineStatement> a, List<DoctrineStatement> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
