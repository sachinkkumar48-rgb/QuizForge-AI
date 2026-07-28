import 'package:meta/meta.dart';

/// Immutable domain model representing a category or topic tag.
@immutable
class NoteTag {
  final String id;
  final String label;
  final String colorHex;

  const NoteTag({
    required this.id,
    required this.label,
    this.colorHex = '#2196F3',
  });

  NoteTag copyWith({
    String? id,
    String? label,
    String? colorHex,
  }) {
    return NoteTag(
      id: id ?? this.id,
      label: label ?? this.label,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'colorHex': colorHex,
      };

  factory NoteTag.fromJson(Map<String, dynamic> json) => NoteTag(
        id: json['id'] as String,
        label: json['label'] as String,
        colorHex: json['colorHex'] as String? ?? '#2196F3',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteTag &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          colorHex == other.colorHex;

  @override
  int get hashCode => Object.hash(id, label, colorHex);
}
