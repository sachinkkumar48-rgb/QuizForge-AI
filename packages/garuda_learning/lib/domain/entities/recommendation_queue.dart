/// Recommendation Queue Aggregate Root (TITAN-KO-021.0 P21).
///
/// Aggregate root representing the prioritized, deterministic sequence of
/// learning recommendations generated for a specific learner.
library;

import 'package:meta/meta.dart';

import 'learning_recommendation.dart';
import 'recommendation_policy.dart';

@immutable
class RecommendationQueue {
  /// Target learner identifier.
  final String learnerId;

  /// Ordered list of prioritized learning recommendations.
  final List<LearningRecommendation> items;

  /// UTC timestamp when this queue was generated.
  final DateTime generatedAt;

  /// Policy configuration used during generation.
  final RecommendationPolicy policyUsed;

  RecommendationQueue({
    required this.learnerId,
    required List<LearningRecommendation> items,
    DateTime? generatedAt,
    this.policyUsed = const RecommendationPolicy(),
  })  : generatedAt = (generatedAt ?? DateTime.now()).toUtc(),
        items = List<LearningRecommendation>.unmodifiable(
          _sortItemsDeterministically(items),
        ) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
  }

  /// Returns true if the recommendation queue contains zero items.
  bool get isEmpty => items.isEmpty;

  /// Returns true if the recommendation queue contains at least one item.
  bool get isNotEmpty => items.isNotEmpty;

  /// Number of recommendations in the queue.
  int get length => items.length;

  /// Retrieves the top recommendation, or null if the queue is empty.
  LearningRecommendation? get topRecommendation =>
      items.isNotEmpty ? items.first : null;

  /// Sorts recommendations strictly by `priorityScore` descending, using `objectiveId` as tie-breaker.
  static List<LearningRecommendation> _sortItemsDeterministically(
    List<LearningRecommendation> raw,
  ) {
    final list = List<LearningRecommendation>.from(raw);
    list.sort((a, b) {
      final scoreCmp = b.priorityScore.compareTo(a.priorityScore);
      if (scoreCmp != 0) return scoreCmp;
      return a.objectiveId.compareTo(b.objectiveId);
    });
    return list;
  }

  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        'items': items.map((i) => i.toJson()).toList(),
        'generatedAt': generatedAt.toIso8601String(),
        'policyUsed': policyUsed.toJson(),
      };

  factory RecommendationQueue.fromJson(Map<String, dynamic> json) =>
      RecommendationQueue(
        learnerId: json['learnerId'] as String? ?? '',
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => LearningRecommendation.fromJson(
                Map<String, dynamic>.from(e as Map? ?? const {})))
            .toList(),
        generatedAt: json['generatedAt'] != null
            ? DateTime.parse(json['generatedAt'] as String)
            : null,
        policyUsed: json['policyUsed'] != null
            ? RecommendationPolicy.fromJson(Map<String, dynamic>.from(
                json['policyUsed'] as Map? ?? const {}))
            : const RecommendationPolicy(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationQueue &&
          learnerId == other.learnerId &&
          generatedAt == other.generatedAt &&
          policyUsed == other.policyUsed &&
          _listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(
        learnerId,
        generatedAt,
        policyUsed,
        Object.hashAll(items),
      );

  @override
  String toString() =>
      'RecommendationQueue(learnerId: $learnerId, itemsCount: ${items.length}, generatedAt: $generatedAt)';

  static bool _listEquals(
    List<LearningRecommendation> a,
    List<LearningRecommendation> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
