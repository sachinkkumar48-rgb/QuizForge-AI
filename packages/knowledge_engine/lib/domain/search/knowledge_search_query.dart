import 'package:meta/meta.dart';

import '../value_objects/knowledge_type.dart';
import '../value_objects/relationship_type.dart';

/// Available sorting modes for search queries in the TITAN Knowledge Intelligence Engine.
enum SearchSortOrder {
  /// Ranks results by relevance score calculated by [SearchRankingStrategy].
  relevance,

  /// Sorts results by creation date descending (newest first).
  newestFirst,

  /// Sorts results by creation date ascending (oldest first).
  oldestFirst,

  /// Sorts results alphabetically by title A to Z.
  titleAscending,

  /// Sorts results alphabetically by title Z to A.
  titleDescending,
}

/// Immutable value object specifying search, filtering, sorting, and pagination criteria
/// for querying [KnowledgeObject] entities across TITAN platform consumers.
@immutable
class KnowledgeSearchQuery {
  /// Optional free text query string matching title, summary, subjects, topics, or keywords.
  final String? freeText;

  /// Optional filter restricting results to specific subject domain tags.
  final List<String> subjects;

  /// Optional filter restricting results to specific topic tags.
  final List<String> topics;

  /// Optional filter restricting results to specific [KnowledgeType] categories.
  final List<KnowledgeType> knowledgeTypes;

  /// Optional filter restricting graph relationship edge lookups to [RelationshipType] categories.
  final List<RelationshipType> relationshipTypes;

  /// Optional filter restricting results to specific indexing tags or keywords.
  final List<String> tags;

  /// Optional filter restricting results to a ISO language code (e.g. 'en', 'hi').
  final String? language;

  /// Maximum number of matching objects to return in a single page (must be > 0).
  final int limit;

  /// Number of matching objects to skip for pagination (must be >= 0).
  final int offset;

  /// Sorting mode applied to the returned results.
  final SearchSortOrder sortOrder;

  /// Extensible key-value filter map for consumer-specific query attributes.
  final Map<String, dynamic> filters;

  /// Constructs an immutable [KnowledgeSearchQuery].
  KnowledgeSearchQuery({
    this.freeText,
    List<String> subjects = const [],
    List<String> topics = const [],
    List<KnowledgeType> knowledgeTypes = const [],
    List<RelationshipType> relationshipTypes = const [],
    List<String> tags = const [],
    this.language,
    this.limit = 20,
    this.offset = 0,
    this.sortOrder = SearchSortOrder.relevance,
    Map<String, dynamic> filters = const {},
  })  : assert(limit > 0, 'limit must be greater than 0'),
        assert(offset >= 0, 'offset must be non-negative'),
        subjects = List<String>.unmodifiable(subjects),
        topics = List<String>.unmodifiable(topics),
        knowledgeTypes = List<KnowledgeType>.unmodifiable(knowledgeTypes),
        relationshipTypes =
            List<RelationshipType>.unmodifiable(relationshipTypes),
        tags = List<String>.unmodifiable(tags),
        filters = Map<String, dynamic>.unmodifiable(filters);

  /// Creates a copy of this [KnowledgeSearchQuery] with updated parameters.
  KnowledgeSearchQuery copyWith({
    String? freeText,
    List<String>? subjects,
    List<String>? topics,
    List<KnowledgeType>? knowledgeTypes,
    List<RelationshipType>? relationshipTypes,
    List<String>? tags,
    String? language,
    int? limit,
    int? offset,
    SearchSortOrder? sortOrder,
    Map<String, dynamic>? filters,
  }) {
    return KnowledgeSearchQuery(
      freeText: freeText ?? this.freeText,
      subjects: subjects ?? this.subjects,
      topics: topics ?? this.topics,
      knowledgeTypes: knowledgeTypes ?? this.knowledgeTypes,
      relationshipTypes: relationshipTypes ?? this.relationshipTypes,
      tags: tags ?? this.tags,
      language: language ?? this.language,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      sortOrder: sortOrder ?? this.sortOrder,
      filters: filters ?? this.filters,
    );
  }

  /// Converts this [KnowledgeSearchQuery] into a JSON-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'freeText': freeText,
      'subjects': subjects,
      'topics': topics,
      'knowledgeTypes': knowledgeTypes.map((e) => e.name).toList(),
      'relationshipTypes': relationshipTypes.map((e) => e.name).toList(),
      'tags': tags,
      'language': language,
      'limit': limit,
      'offset': offset,
      'sortOrder': sortOrder.name,
      'filters': filters,
    };
  }

  /// Deserializes a [KnowledgeSearchQuery] from a Map.
  factory KnowledgeSearchQuery.fromMap(Map<String, dynamic> map) {
    return KnowledgeSearchQuery(
      freeText: map['freeText'] as String?,
      subjects: List<String>.from(map['subjects'] as List? ?? const []),
      topics: List<String>.from(map['topics'] as List? ?? const []),
      knowledgeTypes: (map['knowledgeTypes'] as List? ?? const [])
          .map((e) => KnowledgeType.values.firstWhere(
                (kt) => kt.name == e,
                orElse: () => KnowledgeType.pdf,
              ))
          .toList(),
      relationshipTypes: (map['relationshipTypes'] as List? ?? const [])
          .map((e) => RelationshipType.values.firstWhere(
                (rt) => rt.name == e,
                orElse: () => RelationshipType.relatedTo,
              ))
          .toList(),
      tags: List<String>.from(map['tags'] as List? ?? const []),
      language: map['language'] as String?,
      limit: (map['limit'] as num?)?.toInt() ?? 20,
      offset: (map['offset'] as num?)?.toInt() ?? 0,
      sortOrder: SearchSortOrder.values.firstWhere(
        (e) => e.name == map['sortOrder'],
        orElse: () => SearchSortOrder.relevance,
      ),
      filters: Map<String, dynamic>.from(map['filters'] as Map? ?? const {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is KnowledgeSearchQuery &&
        other.freeText == freeText &&
        _listEquals(other.subjects, subjects) &&
        _listEquals(other.topics, topics) &&
        _listEquals(other.knowledgeTypes, knowledgeTypes) &&
        _listEquals(other.relationshipTypes, relationshipTypes) &&
        _listEquals(other.tags, tags) &&
        other.language == language &&
        other.limit == limit &&
        other.offset == offset &&
        other.sortOrder == sortOrder &&
        _mapEquals(other.filters, filters);
  }

  @override
  int get hashCode {
    return Object.hash(
      freeText,
      Object.hashAll(subjects),
      Object.hashAll(topics),
      Object.hashAll(knowledgeTypes),
      Object.hashAll(relationshipTypes),
      Object.hashAll(tags),
      language,
      limit,
      offset,
      sortOrder,
      Object.hashAll(filters.keys),
      Object.hashAll(filters.values),
    );
  }

  @override
  String toString() {
    return 'KnowledgeSearchQuery(freeText: $freeText, limit: $limit, offset: $offset, sortOrder: ${sortOrder.name})';
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
