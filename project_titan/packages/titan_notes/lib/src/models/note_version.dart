import 'package:meta/meta.dart';

/// Immutable domain model representing a historical version snapshot of a note.
@immutable
class NoteVersion {
  final int versionNumber;
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;

  const NoteVersion({
    required this.versionNumber,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  NoteVersion copyWith({
    int? versionNumber,
    String? title,
    String? content,
    String? author,
    DateTime? createdAt,
  }) {
    return NoteVersion(
      versionNumber: versionNumber ?? this.versionNumber,
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'versionNumber': versionNumber,
        'title': title,
        'content': content,
        'author': author,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NoteVersion.fromJson(Map<String, dynamic> json) => NoteVersion(
        versionNumber: json['versionNumber'] as int,
        title: json['title'] as String,
        content: json['content'] as String,
        author: json['author'] as String? ?? 'Aspirant',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteVersion &&
          runtimeType == other.runtimeType &&
          versionNumber == other.versionNumber &&
          title == other.title &&
          content == other.content &&
          author == other.author &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      Object.hash(versionNumber, title, content, author, createdAt);
}
