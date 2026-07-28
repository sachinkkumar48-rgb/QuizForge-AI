import 'package:meta/meta.dart';

/// Immutable domain model representing a bookmark inside a note.
@immutable
class NoteBookmark {
  final String id;
  final String noteId;
  final String label;
  final int offsetIndex;
  final DateTime createdAt;

  const NoteBookmark({
    required this.id,
    required this.noteId,
    required this.label,
    required this.offsetIndex,
    required this.createdAt,
  });

  NoteBookmark copyWith({
    String? id,
    String? noteId,
    String? label,
    int? offsetIndex,
    DateTime? createdAt,
  }) {
    return NoteBookmark(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      label: label ?? this.label,
      offsetIndex: offsetIndex ?? this.offsetIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'noteId': noteId,
        'label': label,
        'offsetIndex': offsetIndex,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NoteBookmark.fromJson(Map<String, dynamic> json) => NoteBookmark(
        id: json['id'] as String,
        noteId: json['noteId'] as String,
        label: json['label'] as String,
        offsetIndex: json['offsetIndex'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteBookmark &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          noteId == other.noteId &&
          label == other.label &&
          offsetIndex == other.offsetIndex &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, noteId, label, offsetIndex, createdAt);
}
