import 'package:meta/meta.dart';

import 'search_scope.dart';

/// Immutable domain model representing a structured user search query.
@immutable
class SearchQuery {
  final String rawQuery;
  final Set<SearchScope> scopes;
  final bool exactMatchOnly;
  final bool includeSynonyms;
  final bool expandRelatedConcepts;
  final bool fuzzyMatch;
  final Map<String, dynamic> filters;
  final int limit;

  SearchQuery({
    required this.rawQuery,
    Set<SearchScope>? scopes,
    this.exactMatchOnly = false,
    this.includeSynonyms = true,
    this.expandRelatedConcepts = true,
    this.fuzzyMatch = true,
    Map<String, dynamic>? filters,
    this.limit = 20,
  })  : scopes =
            Set<SearchScope>.unmodifiable(scopes ?? SearchScope.values.toSet()),
        filters = Map<String, dynamic>.unmodifiable(filters ?? {});

  SearchQuery copyWith({
    String? rawQuery,
    Set<SearchScope>? scopes,
    bool? exactMatchOnly,
    bool? includeSynonyms,
    bool? expandRelatedConcepts,
    bool? fuzzyMatch,
    Map<String, dynamic>? filters,
    int? limit,
  }) {
    return SearchQuery(
      rawQuery: rawQuery ?? this.rawQuery,
      scopes: scopes ?? this.scopes,
      exactMatchOnly: exactMatchOnly ?? this.exactMatchOnly,
      includeSynonyms: includeSynonyms ?? this.includeSynonyms,
      expandRelatedConcepts:
          expandRelatedConcepts ?? this.expandRelatedConcepts,
      fuzzyMatch: fuzzyMatch ?? this.fuzzyMatch,
      filters: filters ?? this.filters,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toJson() => {
        'rawQuery': rawQuery,
        'scopes': scopes.map((s) => s.name).toList(),
        'exactMatchOnly': exactMatchOnly,
        'includeSynonyms': includeSynonyms,
        'expandRelatedConcepts': expandRelatedConcepts,
        'fuzzyMatch': fuzzyMatch,
        'filters': filters,
        'limit': limit,
      };

  factory SearchQuery.fromJson(Map<String, dynamic> json) {
    final scopesList = (json['scopes'] as List? ?? [])
        .map((s) => SearchScope.values.firstWhere(
              (e) => e.name == s,
              orElse: () => SearchScope.notes,
            ))
        .toSet();

    return SearchQuery(
      rawQuery: json['rawQuery'] as String? ?? '',
      scopes: scopesList.isEmpty ? SearchScope.values.toSet() : scopesList,
      exactMatchOnly: json['exactMatchOnly'] as bool? ?? false,
      includeSynonyms: json['includeSynonyms'] as bool? ?? true,
      expandRelatedConcepts: json['expandRelatedConcepts'] as bool? ?? true,
      fuzzyMatch: json['fuzzyMatch'] as bool? ?? true,
      filters: Map<String, dynamic>.from(json['filters'] as Map? ?? {}),
      limit: json['limit'] as int? ?? 20,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchQuery &&
          runtimeType == other.runtimeType &&
          rawQuery == other.rawQuery &&
          exactMatchOnly == other.exactMatchOnly &&
          includeSynonyms == other.includeSynonyms &&
          expandRelatedConcepts == other.expandRelatedConcepts &&
          fuzzyMatch == other.fuzzyMatch &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(
        rawQuery,
        exactMatchOnly,
        includeSynonyms,
        expandRelatedConcepts,
        fuzzyMatch,
        limit,
      );
}
