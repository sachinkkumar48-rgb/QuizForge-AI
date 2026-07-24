import 'package:meta/meta.dart';

import '../value_objects/knowledge_type.dart';

/// Canonical Knowledge Object (CKO) representing a foundational, immutable
/// knowledge entity across all TITAN platform engines.
@immutable
class KnowledgeObject {
  /// Unique identifier of the knowledge object.
  final String id;

  /// Category/type of knowledge source.
  final KnowledgeType type;

  /// Descriptive title of the knowledge object.
  final String title;

  /// High-level summary or abstract of the knowledge content.
  final String summary;

  /// Origin URI, file path, or source attribution.
  final String source;

  /// Primary language of the content (e.g., 'en', 'hi').
  final String language;

  /// Subject areas associated with this knowledge object.
  final List<String> subjects;

  /// Specific topic tags associated with this knowledge object.
  final List<String> topics;

  /// Indexing keywords and search terms.
  final List<String> keywords;

  /// Arbitrary extensible key-value metadata payload.
  final Map<String, dynamic> metadata;

  /// Timestamp when the object was first created.
  final DateTime createdAt;

  /// Timestamp when the object was last modified.
  final DateTime updatedAt;

  /// Constructs an immutable [KnowledgeObject] instance.
  ///
  /// Defensive copies are created for lists and metadata maps to guarantee
  /// immutability.
  KnowledgeObject({
    required this.id,
    required this.type,
    required this.title,
    required this.summary,
    required this.source,
    this.language = 'en',
    List<String> subjects = const [],
    List<String> topics = const [],
    List<String> keywords = const [],
    Map<String, dynamic> metadata = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : subjects = List<String>.unmodifiable(subjects),
        topics = List<String>.unmodifiable(topics),
        keywords = List<String>.unmodifiable(keywords),
        metadata = Map<String, dynamic>.unmodifiable(metadata),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Creates a copy of this [KnowledgeObject] with modified fields.
  KnowledgeObject copyWith({
    String? id,
    KnowledgeType? type,
    String? title,
    String? summary,
    String? source,
    String? language,
    List<String>? subjects,
    List<String>? topics,
    List<String>? keywords,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KnowledgeObject(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      source: source ?? this.source,
      language: language ?? this.language,
      subjects: subjects ?? this.subjects,
      topics: topics ?? this.topics,
      keywords: keywords ?? this.keywords,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts this [KnowledgeObject] into a JSON-compatible [Map].
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'summary': summary,
      'source': source,
      'language': language,
      'subjects': subjects,
      'topics': topics,
      'keywords': keywords,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Deserializes a [KnowledgeObject] from a [Map].
  factory KnowledgeObject.fromMap(Map<String, dynamic> map) {
    return KnowledgeObject(
      id: map['id'] as String,
      type: KnowledgeType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => KnowledgeType.other,
      ),
      title: map['title'] as String,
      summary: map['summary'] as String,
      source: map['source'] as String,
      language: map['language'] as String? ?? 'en',
      subjects: List<String>.from(map['subjects'] as List? ?? const []),
      topics: List<String>.from(map['topics'] as List? ?? const []),
      keywords: List<String>.from(map['keywords'] as List? ?? const []),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? const {}),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is KnowledgeObject &&
        other.id == id &&
        other.type == type &&
        other.title == title &&
        other.summary == summary &&
        other.source == source &&
        other.language == language &&
        _listEquals(other.subjects, subjects) &&
        _listEquals(other.topics, topics) &&
        _listEquals(other.keywords, keywords) &&
        _mapEquals(other.metadata, metadata) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      title,
      summary,
      source,
      language,
      Object.hashAll(subjects),
      Object.hashAll(topics),
      Object.hashAll(keywords),
      Object.hashAll(metadata.keys),
      Object.hashAll(metadata.values),
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'KnowledgeObject(id: $id, type: ${type.name}, title: $title, source: $source)';
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
