/// Section models for the Evidence-Bounded UPSC Topic Knowledge Product layer
/// (TITAN-KO-015.0 P14).
///
/// A topic product is a list of [TopicSection]s; each section is a list of
/// [TopicStatement]s. Every statement carries the canonical source references
/// and the provenance that establish it — nothing is presented without a
/// traceable origin, and nothing is invented (see
/// `P14_TOPIC_KNOWLEDGE_PRODUCT.md`).
///
/// These models mirror the P11/P12/P13 `*Section` / `*Statement` shape exactly;
/// the section vocabulary is topic-shaped, so a distinct section model (with
/// [TopicSectionType]) is used rather than forcing topic content into the
/// case/doctrine/statute vocabulary.
library;

import 'package:meta/meta.dart';

import 'topic_product_enums.dart';

/// One presented, evidence-backed item within a topic section.
///
/// [label] is a deterministic presentation label (e.g. `Member case 1`,
/// `Amending power`); [text] is the verbatim validated content; [sourceRefs]
/// are the canonical identifiers that establish the statement (never empty);
/// and [provenance] records which validated corpus/graph/product field the
/// content traces to (e.g. `p4:upscIntelligence.mainsThemes`,
/// `p14:syllabusConfig.v3`, `p11:CaseExplanation`, `p12:DoctrineKnowledgeProduct`,
/// `p13:StatuteKnowledgeProduct`).
@immutable
class TopicStatement {
  /// Deterministic presentation label (e.g. `Member case 1`).
  final String label;

  /// The presented content, verbatim from validated source data.
  final String text;

  /// Canonical identifiers that establish the statement. Never empty.
  final List<String> sourceRefs;

  /// Provenance of the content (e.g. `p4:upscIntelligence.mainsThemes`).
  final String provenance;

  const TopicStatement({
    required this.label,
    required this.text,
    required this.sourceRefs,
    required this.provenance,
  }) : assert(
            sourceRefs.length > 0, 'a topic statement needs source references');

  Map<String, dynamic> toJson() => {
        'label': label,
        'text': text,
        'sourceRefs': sourceRefs,
        'provenance': provenance,
      };

  factory TopicStatement.fromJson(Map<String, dynamic> json) => TopicStatement(
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
      other is TopicStatement &&
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

/// One section of a [TopicKnowledgeProduct].
///
/// A section has a fixed [type] and a deterministic [title]. It is only
/// constructed from existing validated evidence; a section with no statements
/// is omitted rather than emitted empty. The aggregated [provenance] and
/// [references] are derived deterministically from the contained statements
/// (unique, sorted), so a consumer can validate traceability without walking
/// the statements.
@immutable
class TopicSection {
  /// Kind of section.
  final TopicSectionType type;

  /// Deterministic human-readable heading.
  final String title;

  /// The presented, evidence-backed statements.
  final List<TopicStatement> statements;

  const TopicSection({
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

  factory TopicSection.fromJson(Map<String, dynamic> json) => TopicSection(
        type: TopicSectionType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => TopicSectionType.identity,
        ),
        title: json['title'] as String? ?? '',
        statements: (json['statements'] as List<dynamic>? ?? const [])
            .map((e) => TopicStatement.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicSection &&
          type == other.type &&
          title == other.title &&
          _statementListEquals(statements, other.statements);

  @override
  int get hashCode => Object.hash(type, title);

  static bool _statementListEquals(
      List<TopicStatement> a, List<TopicStatement> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
