import 'package:meta/meta.dart';

/// Immutable domain model representing text or canvas annotation over media.
@immutable
class Annotation {
  final String id;
  final String contentId;
  final int? pageNumber;
  final int? timestampSeconds;
  final String text;
  final String author;
  final DateTime createdAt;

  const Annotation({
    required this.id,
    required this.contentId,
    this.pageNumber,
    this.timestampSeconds,
    required this.text,
    required this.author,
    required this.createdAt,
  });

  Annotation copyWith({
    String? id,
    String? contentId,
    int? pageNumber,
    int? timestampSeconds,
    String? text,
    String? author,
    DateTime? createdAt,
  }) {
    return Annotation(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      pageNumber: pageNumber ?? this.pageNumber,
      timestampSeconds: timestampSeconds ?? this.timestampSeconds,
      text: text ?? this.text,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contentId': contentId,
        'pageNumber': pageNumber,
        'timestampSeconds': timestampSeconds,
        'text': text,
        'author': author,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Annotation.fromJson(Map<String, dynamic> json) => Annotation(
        id: json['id'] as String,
        contentId: json['contentId'] as String,
        pageNumber: json['pageNumber'] as int?,
        timestampSeconds: json['timestampSeconds'] as int?,
        text: json['text'] as String,
        author: json['author'] as String? ?? 'Aspirant',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Annotation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          contentId == other.contentId &&
          pageNumber == other.pageNumber &&
          timestampSeconds == other.timestampSeconds &&
          text == other.text &&
          author == other.author &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
      id, contentId, pageNumber, timestampSeconds, text, author, createdAt);
}
