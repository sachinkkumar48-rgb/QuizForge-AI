import 'package:meta/meta.dart';

/// Immutable domain model representing a timestamp-anchored note created by the learner.
@immutable
class VideoNote {
  final String id;
  final String contentId;
  final int timestampSeconds;
  final String text;
  final DateTime createdAt;

  const VideoNote({
    required this.id,
    required this.contentId,
    required this.timestampSeconds,
    required this.text,
    required this.createdAt,
  });

  VideoNote copyWith({
    String? id,
    String? contentId,
    int? timestampSeconds,
    String? text,
    DateTime? createdAt,
  }) {
    return VideoNote(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      timestampSeconds: timestampSeconds ?? this.timestampSeconds,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contentId': contentId,
        'timestampSeconds': timestampSeconds,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VideoNote.fromJson(Map<String, dynamic> json) => VideoNote(
        id: json['id'] as String,
        contentId: json['contentId'] as String,
        timestampSeconds: json['timestampSeconds'] as int? ?? 0,
        text: json['text'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoNote &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          contentId == other.contentId &&
          timestampSeconds == other.timestampSeconds &&
          text == other.text &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        contentId,
        timestampSeconds,
        text,
        createdAt,
      );
}
