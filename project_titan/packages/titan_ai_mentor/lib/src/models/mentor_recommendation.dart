import 'package:meta/meta.dart';

/// Immutable domain model representing a recommended action suggested by AI Mentor.
@immutable
class MentorRecommendation {
  final String id;
  final String title;
  final String description;
  final String actionType;
  final String? targetId;
  final Map<String, dynamic> metadata;

  MentorRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.actionType,
    this.targetId,
    Map<String, dynamic>? metadata,
  }) : metadata = Map<String, dynamic>.unmodifiable(metadata ?? {});

  MentorRecommendation copyWith({
    String? id,
    String? title,
    String? description,
    String? actionType,
    String? targetId,
    Map<String, dynamic>? metadata,
  }) {
    return MentorRecommendation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      actionType: actionType ?? this.actionType,
      targetId: targetId ?? this.targetId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'actionType': actionType,
        'targetId': targetId,
        'metadata': metadata,
      };

  factory MentorRecommendation.fromJson(Map<String, dynamic> json) =>
      MentorRecommendation(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        actionType: json['actionType'] as String,
        targetId: json['targetId'] as String?,
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentorRecommendation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          actionType == other.actionType;

  @override
  int get hashCode => Object.hash(id, title, actionType);
}
