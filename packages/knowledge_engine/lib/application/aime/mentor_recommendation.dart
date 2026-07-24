import 'package:meta/meta.dart';

import '../../domain/entities/knowledge_object.dart';
import 'recommendation_reason.dart';

/// Value object representing a complete AI Mentor recommendation payload in TITAN AIME.
@immutable
class MentorRecommendation {
  /// Recommended primary topics or study items for the learner.
  final List<KnowledgeObject> recommendedTopics;

  /// Required prerequisite knowledge objects for recommended topics.
  final List<KnowledgeObject> prerequisites;

  /// Related knowledge objects for broader context.
  final List<KnowledgeObject> relatedTopics;

  /// Suggested Previous Year Question (PYQ) knowledge objects for assessment.
  final List<KnowledgeObject> suggestedPYQs;

  /// Suggested Current Affairs article knowledge objects for real-world context.
  final List<KnowledgeObject> suggestedCurrentAffairs;

  /// Primary reasoning payload explaining why this recommendation cycle was produced.
  final RecommendationReason reasoning;

  /// Constructs an immutable [MentorRecommendation].
  MentorRecommendation({
    required List<KnowledgeObject> recommendedTopics,
    required this.reasoning,
    List<KnowledgeObject> prerequisites = const [],
    List<KnowledgeObject> relatedTopics = const [],
    List<KnowledgeObject> suggestedPYQs = const [],
    List<KnowledgeObject> suggestedCurrentAffairs = const [],
  })  : recommendedTopics =
            List<KnowledgeObject>.unmodifiable(recommendedTopics),
        prerequisites = List<KnowledgeObject>.unmodifiable(prerequisites),
        relatedTopics = List<KnowledgeObject>.unmodifiable(relatedTopics),
        suggestedPYQs = List<KnowledgeObject>.unmodifiable(suggestedPYQs),
        suggestedCurrentAffairs =
            List<KnowledgeObject>.unmodifiable(suggestedCurrentAffairs);

  /// Creates a copy of this [MentorRecommendation] with updated fields.
  MentorRecommendation copyWith({
    List<KnowledgeObject>? recommendedTopics,
    List<KnowledgeObject>? prerequisites,
    List<KnowledgeObject>? relatedTopics,
    List<KnowledgeObject>? suggestedPYQs,
    List<KnowledgeObject>? suggestedCurrentAffairs,
    RecommendationReason? reasoning,
  }) {
    return MentorRecommendation(
      recommendedTopics: recommendedTopics ?? this.recommendedTopics,
      prerequisites: prerequisites ?? this.prerequisites,
      relatedTopics: relatedTopics ?? this.relatedTopics,
      suggestedPYQs: suggestedPYQs ?? this.suggestedPYQs,
      suggestedCurrentAffairs:
          suggestedCurrentAffairs ?? this.suggestedCurrentAffairs,
      reasoning: reasoning ?? this.reasoning,
    );
  }

  /// Converts this [MentorRecommendation] into a JSON-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'recommendedTopics': recommendedTopics.map((e) => e.toMap()).toList(),
      'prerequisites': prerequisites.map((e) => e.toMap()).toList(),
      'relatedTopics': relatedTopics.map((e) => e.toMap()).toList(),
      'suggestedPYQs': suggestedPYQs.map((e) => e.toMap()).toList(),
      'suggestedCurrentAffairs':
          suggestedCurrentAffairs.map((e) => e.toMap()).toList(),
      'reasoning': reasoning.toMap(),
    };
  }

  /// Deserializes a [MentorRecommendation] from a Map.
  factory MentorRecommendation.fromMap(Map<String, dynamic> map) {
    return MentorRecommendation(
      recommendedTopics: List<KnowledgeObject>.from(
        (map['recommendedTopics'] as List? ?? const []).map((e) =>
            KnowledgeObject.fromMap(Map<String, dynamic>.from(e as Map))),
      ),
      prerequisites: List<KnowledgeObject>.from(
        (map['prerequisites'] as List? ?? const []).map((e) =>
            KnowledgeObject.fromMap(Map<String, dynamic>.from(e as Map))),
      ),
      relatedTopics: List<KnowledgeObject>.from(
        (map['relatedTopics'] as List? ?? const []).map((e) =>
            KnowledgeObject.fromMap(Map<String, dynamic>.from(e as Map))),
      ),
      suggestedPYQs: List<KnowledgeObject>.from(
        (map['suggestedPYQs'] as List? ?? const []).map((e) =>
            KnowledgeObject.fromMap(Map<String, dynamic>.from(e as Map))),
      ),
      suggestedCurrentAffairs: List<KnowledgeObject>.from(
        (map['suggestedCurrentAffairs'] as List? ?? const []).map((e) =>
            KnowledgeObject.fromMap(Map<String, dynamic>.from(e as Map))),
      ),
      reasoning: map['reasoning'] != null
          ? RecommendationReason.fromMap(
              Map<String, dynamic>.from(map['reasoning'] as Map))
          : RecommendationReason(
              code: 'GENERAL', explanation: 'General recommendation'),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MentorRecommendation &&
        _listEquals(other.recommendedTopics, recommendedTopics) &&
        _listEquals(other.prerequisites, prerequisites) &&
        _listEquals(other.relatedTopics, relatedTopics) &&
        _listEquals(other.suggestedPYQs, suggestedPYQs) &&
        _listEquals(other.suggestedCurrentAffairs, suggestedCurrentAffairs) &&
        other.reasoning == reasoning;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(recommendedTopics),
      Object.hashAll(prerequisites),
      Object.hashAll(relatedTopics),
      Object.hashAll(suggestedPYQs),
      Object.hashAll(suggestedCurrentAffairs),
      reasoning,
    );
  }

  @override
  String toString() {
    return 'MentorRecommendation(topics: ${recommendedTopics.length}, pyqs: ${suggestedPYQs.length}, ca: ${suggestedCurrentAffairs.length}, reason: ${reasoning.code})';
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
