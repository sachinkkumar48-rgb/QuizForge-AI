import 'package:meta/meta.dart';

/// Immutable domain model representing a collection / notebook of smart notes.
@immutable
class NoteCollection {
  final String id;
  final String name;
  final String description;
  final String subject;
  final List<String> noteIds;
  final DateTime createdAt;

  NoteCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.subject,
    required List<String> noteIds,
    required this.createdAt,
  }) : noteIds = List<String>.unmodifiable(noteIds);

  NoteCollection copyWith({
    String? id,
    String? name,
    String? description,
    String? subject,
    List<String>? noteIds,
    DateTime? createdAt,
  }) {
    return NoteCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      noteIds: noteIds ?? this.noteIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'subject': subject,
        'noteIds': noteIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NoteCollection.fromJson(Map<String, dynamic> json) => NoteCollection(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        subject: json['subject'] as String? ?? 'General Studies',
        noteIds: (json['noteIds'] as List? ?? []).cast<String>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteCollection &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          subject == other.subject &&
          createdAt == other.createdAt &&
          _listEquals(noteIds, other.noteIds);

  @override
  int get hashCode => Object.hash(
      id, name, description, subject, createdAt, Object.hashAll(noteIds));
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
