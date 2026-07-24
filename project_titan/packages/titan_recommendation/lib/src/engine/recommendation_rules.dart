import 'package:titan_learning_profile/titan_learning_profile.dart';
import '../models/recommendation_models.dart';

/// Pure recommendation rules evaluator.
class RecommendationRules {
  const RecommendationRules();

  /// Evaluates overdue items from the Revision Engine queue.
  List<Recommendation> evaluateRevisionQueue(RecommendationContext context) {
    final recommendations = <Recommendation>[];
    final overdueItems =
        context.revisionQueue.items.where((i) => i.isOverdue).toList();

    for (final item in overdueItems) {
      final reason = RecommendationReason(
        code: 'OVERDUE_RECALL',
        title: 'Active Recall Overdue',
        description:
            'Concept [${item.topic}] is overdue for active recall based on SM-2 scheduling.',
        weight: 0.95,
      );

      recommendations.add(
        Recommendation(
          id: 'rec_rev_${item.id}',
          title: 'Review Overdue Concept: ${item.subtopic ?? item.topic}',
          topic: item.topic,
          actionType: 'Active Recall',
          priority: 'Urgent',
          confidence: 0.95,
          source: 'Revision Engine',
          reasons: [reason],
          estimatedStudyTimeMinutes: 10,
        ),
      );
    }

    return recommendations;
  }

  /// Evaluates weak areas identified in the learner's profile.
  List<Recommendation> evaluateLearningProfile(RecommendationContext context) {
    final recommendations = <Recommendation>[];
    final weakTopics = context.profile.weakTopics;

    for (var i = 0; i < weakTopics.length; i++) {
      final topic = weakTopics[i];
      final mastery = context.profile.topicMasteries.firstWhere(
          (m) => m.topic == topic,
          orElse: () => _defaultMastery(topic));

      final reason = RecommendationReason(
        code: 'WEAK_AREA_DEEP_DIVE',
        title: 'Low Topic Accuracy',
        description:
            'Topic [$topic] has a low accuracy of ${mastery.masteryPercentage}%. Focused deep dive recommended.',
        weight: 0.88,
      );

      recommendations.add(
        Recommendation(
          id: 'rec_profile_weak_$i',
          title: 'Deep Dive: $topic Masterclass',
          topic: topic,
          actionType: 'Concept Deep Dive',
          priority: 'High',
          confidence: 0.88,
          source: 'Learning Profile',
          reasons: [reason],
          estimatedStudyTimeMinutes: 25,
        ),
      );
    }

    return recommendations;
  }

  /// Evaluates latest quiz result analytics for immediate follow-up recommendations.
  List<Recommendation> evaluateAnalytics(RecommendationContext context) {
    final recommendations = <Recommendation>[];
    final analytics = context.latestAnalytics;
    if (analytics == null) return recommendations;

    for (final topicPerf in analytics.topicPerformances) {
      if (topicPerf.accuracy < 60.0) {
        final reason = RecommendationReason(
          code: 'RECENT_QUIZ_MISTAKE',
          title: 'Recent Quiz Struggles',
          description:
              'Scored only ${topicPerf.accuracy.toStringAsFixed(0)}% in recent quiz session for [${topicPerf.topic}].',
          weight: 0.90,
        );

        recommendations.add(
          Recommendation(
            id: 'rec_analytics_${topicPerf.topic.toLowerCase().replaceAll(' ', '_')}',
            title: 'Fix Quiz Errors: ${topicPerf.topic}',
            topic: topicPerf.topic,
            actionType: 'Mock Quiz',
            priority: 'High',
            confidence: 0.90,
            source: 'Analytics Engine',
            reasons: [reason],
            estimatedStudyTimeMinutes: 15,
          ),
        );
      }
    }

    return recommendations;
  }

  /// Evaluates Knowledge Engine data for high-yield topics and concepts.
  List<Recommendation> evaluateKnowledgeEngine(RecommendationContext context) {
    final recommendations = <Recommendation>[];

    // 1. Evaluate from latest analytics PYQ correlation
    final analytics = context.latestAnalytics;
    if (analytics != null && analytics.pyqCorrelation.keyPyqTopics.isNotEmpty) {
      for (final pyqTopic in analytics.pyqCorrelation.keyPyqTopics) {
        final reason = RecommendationReason(
          code: 'PYQ_HIGH_YIELD',
          title: 'High-Yield PYQ Pattern',
          description:
              '[$pyqTopic] frequently appears in UPSC previous year question papers.',
          weight: 0.82,
        );

        recommendations.add(
          Recommendation(
            id: 'rec_pyq_${pyqTopic.toLowerCase().replaceAll(' ', '_')}',
            title: 'Practice PYQs: $pyqTopic',
            topic: pyqTopic,
            actionType: 'Practice PYQ',
            priority: 'Medium',
            confidence: 0.82,
            source: 'Knowledge Engine',
            reasons: [reason],
            estimatedStudyTimeMinutes: 20,
          ),
        );
      }
    }

    // 2. Evaluate from Knowledge Objects snapshot
    final knowledgeObjs = context.knowledgeObjects;
    if (knowledgeObjs != null) {
      for (final ko in knowledgeObjs) {
        final reason = RecommendationReason(
          code: 'KNOWLEDGE_GRAPH_PRIORITY',
          title: 'Core Knowledge Node',
          description:
              'Concept node [${ko.title}] is flagged as high priority in the Knowledge Graph.',
          weight: 0.85,
        );

        recommendations.add(
          Recommendation(
            id: 'rec_ke_${ko.id.toLowerCase().replaceAll(' ', '_')}',
            title: 'Study Knowledge Node: ${ko.title}',
            topic: ko.title,
            actionType: 'Concept Deep Dive',
            priority: 'High',
            confidence: 0.85,
            source: 'Knowledge Engine',
            reasons: [reason],
            estimatedStudyTimeMinutes: 15,
          ),
        );
      }
    }

    return recommendations;
  }

  /// Evaluates Knowledge Engine PYQ trends for high-yield topic coverage (backward compatibility).
  List<Recommendation> evaluatePYQTrends(RecommendationContext context) =>
      evaluateKnowledgeEngine(context);

  TopicMastery _defaultMastery(String topic) {
    return TopicMastery(
      topic: topic,
      subject: topic,
      masteryPercentage: 50.0,
      totalAttempted: 10,
      correctCount: 5,
      retentionScore: 50.0,
      lastPracticedAt: DateTime.now(),
      masteryLevel: 'Learning',
    );
  }
}
