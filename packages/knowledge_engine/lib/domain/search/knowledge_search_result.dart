import 'package:meta/meta.dart';

import '../entities/knowledge_object.dart';

/// Immutable domain value object encapsulating search query execution results,
/// matching entities, total match count, applied filters, and execution statistics.
@immutable
class KnowledgeSearchResult {
  /// Paginated list of [KnowledgeObject] entities matching the query.
  final List<KnowledgeObject> matchedObjects;

  /// Convenience getter returning [matchedObjects].
  List<KnowledgeObject> get items => matchedObjects;

  /// Total number of matching entities discovered before pagination offset/limit.
  final int totalCount;

  /// Execution metrics payload (e.g. `executionTimeMs`, `returnedCount`, `rankingScoreCount`).
  final Map<String, dynamic> statistics;

  /// Summary payload of query parameters and criteria applied during evaluation.
  final Map<String, dynamic> appliedFilters;

  /// Constructs an immutable [KnowledgeSearchResult].
  KnowledgeSearchResult({
    required List<KnowledgeObject> matchedObjects,
    required this.totalCount,
    Map<String, dynamic> statistics = const {},
    Map<String, dynamic> appliedFilters = const {},
  })  : matchedObjects = List<KnowledgeObject>.unmodifiable(matchedObjects),
        statistics = Map<String, dynamic>.unmodifiable(statistics),
        appliedFilters = Map<String, dynamic>.unmodifiable(appliedFilters);

  /// Converts this [KnowledgeSearchResult] into a JSON-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'matchedObjects': matchedObjects.map((e) => e.toMap()).toList(),
      'totalCount': totalCount,
      'statistics': statistics,
      'appliedFilters': appliedFilters,
    };
  }

  /// Deserializes a [KnowledgeSearchResult] from a Map.
  factory KnowledgeSearchResult.fromMap(Map<String, dynamic> map) {
    return KnowledgeSearchResult(
      matchedObjects: (map['matchedObjects'] as List? ?? const [])
          .map((e) =>
              KnowledgeObject.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      totalCount: (map['totalCount'] as num?)?.toInt() ?? 0,
      statistics:
          Map<String, dynamic>.from(map['statistics'] as Map? ?? const {}),
      appliedFilters:
          Map<String, dynamic>.from(map['appliedFilters'] as Map? ?? const {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is KnowledgeSearchResult &&
        _listEquals(other.matchedObjects, matchedObjects) &&
        other.totalCount == totalCount &&
        _mapEquals(other.statistics, statistics) &&
        _mapEquals(other.appliedFilters, appliedFilters);
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(matchedObjects),
      totalCount,
      Object.hashAll(statistics.keys),
      Object.hashAll(statistics.values),
      Object.hashAll(appliedFilters.keys),
      Object.hashAll(appliedFilters.values),
    );
  }

  @override
  String toString() {
    return 'KnowledgeSearchResult(matchedObjects: ${matchedObjects.length}, totalCount: $totalCount)';
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
