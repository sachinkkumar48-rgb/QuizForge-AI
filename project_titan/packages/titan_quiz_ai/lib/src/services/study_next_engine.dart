import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';
import '../models/learner_profile.dart';
import '../models/mastery_trend.dart';
import '../models/review_schedule_item.dart';
import '../models/study_next_recommendation.dart';
import '../models/topic_mastery.dart';
import 'difficulty_adapter.dart';

/// Deterministic decision engine evaluating learner profile and review schedule to produce the next highest-priority study action.
class StudyNextEngine {
  final DifficultyAdapter difficultyAdapter;

  const StudyNextEngine({
    this.difficultyAdapter = const DifficultyAdapter(),
  });

  /// Evaluates learner status and determines the single most impactful next learning activity.
  StudyNextRecommendation recommendNext({
    required LearnerProfile profile,
    List<ReviewScheduleItem> dueReviewItems = const [],
    String? activeDocumentId,
  }) {
    // 1. First-time / Empty state
    if (profile.isEmpty) {
      return StudyNextRecommendation(
        actionType: StudyNextActionType.startFirstAssessment,
        title: 'Start Your First Assessment',
        description:
            'Complete a diagnostic assessment to generate your personalized learning profile and mastery metrics.',
        documentId: activeDocumentId,
        recommendedDifficulty: QuizDifficulty.medium,
        rationale:
            'No prior assessment data exists. A baseline assessment establishes your knowledge profile.',
      );
    }

    // 2. Priority 1: Overdue spaced reviews
    if (dueReviewItems.isNotEmpty) {
      final item = dueReviewItems.first;
      final deepLink = item.documentId != null && item.pageNumber != null
          ? ReaderDeepLinkRequest(
              documentId: item.documentId!,
              pageNumber: item.pageNumber!,
              chunkId: item.sourceChunkId,
              source: 'study_next_review_due',
            )
          : null;

      return StudyNextRecommendation(
        actionType: StudyNextActionType.reviewDue,
        title: 'Review Due: ${item.topic}',
        description:
            'Scheduled spaced-repetition review is due for "${item.topic}". Reinforce memory before forgetting.',
        targetTopic: item.topic,
        documentId: item.documentId,
        pageNumber: item.pageNumber,
        sourceChunkId: item.sourceChunkId,
        deepLinkRequest: deepLink,
        recommendedDifficulty: QuizDifficulty.medium,
        rationale:
            'Overdue spaced repetition item detected to maximize long-term retention.',
      );
    }

    // 3. Priority 2: Repeated incorrect / zero accuracy topics
    final zeroAccuracyTopics = profile.topicPerformance.values
        .where((t) => t.hasAttempted && t.correct == 0)
        .toList();
    if (zeroAccuracyTopics.isNotEmpty) {
      final topic = zeroAccuracyTopics.first;
      final deepLink = _buildDeepLink(topic, 'study_next_zero_acc');

      return StudyNextRecommendation(
        actionType: StudyNextActionType.remedyWeakTopic,
        title: 'Remediate Weak Area: ${topic.topic}',
        description:
            'You have 0% accuracy on "${topic.topic}". Review source concepts in TITAN Reader.',
        targetTopic: topic.topic,
        documentId: topic.documentId ?? activeDocumentId,
        pageNumber: topic.pageNumbers.isNotEmpty ? topic.pageNumbers.first : 1,
        sourceChunkId:
            topic.sourceChunkIds.isNotEmpty ? topic.sourceChunkIds.first : null,
        deepLinkRequest: deepLink,
        recommendedDifficulty: QuizDifficulty.easy,
        rationale:
            'Repeated incorrect answers require concept re-reading prior to re-testing.',
      );
    }

    // 4. Priority 3: Declining mastery trend
    final decliningTopics = profile.topicPerformance.values
        .where((t) => t.trend == MasteryTrend.declining)
        .toList();
    if (decliningTopics.isNotEmpty) {
      final topic = decliningTopics.first;
      final deepLink = _buildDeepLink(topic, 'study_next_declining');

      return StudyNextRecommendation(
        actionType: StudyNextActionType.reviewDecliningTopic,
        title: 'Strengthen Declining Area: ${topic.topic}',
        description:
            'Recent scores on "${topic.topic}" indicate a downward trend. Review key concepts.',
        targetTopic: topic.topic,
        documentId: topic.documentId ?? activeDocumentId,
        pageNumber: topic.pageNumbers.isNotEmpty ? topic.pageNumbers.first : 1,
        sourceChunkId:
            topic.sourceChunkIds.isNotEmpty ? topic.sourceChunkIds.first : null,
        deepLinkRequest: deepLink,
        recommendedDifficulty:
            difficultyAdapter.recommendDifficultyForTopic(topic),
        rationale:
            'Declining retention signals need prompt intervention to prevent concept gaps.',
      );
    }

    // 5. Priority 4: Weak topics (< 60% mastery)
    if (profile.hasWeakTopics) {
      final weakName = profile.weakTopics.first;
      final topic = profile.topicPerformance[weakName];
      final deepLink =
          topic != null ? _buildDeepLink(topic, 'study_next_weak') : null;

      return StudyNextRecommendation(
        actionType: StudyNextActionType.remedyWeakTopic,
        title: 'Targeted Practice: $weakName',
        description:
            'Mastery is below 60%. Practice targeted questions to build topic proficiency.',
        targetTopic: weakName,
        documentId: topic?.documentId ?? activeDocumentId,
        pageNumber: topic?.pageNumbers.isNotEmpty == true
            ? topic!.pageNumbers.first
            : 1,
        sourceChunkId: topic?.sourceChunkIds.isNotEmpty == true
            ? topic!.sourceChunkIds.first
            : null,
        deepLinkRequest: deepLink,
        recommendedDifficulty: topic != null
            ? difficultyAdapter.recommendDifficultyForTopic(topic)
            : QuizDifficulty.easy,
        rationale:
            'Focused practice on weak topics accelerates overall profile mastery.',
      );
    }

    // 6. Priority 5: Progressive practice on strong or new topics
    final recommendedDiff =
        difficultyAdapter.recommendOverallDifficulty(profile);
    return StudyNextRecommendation(
      actionType: StudyNextActionType.practiceNewTopic,
      title: 'Progressive Mastery Practice',
      description:
          'Your overall mastery is ${(profile.overallMastery * 100).toStringAsFixed(0)}%. Challenge yourself at ${recommendedDiff.name.toUpperCase()} level.',
      documentId: activeDocumentId,
      recommendedDifficulty: recommendedDiff,
      rationale:
          'All current topics in stable or strong standing. Continue curriculum progression.',
    );
  }

  ReaderDeepLinkRequest? _buildDeepLink(TopicMastery topic, String sourceTag) {
    if (topic.documentId == null && topic.pageNumbers.isEmpty) return null;
    return ReaderDeepLinkRequest(
      documentId: topic.documentId ?? 'document',
      pageNumber: topic.pageNumbers.isNotEmpty ? topic.pageNumbers.first : 1,
      chunkId:
          topic.sourceChunkIds.isNotEmpty ? topic.sourceChunkIds.first : null,
      source: sourceTag,
    );
  }
}
