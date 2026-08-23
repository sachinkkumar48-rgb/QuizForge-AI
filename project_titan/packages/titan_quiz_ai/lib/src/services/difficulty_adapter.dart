import 'package:titan_quiz/titan_quiz.dart';
import '../models/learner_profile.dart';
import '../models/mastery_trend.dart';
import '../models/topic_mastery.dart';

/// Deterministic difficulty adaptation service calculating optimal challenge levels.
class DifficultyAdapter {
  final double failureThreshold;
  final double masteryThreshold;
  final double minConfidenceForHard;

  const DifficultyAdapter({
    this.failureThreshold = 0.50,
    this.masteryThreshold = 0.80,
    this.minConfidenceForHard = 0.35,
  });

  /// Recommends adapted difficulty for a specific topic based on its mastery and trend metrics.
  QuizDifficulty recommendDifficultyForTopic(
    TopicMastery topicMastery, {
    QuizDifficulty currentDifficulty = QuizDifficulty.medium,
  }) {
    if (!topicMastery.hasAttempted) {
      return currentDifficulty;
    }

    // Repeated failure or declining trend -> Step down difficulty
    if (topicMastery.accuracy < failureThreshold ||
        topicMastery.trend == MasteryTrend.declining ||
        topicMastery.masteryScore < 0.40) {
      switch (currentDifficulty) {
        case QuizDifficulty.hard:
          return QuizDifficulty.medium;
        case QuizDifficulty.medium:
        case QuizDifficulty.mixed:
          return QuizDifficulty.easy;
        case QuizDifficulty.easy:
          return QuizDifficulty.easy;
      }
    }

    // High accuracy & solid confidence -> Step up difficulty
    if (topicMastery.accuracy >= masteryThreshold &&
        topicMastery.confidence >= minConfidenceForHard &&
        topicMastery.trend != MasteryTrend.declining) {
      switch (currentDifficulty) {
        case QuizDifficulty.easy:
          return QuizDifficulty.medium;
        case QuizDifficulty.medium:
        case QuizDifficulty.mixed:
          return QuizDifficulty.hard;
        case QuizDifficulty.hard:
          return QuizDifficulty.hard;
      }
    }

    // Stable performance -> Maintain current
    return currentDifficulty;
  }

  /// Recommends overall difficulty for a learner based on aggregate performance profile.
  QuizDifficulty recommendOverallDifficulty(
    LearnerProfile profile, {
    QuizDifficulty fallback = QuizDifficulty.medium,
  }) {
    if (profile.isEmpty) {
      return fallback;
    }

    if (profile.overallAccuracy < failureThreshold ||
        profile.overallMastery < 0.45) {
      return QuizDifficulty.easy;
    }

    if (profile.overallAccuracy >= masteryThreshold &&
        profile.overallMastery >= 0.75) {
      return QuizDifficulty.hard;
    }

    return QuizDifficulty.medium;
  }
}
