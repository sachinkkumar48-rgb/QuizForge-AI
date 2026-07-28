import 'package:meta/meta.dart';

/// Immutable domain model representing a video timeline chapter marker.
@immutable
class VideoChapter {
  final String id;
  final String title;
  final int startSeconds;
  final int endSeconds;
  final String? thumbnailUri;

  const VideoChapter({
    required this.id,
    required this.title,
    required this.startSeconds,
    required this.endSeconds,
    this.thumbnailUri,
  });

  VideoChapter copyWith({
    String? id,
    String? title,
    int? startSeconds,
    int? endSeconds,
    String? thumbnailUri,
  }) {
    return VideoChapter(
      id: id ?? this.id,
      title: title ?? this.title,
      startSeconds: startSeconds ?? this.startSeconds,
      endSeconds: endSeconds ?? this.endSeconds,
      thumbnailUri: thumbnailUri ?? this.thumbnailUri,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startSeconds': startSeconds,
        'endSeconds': endSeconds,
        'thumbnailUri': thumbnailUri,
      };

  factory VideoChapter.fromJson(Map<String, dynamic> json) => VideoChapter(
        id: json['id'] as String,
        title: json['title'] as String,
        startSeconds: json['startSeconds'] as int? ?? 0,
        endSeconds: json['endSeconds'] as int? ?? 0,
        thumbnailUri: json['thumbnailUri'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoChapter &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          startSeconds == other.startSeconds &&
          endSeconds == other.endSeconds &&
          thumbnailUri == other.thumbnailUri;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        startSeconds,
        endSeconds,
        thumbnailUri,
      );
}
