import 'package:meta/meta.dart';

/// Immutable domain entity representing a Current Affairs knowledge payload in TITAN.
@immutable
class CurrentAffairsItem {
  /// Unique identifier of the current affairs item.
  final String id;

  /// Headline or title of the current affairs item.
  final String title;

  /// High-level summary or abstract of the item.
  final String summary;

  /// Full body content of the current affairs item.
  final String content;

  /// Publication timestamp of the item.
  final DateTime publicationDate;

  /// Origin/source attribution (e.g. 'PIB', 'The Hindu', 'Yojana', 'Press Bureau').
  final String source;

  /// Broad domain category (e.g. 'Polity', 'Economy', 'Environment', 'IR', 'Science & Tech').
  final String category;

  /// Topic tags associated with the item (e.g. ['Judicial Reforms', 'Constitution']).
  final List<String> tags;

  /// Related subject areas for UPSC alignment (e.g. ['GS Paper II', 'Polity & Governance']).
  final List<String> relatedSubjects;

  /// Constructs an immutable [CurrentAffairsItem].
  CurrentAffairsItem({
    required this.id,
    required this.title,
    required this.content,
    this.summary = '',
    DateTime? publicationDate,
    this.source = 'Unknown',
    this.category = 'General',
    List<String> tags = const [],
    List<String> relatedSubjects = const [],
  })  : publicationDate = publicationDate ?? DateTime.now(),
        tags = List<String>.unmodifiable(tags),
        relatedSubjects = List<String>.unmodifiable(relatedSubjects);

  /// Creates a copy of this [CurrentAffairsItem] with updated fields.
  CurrentAffairsItem copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    DateTime? publicationDate,
    String? source,
    String? category,
    List<String>? tags,
    List<String>? relatedSubjects,
  }) {
    return CurrentAffairsItem(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      publicationDate: publicationDate ?? this.publicationDate,
      source: source ?? this.source,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      relatedSubjects: relatedSubjects ?? this.relatedSubjects,
    );
  }

  /// Converts this [CurrentAffairsItem] into a JSON-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'content': content,
      'publicationDate': publicationDate.toIso8601String(),
      'source': source,
      'category': category,
      'tags': tags,
      'relatedSubjects': relatedSubjects,
    };
  }

  /// Deserializes a [CurrentAffairsItem] from a Map.
  factory CurrentAffairsItem.fromMap(Map<String, dynamic> map) {
    return CurrentAffairsItem(
      id: (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      summary: (map['summary'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      publicationDate: map['publicationDate'] != null
          ? DateTime.parse(map['publicationDate'] as String)
          : DateTime.now(),
      source: (map['source'] as String?) ?? 'Unknown',
      category: (map['category'] as String?) ?? 'General',
      tags: List<String>.from(map['tags'] as List? ?? const []),
      relatedSubjects:
          List<String>.from(map['relatedSubjects'] as List? ?? const []),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CurrentAffairsItem &&
        other.id == id &&
        other.title == title &&
        other.summary == summary &&
        other.content == content &&
        other.publicationDate == publicationDate &&
        other.source == source &&
        other.category == category &&
        _listEquals(other.tags, tags) &&
        _listEquals(other.relatedSubjects, relatedSubjects);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      summary,
      content,
      publicationDate,
      source,
      category,
      Object.hashAll(tags),
      Object.hashAll(relatedSubjects),
    );
  }

  @override
  String toString() {
    return 'CurrentAffairsItem(id: $id, title: $title, category: $category, source: $source)';
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
