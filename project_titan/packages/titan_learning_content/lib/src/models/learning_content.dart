import 'package:meta/meta.dart';
import 'content_completion.dart';

import 'content_metadata.dart';
import 'content_objective.dart';
import 'content_outcome.dart';
import 'content_prerequisite.dart';
import 'content_progress.dart';

import 'enums.dart';

import 'learning_content_reference.dart';

/// Canonical domain model representing every educational resource in Project TITAN.
@immutable
class LearningContent {
  final String id;
  final String title;
  final String description;
  final ContentType type;
  final ContentMetadata metadata;
  final List<ContentObjective> objectives;
  final List<ContentPrerequisite> prerequisites;
  final List<ContentOutcome> outcomes;
  final List<LearningContentReference> references;
  final String? chapterId;
  final String? courseId;
  final String? knowledgeNodeId;
  final ContentProgress? progress;
  final ContentCompletion? completion;

  LearningContent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.metadata,
    required List<ContentObjective> objectives,
    required List<ContentPrerequisite> prerequisites,
    required List<ContentOutcome> outcomes,
    required List<LearningContentReference> references,
    this.chapterId,
    this.courseId,
    this.knowledgeNodeId,
    this.progress,
    this.completion,
  })  : objectives = List<ContentObjective>.unmodifiable(objectives),
        prerequisites = List<ContentPrerequisite>.unmodifiable(prerequisites),
        outcomes = List<ContentOutcome>.unmodifiable(outcomes),
        references = List<LearningContentReference>.unmodifiable(references);

  LearningContent copyWith({
    String? id,
    String? title,
    String? description,
    ContentType? type,
    ContentMetadata? metadata,
    List<ContentObjective>? objectives,
    List<ContentPrerequisite>? prerequisites,
    List<ContentOutcome>? outcomes,
    List<LearningContentReference>? references,
    String? chapterId,
    String? courseId,
    String? knowledgeNodeId,
    ContentProgress? progress,
    ContentCompletion? completion,
  }) {
    return LearningContent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      objectives: objectives ?? this.objectives,
      prerequisites: prerequisites ?? this.prerequisites,
      outcomes: outcomes ?? this.outcomes,
      references: references ?? this.references,
      chapterId: chapterId ?? this.chapterId,
      courseId: courseId ?? this.courseId,
      knowledgeNodeId: knowledgeNodeId ?? this.knowledgeNodeId,
      progress: progress ?? this.progress,
      completion: completion ?? this.completion,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'metadata': metadata.toJson(),
        'objectives': objectives.map((o) => o.toJson()).toList(),
        'prerequisites': prerequisites.map((p) => p.toJson()).toList(),
        'outcomes': outcomes.map((o) => o.toJson()).toList(),
        'references': references.map((r) => r.toJson()).toList(),
        'chapterId': chapterId,
        'courseId': courseId,
        'knowledgeNodeId': knowledgeNodeId,
        'progress': progress?.toJson(),
        'completion': completion?.toJson(),
      };

  factory LearningContent.fromJson(Map<String, dynamic> json) =>
      LearningContent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        type: ContentType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ContentType.notes,
        ),
        metadata: ContentMetadata.fromJson(
            Map<String, dynamic>.from(json['metadata'] as Map)),
        objectives: (json['objectives'] as List? ?? [])
            .map((o) =>
                ContentObjective.fromJson(Map<String, dynamic>.from(o as Map)))
            .toList(),
        prerequisites: (json['prerequisites'] as List? ?? [])
            .map((p) => ContentPrerequisite.fromJson(
                Map<String, dynamic>.from(p as Map)))
            .toList(),
        outcomes: (json['outcomes'] as List? ?? [])
            .map((o) =>
                ContentOutcome.fromJson(Map<String, dynamic>.from(o as Map)))
            .toList(),
        references: (json['references'] as List? ?? [])
            .map((r) => LearningContentReference.fromJson(
                Map<String, dynamic>.from(r as Map)))
            .toList(),
        chapterId: json['chapterId'] as String?,
        courseId: json['courseId'] as String?,
        knowledgeNodeId: json['knowledgeNodeId'] as String?,
        progress: json['progress'] != null
            ? ContentProgress.fromJson(
                Map<String, dynamic>.from(json['progress'] as Map))
            : null,
        completion: json['completion'] != null
            ? ContentCompletion.fromJson(
                Map<String, dynamic>.from(json['completion'] as Map))
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningContent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          type == other.type &&
          metadata == other.metadata &&
          chapterId == other.chapterId &&
          courseId == other.courseId &&
          knowledgeNodeId == other.knowledgeNodeId &&
          progress == other.progress &&
          completion == other.completion &&
          _listEquals(objectives, other.objectives) &&
          _listEquals(prerequisites, other.prerequisites) &&
          _listEquals(outcomes, other.outcomes) &&
          _listEquals(references, other.references);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        type,
        metadata,
        chapterId,
        courseId,
        knowledgeNodeId,
        progress,
        completion,
        Object.hashAll(objectives),
        Object.hashAll(prerequisites),
        Object.hashAll(outcomes),
        Object.hashAll(references),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
