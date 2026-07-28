import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain model representing downloadable learning resources shared during a live session.
@immutable
class LiveResource {
  final String id;
  final String sessionId;
  final String title;
  final String url;
  final LiveResourceType type;
  final String? description;

  const LiveResource({
    required this.id,
    required this.sessionId,
    required this.title,
    required this.url,
    this.type = LiveResourceType.pdf,
    this.description,
  });

  LiveResource copyWith({
    String? id,
    String? sessionId,
    String? title,
    String? url,
    LiveResourceType? type,
    String? description,
  }) {
    return LiveResource(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      url: url ?? this.url,
      type: type ?? this.type,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'title': title,
        'url': url,
        'type': type.name,
        'description': description,
      };

  factory LiveResource.fromJson(Map<String, dynamic> json) => LiveResource(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        title: json['title'] as String,
        url: json['url'] as String,
        type: LiveResourceType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => LiveResourceType.pdf,
        ),
        description: json['description'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveResource &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          title == other.title;

  @override
  int get hashCode => Object.hash(id, sessionId, title);
}
