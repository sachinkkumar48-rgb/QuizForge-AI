import 'package:meta/meta.dart';

/// Immutable domain model representing user or AI feedback comments on a note.
@immutable
class NoteComment {
  final String id;
  final String noteId;
  final String author;
  final String text;
  final bool isAiGenerated;
  final DateTime createdAt;

  const NoteComment({
    required this.id,
    required this.noteId,
    required this.author,
    required this.text,
    this.isAiGenerated = false,
    required this.createdAt,
  });

  NoteComment copyWith({
    String? id,
    String? noteId,
    String? author,
    String? text,
    bool? isAiGenerated,
    DateTime? createdAt,
  }) {
    return NoteComment(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      author: author ?? this.author,
      text: text ?? this.text,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'noteId': noteId,
        'author': author,
        'text': text,
        'isAiGenerated': isAiGenerated,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NoteComment.fromJson(Map<String, dynamic> json) => NoteComment(
        id: json['id'] as String,
        noteId: json['noteId'] as String,
        author: json['author'] as String,
        text: json['text'] as String,
        isAiGenerated: json['isAiGenerated'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteComment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          noteId == other.noteId &&
          author == other.author &&
          text == other.text &&
          isAiGenerated == other.isAiGenerated &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      Object.hash(id, noteId, author, text, isAiGenerated, createdAt);
}
