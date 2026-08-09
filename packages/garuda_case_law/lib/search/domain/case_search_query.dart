/// Case Law search query payload (TITAN-KO-015.0 P6).
///
/// A text [term] drives deterministic relevance scoring; an optional filter
/// set narrows the candidate pool. Structured lookups (`findByArticle`,
/// `findByJudge`, ...) are thin conveniences that build the same query.
library;

import 'package:meta/meta.dart';

import 'case_search_filters.dart';

/// Immutable search query for [CaseSearchEngine.search].
@immutable
class CaseSearchQuery {
  /// Free-text term scored across every searchable field of the corpus.
  ///
  /// Null or empty means "no text constraint" — with no filters the engine
  /// returns the full corpus ordered by the deterministic tie-breaker.
  final String? term;

  /// Maximum number of results to return (null = no limit).
  final int? limit;

  /// Orthogonal filters applied on top of [term].
  final CaseSearchFilters? filters;

  const CaseSearchQuery({
    this.term,
    this.limit,
    this.filters,
  });

  /// Whether no text and no filters are set (a "browse all" query).
  bool get isEmpty =>
      (term == null || term!.trim().isEmpty) &&
      (filters == null || filters!.isEmpty);

  Map<String, dynamic> toJson() => {
        if (term != null) 'term': term,
        if (limit != null) 'limit': limit,
        if (filters != null) 'filters': filters!.toJson(),
      };

  factory CaseSearchQuery.fromJson(Map<String, dynamic> json) =>
      CaseSearchQuery(
        term: json['term'] as String?,
        limit: json['limit'] as int?,
        filters: json['filters'] == null
            ? null
            : CaseSearchFilters.fromJson(
                json['filters'] as Map<String, dynamic>),
      );
}
