import 'package:meta/meta.dart';

/// Immutable domain model representing a section block inside a smart note.
@immutable
class NoteSection {
  final String id;
  final String heading;
  final String content;
  final int orderIndex;

  const NoteSection({
    required this.id,
    required this.heading,
    required this.content,
    required this.orderIndex,
  });

  NoteSection copyWith({
    String? id,
    String? heading,
    String? content,
    int? orderIndex,
  }) {
    return NoteSection(
      id: id ?? this.id,
      heading: heading ?? this.heading,
      content: content ?? this.content,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'heading': heading,
        'content': content,
        'orderIndex': orderIndex,
      };

  factory NoteSection.fromJson(Map<String, dynamic> json) => NoteSection(
        id: json['id'] as String,
        heading: json['heading'] as String,
        content: json['content'] as String,
        orderIndex: json['orderIndex'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteSection &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          heading == other.heading &&
          content == other.content &&
          orderIndex == other.orderIndex;

  @override
  int get hashCode => Object.hash(id, heading, content, orderIndex);
}
