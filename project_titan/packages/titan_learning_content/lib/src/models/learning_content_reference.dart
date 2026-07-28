import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain model representing a reference to an external or internal resource URI.
@immutable
class LearningContentReference {
  final String id;
  final String contentId;
  final String title;
  final ContentType contentType;
  final String uri;
  final String type; // 'pdf', 'video_stream', 'external_link', 'asset'

  const LearningContentReference({
    required this.id,
    required this.contentId,
    required this.title,
    required this.contentType,
    required this.uri,
    required this.type,
  });

  LearningContentReference copyWith({
    String? id,
    String? contentId,
    String? title,
    ContentType? contentType,
    String? uri,
    String? type,
  }) {
    return LearningContentReference(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      title: title ?? this.title,
      contentType: contentType ?? this.contentType,
      uri: uri ?? this.uri,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contentId': contentId,
        'title': title,
        'contentType': contentType.name,
        'uri': uri,
        'type': type,
      };

  factory LearningContentReference.fromJson(Map<String, dynamic> json) =>
      LearningContentReference(
        id: json['id'] as String,
        contentId: json['contentId'] as String,
        title: json['title'] as String,
        contentType: ContentType.values.firstWhere(
          (e) => e.name == json['contentType'],
          orElse: () => ContentType.notes,
        ),
        uri: json['uri'] as String,
        type: json['type'] as String? ?? 'asset',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningContentReference &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          contentId == other.contentId &&
          title == other.title &&
          contentType == other.contentType &&
          uri == other.uri &&
          type == other.type;

  @override
  int get hashCode => Object.hash(
        id,
        contentId,
        title,
        contentType,
        uri,
        type,
      );
}
