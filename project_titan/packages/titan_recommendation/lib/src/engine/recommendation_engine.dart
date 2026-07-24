import '../models/recommendation_models.dart';
import 'recommendation_rules.dart';

/// Pure domain Recommendation Engine orchestrating rule evaluation, confidence scoring,
/// and explainable recommendation sorting.
class RecommendationEngine {
  final RecommendationRules _rules;

  const RecommendationEngine({
    RecommendationRules rules = const RecommendationRules(),
  }) : _rules = rules;

  /// Generates a prioritized, deduplicated list of personalized study recommendations.
  List<Recommendation> generate(RecommendationContext context) {
    final rawRecommendations = <Recommendation>[
      ..._rules.evaluateRevisionQueue(context),
      ..._rules.evaluateLearningProfile(context),
      ..._rules.evaluateAnalytics(context),
      ..._rules.evaluatePYQTrends(context),
    ];

    // Deduplicate by topic & actionType, aggregating reasons and picking highest priority/confidence
    final Map<String, Recommendation> map = {};

    for (final rec in rawRecommendations) {
      final key = '${rec.topic.toLowerCase()}_${rec.actionType}';
      if (!map.containsKey(key)) {
        map[key] = rec;
      } else {
        final existing = map[key]!;
        final combinedReasons = [
          ...existing.reasons,
          ...rec.reasons
              .where((r) => !existing.reasons.any((er) => er.code == r.code)),
        ];

        final higherPriority = _higherPriority(existing.priority, rec.priority);
        final higherConfidence = rec.confidence > existing.confidence
            ? rec.confidence
            : existing.confidence;

        map[key] = existing.copyWith(
          priority: higherPriority,
          confidence: higherConfidence,
          reasons: combinedReasons,
        );
      }
    }

    final result = map.values.toList();

    // Sort by priority order (Urgent > High > Medium > Low), then by confidence score descending
    result.sort((a, b) {
      final pOrder = {'Urgent': 0, 'High': 1, 'Medium': 2, 'Low': 3};
      final pA = pOrder[a.priority] ?? 4;
      final pB = pOrder[b.priority] ?? 4;

      if (pA != pB) return pA.compareTo(pB);
      return b.confidence.compareTo(a.confidence);
    });

    return result;
  }

  String _higherPriority(String p1, String p2) {
    final pOrder = {'Urgent': 0, 'High': 1, 'Medium': 2, 'Low': 3};
    final o1 = pOrder[p1] ?? 4;
    final o2 = pOrder[p2] ?? 4;
    return o1 <= o2 ? p1 : p2;
  }
}
