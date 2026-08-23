import 'package:titan_quiz/titan_quiz.dart';
import '../models/adaptive_assessment_plan.dart';
import '../models/assessment_blueprint.dart';
import '../models/learner_profile.dart';
import '../models/review_schedule_item.dart';
import 'difficulty_adapter.dart';

/// Deterministic strategy engine generating targeted adaptive assessment plans from learner history.
class AdaptiveAssessmentStrategy {
  final DifficultyAdapter difficultyAdapter;
  final int defaultQuestionCount;

  const AdaptiveAssessmentStrategy({
    this.difficultyAdapter = const DifficultyAdapter(),
    this.defaultQuestionCount = 5,
  });

  /// Generates a tailored [AdaptiveAssessmentPlan] prioritizing weak areas, review items, and optimal difficulty.
  AdaptiveAssessmentPlan createPlan({
    required LearnerProfile profile,
    required AssessmentBlueprint baseBlueprint,
    List<ReviewScheduleItem> dueReviewItems = const [],
    List<String> recentQuestionIds = const [],
    int? targetQuestionCount,
  }) {
    final count = targetQuestionCount ?? baseBlueprint.targetQuestions;
    final recommendedDifficulty = difficultyAdapter.recommendOverallDifficulty(
      profile,
      fallback: baseBlueprint.difficulty,
    );

    // 1. Identify target topics prioritizing weak topics and due review topics
    final targetTopics = <String>[];
    final remedialTopics = <String>[];
    final targetChunks = <String>{...baseBlueprint.selectedChunkIds};

    for (final weak in profile.weakTopics) {
      if (!targetTopics.contains(weak)) {
        targetTopics.add(weak);
        remedialTopics.add(weak);
      }
      final mastery = profile.topicPerformance[weak];
      if (mastery != null) {
        targetChunks.addAll(mastery.sourceChunkIds);
      }
    }

    for (final reviewItem in dueReviewItems) {
      if (!targetTopics.contains(reviewItem.topic)) {
        targetTopics.add(reviewItem.topic);
      }
      if (reviewItem.sourceChunkId != null) {
        targetChunks.add(reviewItem.sourceChunkId!);
      }
    }

    // 2. Formulate strategic rationale
    final String rationale;
    if (profile.isEmpty) {
      rationale =
          'Initial baseline assessment configured at standard ${recommendedDifficulty.name} difficulty.';
    } else if (remedialTopics.isNotEmpty) {
      rationale =
          'Remedial practice targeting weak areas (${remedialTopics.join(', ')}) adapted to ${recommendedDifficulty.name} difficulty.';
    } else if (dueReviewItems.isNotEmpty) {
      rationale =
          'Spaced review assessment addressing ${dueReviewItems.length} due items.';
    } else {
      rationale =
          'Progression practice challenging learner at ${recommendedDifficulty.name} difficulty.';
    }

    // 3. Build executable AssessmentBlueprint
    final topicHint = targetTopics.isNotEmpty
        ? targetTopics.join(', ')
        : baseBlueprint.topicHint;
    final adaptedBlueprint = baseBlueprint.copyWith(
      targetQuestions: count,
      difficulty: recommendedDifficulty,
      topicHint: topicHint,
      selectedChunkIds: targetChunks.toList(),
      title: baseBlueprint.title ??
          'Adaptive Practice (${recommendedDifficulty.name.toUpperCase()})',
      description: baseBlueprint.description ?? rationale,
    );

    return AdaptiveAssessmentPlan(
      recommendedDifficulty: recommendedDifficulty,
      targetTopics: targetTopics,
      questionCount: count,
      remedialTopics: remedialTopics,
      sourceChunks: targetChunks.toList(),
      rationale: rationale,
      confidence: profile.isEmpty
          ? 0.5
          : (profile.totalQuestionsAttempted >= 10 ? 1.0 : 0.8),
      blueprint: adaptedBlueprint,
    );
  }

  /// Deterministically ranks candidate questions for adaptive selection.
  List<QuizQuestion> rankQuestions({
    required List<QuizQuestion> candidates,
    required LearnerProfile profile,
    List<String> dueQuestionIds = const [],
    List<String> recentQuestionIds = const [],
    QuizDifficulty? targetDifficulty,
  }) {
    if (candidates.isEmpty) return const [];

    final scored = candidates.map((q) {
      var score = 0.0;
      final topic =
          q.topic?.trim().isNotEmpty == true ? q.topic!.trim() : 'General';
      final mastery = profile.topicPerformance[topic];

      // 1. Weak topic boost
      if (profile.weakTopics.contains(topic)) {
        score += 50.0;
      }
      if (mastery != null) {
        // Lower mastery score = higher priority
        score += (1.0 - mastery.masteryScore) * 30.0;
      }

      // 2. Overdue review item boost
      if (dueQuestionIds.contains(q.id)) {
        score += 40.0;
      }

      // 3. Target difficulty alignment
      if (targetDifficulty != null && q.difficulty == targetDifficulty) {
        score += 20.0;
      }

      // 4. Repetition avoidance: penalty for recently asked questions
      if (recentQuestionIds.contains(q.id) && !dueQuestionIds.contains(q.id)) {
        score -= 80.0;
      }

      return MapEntry(q, score);
    }).toList();

    // Sort descending by score
    scored.sort((a, b) => b.value.compareTo(a.value));
    return List.unmodifiable(scored.map((e) => e.key).toList());
  }
}
