import 'package:knowledge_engine/domain/entities/knowledge_object.dart';
import 'package:meta/meta.dart';
import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_revision/titan_revision.dart';

/// Immutable model representing an explainable reason for a recommendation.
@immutable
class RecommendationReason {
  final String code;
  final String title;
  final String description;
  final double weight; // 0.0 to 1.0

  const RecommendationReason({
    required this.code,
    required this.title,
    required this.description,
    this.weight = 1.0,
  });

  RecommendationReason copyWith({
    String? code,
    String? title,
    String? description,
    double? weight,
  }) {
    return RecommendationReason(
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      weight: weight ?? this.weight,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationReason &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          title == other.title &&
          description == other.description &&
          weight == other.weight;

  @override
  int get hashCode => Object.hash(code, title, description, weight);
}

/// Immutable contextual snapshot used by the RecommendationEngine to evaluate rules.
@immutable
class RecommendationContext {
  final LearningProfile profile;
  final RevisionQueue revisionQueue;
  final ResultAnalytics? latestAnalytics;
  final List<KnowledgeObject>? knowledgeObjects;
  final List<String> availableTopics;
  final DateTime generatedAt;

  RecommendationContext({
    required this.profile,
    required this.revisionQueue,
    this.latestAnalytics,
    List<KnowledgeObject>? knowledgeObjects,
    required List<String> availableTopics,
    required this.generatedAt,
  })  : knowledgeObjects = knowledgeObjects != null
            ? List<KnowledgeObject>.unmodifiable(knowledgeObjects)
            : null,
        availableTopics = List<String>.unmodifiable(availableTopics);

  RecommendationContext copyWith({
    LearningProfile? profile,
    RevisionQueue? revisionQueue,
    ResultAnalytics? latestAnalytics,
    List<KnowledgeObject>? knowledgeObjects,
    List<String>? availableTopics,
    DateTime? generatedAt,
  }) {
    return RecommendationContext(
      profile: profile ?? this.profile,
      revisionQueue: revisionQueue ?? this.revisionQueue,
      latestAnalytics: latestAnalytics ?? this.latestAnalytics,
      knowledgeObjects: knowledgeObjects ?? this.knowledgeObjects,
      availableTopics: availableTopics ?? this.availableTopics,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationContext &&
          runtimeType == other.runtimeType &&
          profile == other.profile &&
          revisionQueue == other.revisionQueue &&
          latestAnalytics == other.latestAnalytics &&
          generatedAt == other.generatedAt &&
          _nullableListEquals(knowledgeObjects, other.knowledgeObjects) &&
          _listEquals(availableTopics, other.availableTopics);

  @override
  int get hashCode => Object.hash(
        profile,
        revisionQueue,
        latestAnalytics,
        generatedAt,
        knowledgeObjects != null ? Object.hashAll(knowledgeObjects!) : null,
        Object.hashAll(availableTopics),
      );
}

bool _nullableListEquals<T>(List<T>? a, List<T>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return _listEquals(a, b);
}

/// Immutable domain model representing a personalized study recommendation.
@immutable
class Recommendation {
  final String id;
  final String title;
  final String topic;
  final String
      actionType; // 'Active Recall', 'Concept Deep Dive', 'Practice PYQ', 'Mock Quiz'
  final String priority; // 'Urgent', 'High', 'Medium', 'Low'
  final double confidence; // 0.0 - 1.0
  final String
      source; // 'AI Mentor', 'Revision Engine', 'Learning Profile', 'Knowledge Engine', 'Analytics Engine'
  final List<RecommendationReason> reasons;
  final int estimatedStudyTimeMinutes;
  final String? targetUrl;

  Recommendation({
    required this.id,
    required this.title,
    required this.topic,
    required this.actionType,
    required this.priority,
    required this.confidence,
    required this.source,
    required List<RecommendationReason> reasons,
    required this.estimatedStudyTimeMinutes,
    this.targetUrl,
  }) : reasons = List<RecommendationReason>.unmodifiable(reasons);

  Recommendation copyWith({
    String? id,
    String? title,
    String? topic,
    String? actionType,
    String? priority,
    double? confidence,
    String? source,
    List<RecommendationReason>? reasons,
    int? estimatedStudyTimeMinutes,
    String? targetUrl,
  }) {
    return Recommendation(
      id: id ?? this.id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      actionType: actionType ?? this.actionType,
      priority: priority ?? this.priority,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      reasons: reasons ?? this.reasons,
      estimatedStudyTimeMinutes:
          estimatedStudyTimeMinutes ?? this.estimatedStudyTimeMinutes,
      targetUrl: targetUrl ?? this.targetUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recommendation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          topic == other.topic &&
          actionType == other.actionType &&
          priority == other.priority &&
          confidence == other.confidence &&
          source == other.source &&
          estimatedStudyTimeMinutes == other.estimatedStudyTimeMinutes &&
          targetUrl == other.targetUrl &&
          _listEquals(reasons, other.reasons);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        topic,
        actionType,
        priority,
        confidence,
        source,
        estimatedStudyTimeMinutes,
        targetUrl,
        Object.hashAll(reasons),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
