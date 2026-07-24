import 'package:meta/meta.dart';

/// Immutable domain entity representing a Current Affairs article payload in TITAN.
@immutable
class CurrentAffairsArticle {
  /// Unique identifier of the article.
  final String id;

  /// Headline or title of the current affairs article.
  final String title;

  /// Source attribution (e.g. 'The Hindu', 'PIB', 'Yojana', 'Indian Express').
  final String source;

  /// Publication timestamp of the article.
  final DateTime publicationDate;

  /// Full text body content of the current affairs article.
  final String content;

  /// Topic or category tags associated with the article (e.g. ['Polity', 'Environment', 'IR']).
  final List<String> tags;

  /// ISO language code (e.g. 'en', 'hi').
  final String language;

  /// Constructs an immutable [CurrentAffairsArticle].
  CurrentAffairsArticle({
    required this.id,
    required this.title,
    required this.source,
    required this.content,
    DateTime? publicationDate,
    List<String> tags = const [],
    this.language = 'en',
  })  : assert(id.trim().isNotEmpty, 'id cannot be empty'),
        assert(title.trim().isNotEmpty, 'title cannot be empty'),
        assert(source.trim().isNotEmpty, 'source cannot be empty'),
        assert(content.trim().isNotEmpty, 'content cannot be empty'),
        publicationDate = publicationDate ?? DateTime.now(),
        tags = List<String>.unmodifiable(tags);

  /// Creates a copy of this [CurrentAffairsArticle] with updated fields.
  CurrentAffairsArticle copyWith({
    String? id,
    String? title,
    String? source,
    DateTime? publicationDate,
    String? content,
    List<String>? tags,
    String? language,
  }) {
    return CurrentAffairsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      source: source ?? this.source,
      publicationDate: publicationDate ?? this.publicationDate,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      language: language ?? this.language,
    );
  }

  /// Converts this [CurrentAffairsArticle] into a JSON-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'source': source,
      'publicationDate': publicationDate.toIso8601String(),
      'content': content,
      'tags': tags,
      'language': language,
    };
  }

  /// Deserializes a [CurrentAffairsArticle] from a Map.
  factory CurrentAffairsArticle.fromMap(Map<String, dynamic> map) {
    return CurrentAffairsArticle(
      id: map['id'] as String,
      title: map['title'] as String,
      source: map['source'] as String,
      content: map['content'] as String,
      publicationDate: map['publicationDate'] != null
          ? DateTime.parse(map['publicationDate'] as String)
          : DateTime.now(),
      tags: List<String>.from(map['tags'] as List? ?? const []),
      language: (map['language'] as String?) ?? 'en',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CurrentAffairsArticle &&
        other.id == id &&
        other.title == title &&
        other.source == source &&
        other.publicationDate == publicationDate &&
        other.content == content &&
        _listEquals(other.tags, tags) &&
        other.language == language;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      source,
      publicationDate,
      content,
      Object.hashAll(tags),
      language,
    );
  }

  @override
  String toString() {
    return 'CurrentAffairsArticle(id: $id, title: $title, source: $source, date: ${publicationDate.toIso8601String()})';
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
