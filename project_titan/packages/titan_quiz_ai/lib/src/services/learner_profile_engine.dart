import 'package:titan_quiz/titan_quiz.dart';
import '../models/answer_status.dart';
import '../models/assessment_performance.dart';
import '../models/assessment_question_type.dart';
import '../models/interactive_question_state.dart';
import '../models/learner_profile.dart';
import '../models/mastery_trend.dart';
import '../models/retention_signal.dart';
import '../models/topic_mastery.dart';

/// Deterministic engine calculating mathematical updates to learner profiles upon assessment completion.
class LearnerProfileEngine {
  final double weakTopicThreshold;
  final double strongTopicThreshold;

  const LearnerProfileEngine({
    this.weakTopicThreshold = 0.60,
    this.strongTopicThreshold = 0.80,
  });

  /// Evaluates and updates a [LearnerProfile] with results from a newly completed assessment session.
  LearnerProfile updateProfile({
    required LearnerProfile currentProfile,
    required Quiz quiz,
    required AssessmentPerformance performance,
    required Map<String, InteractiveQuestionState> questionStates,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();

    // 1. Update overall assessment and question aggregates
    final newTotalAssessments = currentProfile.totalAssessments + 1;
    final newTotalQuestions =
        currentProfile.totalQuestionsAttempted + performance.answeredQuestions;
    final newTotalCorrect =
        currentProfile.totalCorrect + performance.correctAnswers;
    final newTotalIncorrect =
        currentProfile.totalIncorrect + performance.incorrectAnswers;
    final newOverallAccuracy = newTotalQuestions > 0
        ? (newTotalCorrect / newTotalQuestions).clamp(0.0, 1.0)
        : 0.0;

    // 2. Update recent performance tracking (rolling window of last 10)
    final recent = List<double>.from(currentProfile.recentPerformance)
      ..add(performance.percentage / 100.0);
    if (recent.length > 10) {
      recent.removeAt(0);
    }

    // 3. Update Question Type Performance
    final updatedTypePerf = Map<AssessmentQuestionType, double>.from(
        currentProfile.questionTypePerformance);
    for (final entry in performance.accuracyByType.entries) {
      final prev = updatedTypePerf[entry.key];
      updatedTypePerf[entry.key] =
          prev != null ? ((prev + entry.value) / 2.0) : entry.value;
    }

    // 4. Update Difficulty Performance
    final updatedDiffPerf =
        Map<QuizDifficulty, double>.from(currentProfile.difficultyPerformance);
    final currentDiffAcc = performance.totalQuestions > 0
        ? (performance.correctAnswers / performance.totalQuestions)
            .clamp(0.0, 1.0)
        : 0.0;
    final prevDiffAcc = updatedDiffPerf[quiz.difficulty];
    updatedDiffPerf[quiz.difficulty] = prevDiffAcc != null
        ? ((prevDiffAcc + currentDiffAcc) / 2.0)
        : currentDiffAcc;

    // 5. Update Topic Mastery per topic tested in this assessment
    final updatedTopicPerf =
        Map<String, TopicMastery>.from(currentProfile.topicPerformance);
    final testedTopics = <String>{};

    for (final q in quiz.questions) {
      final topic =
          q.topic?.trim().isNotEmpty == true ? q.topic!.trim() : 'General';
      testedTopics.add(topic);
    }

    for (final topic in testedTopics) {
      final existingMastery =
          updatedTopicPerf[topic] ?? TopicMastery.initial(topic);

      final topicQuestions = quiz.questions.where((q) {
        final qTopic =
            q.topic?.trim().isNotEmpty == true ? q.topic!.trim() : 'General';
        return qTopic == topic;
      }).toList();

      var sessionCorrect = 0;
      var sessionIncorrect = 0;
      final sessionChunks = <String>{...existingMastery.sourceChunkIds};
      final sessionPages = <int>{...existingMastery.pageNumbers};

      for (final q in topicQuestions) {
        final state = questionStates[q.id];
        if (state != null) {
          if (state.status == AnswerStatus.correct) {
            sessionCorrect++;
          } else if (state.status == AnswerStatus.incorrect) {
            sessionIncorrect++;
          }
          if (state.sourceChunkId != null)
            sessionChunks.add(state.sourceChunkId!);
          if (state.pageNumber != null) sessionPages.add(state.pageNumber!);
        } else if (q.pageReference != null) {
          sessionPages.add(q.pageReference!);
        }
      }

      final sessionTotal = sessionCorrect + sessionIncorrect;
      if (sessionTotal == 0) continue;

      final sessionAccuracy = sessionCorrect / sessionTotal;
      final newAttempts = existingMastery.attempts + sessionTotal;
      final newCorrect = existingMastery.correct + sessionCorrect;
      final newIncorrect = existingMastery.incorrect + sessionIncorrect;
      final newAccuracy = (newCorrect / newAttempts).clamp(0.0, 1.0);

      // Rolling topic accuracy history
      final history = List<double>.from(existingMastery.historyAccuracies)
        ..add(sessionAccuracy);
      if (history.length > 5) {
        history.removeAt(0);
      }

      // Bayesian bounded mastery calculation with recency weight
      final baseBayesian = (newCorrect + 1.0) / (newAttempts + 2.0);
      final masteryScore = history.length >= 2
          ? ((0.6 * sessionAccuracy) + (0.4 * baseBayesian)).clamp(0.0, 1.0)
          : baseBayesian.clamp(0.0, 1.0);

      // Confidence metric based on cumulative attempts
      final confidence = (newAttempts / (newAttempts + 5.0)).clamp(0.0, 1.0);

      // Trend and Retention Signal calculation
      final MasteryTrend trend;
      final RetentionSignal retention;
      if (history.length >= 2) {
        final prev = history[history.length - 2];
        final delta = sessionAccuracy - prev;
        if (delta >= 0.15) {
          trend = MasteryTrend.improving;
          retention = RetentionSignal.improving;
        } else if (delta <= -0.15) {
          trend = MasteryTrend.declining;
          retention = RetentionSignal.declining;
        } else {
          trend = MasteryTrend.stable;
          retention = RetentionSignal.stable;
        }
      } else {
        trend = MasteryTrend.insufficientData;
        retention = RetentionSignal.insufficientData;
      }

      // Streak tracking
      final newStreak =
          sessionAccuracy == 1.0 ? existingMastery.consecutiveCorrect + 1 : 0;

      final updatedMastery = TopicMastery(
        topic: topic,
        attempts: newAttempts,
        correct: newCorrect,
        incorrect: newIncorrect,
        accuracy: newAccuracy,
        masteryScore: masteryScore,
        confidence: confidence,
        trend: trend,
        retention: retention,
        consecutiveCorrect: newStreak,
        lastAttemptAt: now,
        sourceChunkIds: sessionChunks.toList(),
        pageNumbers: sessionPages.toList()..sort(),
        documentId: quiz.sourceDocumentId ?? existingMastery.documentId,
        historyAccuracies: history,
      );

      updatedTopicPerf[topic] = updatedMastery;
    }

    // 6. Aggregate weak and strong topics
    final weakTopics = <String>[];
    final strongTopics = <String>[];
    final masteryLevels = <String, double>{};
    var sumMastery = 0.0;

    for (final entry in updatedTopicPerf.entries) {
      masteryLevels[entry.key] = entry.value.masteryScore;
      sumMastery += entry.value.masteryScore;

      if (entry.value.isWeak) {
        weakTopics.add(entry.key);
      } else if (entry.value.isStrong) {
        strongTopics.add(entry.key);
      }
    }

    final overallMastery = updatedTopicPerf.isNotEmpty
        ? (sumMastery / updatedTopicPerf.length).clamp(0.0, 1.0)
        : 0.0;

    return LearnerProfile(
      learnerId: currentProfile.learnerId,
      totalAssessments: newTotalAssessments,
      totalQuestionsAttempted: newTotalQuestions,
      totalCorrect: newTotalCorrect,
      totalIncorrect: newTotalIncorrect,
      overallAccuracy: newOverallAccuracy,
      overallMastery: overallMastery,
      topicPerformance: updatedTopicPerf,
      questionTypePerformance: updatedTypePerf,
      difficultyPerformance: updatedDiffPerf,
      recentPerformance: recent,
      weakTopics: weakTopics,
      strongTopics: strongTopics,
      masteryLevels: masteryLevels,
      lastUpdated: now,
    );
  }
}
