/// Case Law search suggestion model (TITAN-KO-015.0 P6).
///
/// A lightweight autocomplete suggestion drawn from real corpus values. Every
/// suggestion names the source kind and the case IDs it resolves to, so the
/// UI can turn a suggestion directly into a search without guessing.
library;

import 'package:meta/meta.dart';

/// The vocabulary kind a [CaseSearchSuggestion] was drawn from.
enum CaseSearchSuggestionKind {
  caseName,
  alias,
  doctrine,
  article,
  act,
  judge,
}

extension CaseSearchSuggestionKindExtension on CaseSearchSuggestionKind {
  String get displayName => switch (this) {
        CaseSearchSuggestionKind.caseName => 'Case',
        CaseSearchSuggestionKind.alias => 'Alias',
        CaseSearchSuggestionKind.doctrine => 'Doctrine',
        CaseSearchSuggestionKind.article => 'Article',
        CaseSearchSuggestionKind.act => 'Act',
        CaseSearchSuggestionKind.judge => 'Judge',
      };
}

/// One deduplicated autocomplete suggestion.
@immutable
class CaseSearchSuggestion {
  /// The suggested term (original casing of its first corpus occurrence).
  final String term;

  /// Normalized key used for prefix matching (may differ from [term] for
  /// article keys, e.g. term `Article 21` ↔ key `21`).
  final String normalizedKey;

  /// Vocabulary kind the term belongs to.
  final CaseSearchSuggestionKind kind;

  /// Corpus case IDs that reference this term (sorted, de-duplicated).
  final List<String> caseIds;

  /// How many corpus cases reference the term (ranking signal).
  final int occurrenceCount;

  const CaseSearchSuggestion({
    required this.term,
    required this.normalizedKey,
    required this.kind,
    required this.caseIds,
    required this.occurrenceCount,
  });

  Map<String, dynamic> toJson() => {
        'term': term,
        'normalizedKey': normalizedKey,
        'kind': kind.name,
        'caseIds': caseIds,
        'occurrenceCount': occurrenceCount,
      };

  factory CaseSearchSuggestion.fromJson(Map<String, dynamic> json) =>
      CaseSearchSuggestion(
        term: json['term'] as String? ?? '',
        normalizedKey: json['normalizedKey'] as String? ?? '',
        kind: CaseSearchSuggestionKind.values.firstWhere(
          (e) => e.name == json['kind'],
          orElse: () => CaseSearchSuggestionKind.caseName,
        ),
        caseIds: (json['caseIds'] as List? ?? const []).cast<String>(),
        occurrenceCount: (json['occurrenceCount'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseSearchSuggestion &&
          term == other.term &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(term, kind);

  @override
  String toString() => 'CaseSearchSuggestion(${kind.name}:$term)';
}
