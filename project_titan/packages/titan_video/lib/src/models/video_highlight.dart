import 'package:meta/meta.dart';

/// Immutable domain model representing a highlighted time segment in a video.
@immutable
class VideoHighlight {
  final String id;
  final String contentId;
  final int startSeconds;
  final int endSeconds;
  final String note;
  final String colorHex;

  const VideoHighlight({
    required this.id,
    required this.contentId,
    required this.startSeconds,
    required this.endSeconds,
    required this.note,
    this.colorHex = '#FFD54F',
  });

  VideoHighlight copyWith({
    String? id,
    String? contentId,
    int? startSeconds,
    int? endSeconds,
    String? note,
    String? colorHex,
  }) {
    return VideoHighlight(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      startSeconds: startSeconds ?? this.startSeconds,
      endSeconds: endSeconds ?? this.endSeconds,
      note: note ?? this.note,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contentId': contentId,
        'startSeconds': startSeconds,
        'endSeconds': endSeconds,
        'note': note,
        'colorHex': colorHex,
      };

  factory VideoHighlight.fromJson(Map<String, dynamic> json) => VideoHighlight(
        id: json['id'] as String,
        contentId: json['contentId'] as String,
        startSeconds: json['startSeconds'] as int? ?? 0,
        endSeconds: json['endSeconds'] as int? ?? 0,
        note: json['note'] as String? ?? '',
        colorHex: json['colorHex'] as String? ?? '#FFD54F',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoHighlight &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          contentId == other.contentId &&
          startSeconds == other.startSeconds &&
          endSeconds == other.endSeconds &&
          note == other.note &&
          colorHex == other.colorHex;

  @override
  int get hashCode => Object.hash(
        id,
        contentId,
        startSeconds,
        endSeconds,
        note,
        colorHex,
      );
}
