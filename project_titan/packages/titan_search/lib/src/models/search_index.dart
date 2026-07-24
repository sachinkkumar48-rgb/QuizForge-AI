import 'package:meta/meta.dart';

import 'search_scope.dart';

/// Immutable domain model representing a searchable indexed item in local storage.
@immutable
class SearchIndexItem {
  final String id;
  final String contentId;
  final String title;
  final String content;
  final SearchScope scope;
  final List<String> conceptIds;
  final List<String> tags;
  final DateTime timestamp;
  final int accessCount;
  final Map<String, dynamic> metadata;

  SearchIndexItem({
    required this.id,
    required this.contentId,
    required this.title,
    required this.content,
    required this.scope,
    List<String>? conceptIds,
    List<String>? tags,
    DateTime? timestamp,
    this.accessCount = 0,
    Map<String, dynamic>? metadata,
  })  : conceptIds = List<String>.unmodifiable(conceptIds ?? []),
        tags = List<String>.unmodifiable(tags ?? []),
        timestamp = timestamp ?? DateTime.now(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? {});

  SearchIndexItem copyWith({
    String? id,
    String? contentId,
    String? title,
    String? content,
    SearchScope? scope,
    List<String>? conceptIds,
    List<String>? tags,
    DateTime? timestamp,
    int? accessCount,
    Map<String, dynamic>? metadata,
  }) {
    return SearchIndexItem(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      title: title ?? this.title,
      content: content ?? this.content,
      scope: scope ?? this.scope,
      conceptIds: conceptIds ?? this.conceptIds,
      tags: tags ?? this.tags,
      timestamp: timestamp ?? this.timestamp,
      accessCount: accessCount ?? this.accessCount,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contentId': contentId,
        'title': title,
        'content': content,
        'scope': scope.name,
        'conceptIds': conceptIds,
        'tags': tags,
        'timestamp': timestamp.toIso8601String(),
        'accessCount': accessCount,
        'metadata': metadata,
      };

  factory SearchIndexItem.fromJson(Map<String, dynamic> json) =>
      SearchIndexItem(
        id: json['id'] as String,
        contentId: json['contentId'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        scope: SearchScope.values.firstWhere(
          (e) => e.name == json['scope'],
          orElse: () => SearchScope.notes,
        ),
        conceptIds: (json['conceptIds'] as List? ?? []).cast<String>(),
        tags: (json['tags'] as List? ?? []).cast<String>(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        accessCount: json['accessCount'] as int? ?? 0,
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchIndexItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          contentId == other.contentId &&
          scope == other.scope;

  @override
  int get hashCode => Object.hash(id, contentId, scope);
}
