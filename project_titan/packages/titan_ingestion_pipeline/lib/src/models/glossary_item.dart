import 'package:meta/meta.dart';

/// Domain model representing a term and definition extracted for the lesson glossary.
@immutable
class GlossaryItem {
  final String term;
  final String definition;
  final String domain;
  final List<String> synonyms;

  GlossaryItem({
    required this.term,
    required this.definition,
    this.domain = 'general',
    List<String>? synonyms,
  }) : synonyms = List.unmodifiable(synonyms ?? const []);

  Map<String, dynamic> toJson() => {
        'term': term,
        'definition': definition,
        'domain': domain,
        'synonyms': synonyms,
      };

  factory GlossaryItem.fromJson(Map<String, dynamic> json) => GlossaryItem(
        term: json['term'] as String,
        definition: json['definition'] as String,
        domain: json['domain'] as String? ?? 'general',
        synonyms: List<String>.from(json['synonyms'] as List? ?? []),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlossaryItem &&
          runtimeType == other.runtimeType &&
          term == other.term &&
          definition == other.definition;

  @override
  int get hashCode => Object.hash(term, definition);
}
