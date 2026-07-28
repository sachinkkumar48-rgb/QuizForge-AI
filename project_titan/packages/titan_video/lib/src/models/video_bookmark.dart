import 'package:meta/meta.dart';

/// Immutable domain model representing a timestamped user bookmark on a video.
@immutable
class VideoBookmark {
  final String id;
  final String contentId;
  final int timestampSeconds;
  final String note;
  final DateTime createdAt;

  const VideoBookmark({
    required this.id,
    required this.contentId,
    required this.timestampSeconds,
    required this.note,
    required this.createdAt,
  });

  VideoBookmark copyWith({
    String? id,
    String? contentId,
    int? timestampSeconds,
    String? note,
    DateTime? createdAt,
  }) {
    return VideoBookmark(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      timestampSeconds: timestampSeconds ?? this.timestampSeconds,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contentId': contentId,
        'timestampSeconds': timestampSeconds,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VideoBookmark.fromJson(Map<String, dynamic> json) => VideoBookmark(
        id: json['id'] as String,
        contentId: json['contentId'] as String,
        timestampSeconds: json['timestampSeconds'] as int? ?? 0,
        note: json['note'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoBookmark &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          contentId == other.contentId &&
          timestampSeconds == other.timestampSeconds &&
          note == other.note &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        contentId,
        timestampSeconds,
        note,
        createdAt,
      );
}
