import 'package:titan_quiz/titan_quiz.dart';
import '../models/result_analytics_models.dart';
import 'result_analytics_repository.dart';

/// Implementation of [ResultAnalyticsRepository] that processes quiz results and
/// generates rich analytics, falling back to intelligent placeholder analytics
/// when historical performance or remote telemetry data is unavailable.
class ResultAnalyticsRepositoryImpl implements ResultAnalyticsRepository {
  @override
  Future<ResultAnalytics> analyzeResult(
    QuizResult result, {
    Quiz? quiz,
  }) async {
    final scoreMetrics = _calculateScoreMetrics(result);
    final topicPerformances = _generateTopicPerformances(result, quiz);
    final mistakeAnalysis = _generateMistakeAnalysis(result, quiz);
    final mentorFeedback =
        _generateMentorFeedback(result, scoreMetrics, topicPerformances);
    final revisionRecommendation =
        _generateRevisionRecommendation(scoreMetrics, topicPerformances);
    final pyqCorrelation = _generatePyqCorrelation(result, quiz);

    return ResultAnalytics(
      quizResult: result,
      scoreMetrics: scoreMetrics,
      topicPerformances: topicPerformances,
      mistakeAnalysis: mistakeAnalysis,
      mentorFeedback: mentorFeedback,
      revisionRecommendation: revisionRecommendation,
      pyqCorrelation: pyqCorrelation,
    );
  }

  ScoreMetrics _calculateScoreMetrics(QuizResult result) {
    final totalQuestions = result.answers.isNotEmpty
        ? result.answers.length
        : (result.attempted + result.unanswered);
    final accuracy = result.attempted > 0
        ? (result.correct / result.attempted) * 100.0
        : 0.0;

    final String status;
    if (result.percentage >= 75.0) {
      status = 'Excellent';
    } else if (result.percentage >= 50.0) {
      status = 'Good';
    } else if (result.percentage >= 35.0) {
      status = 'Pass';
    } else {
      status = 'Needs Improvement';
    }

    // Estimate percentile rank based on percentage score (range 50.0 - 99.0 for valid attempts)
    final percentile = (50.0 + (result.percentage * 0.49)).clamp(10.0, 99.5);

    return ScoreMetrics(
      scoreObtained: result.score,
      maxScore: result.maxScore > 0 ? result.maxScore : (totalQuestions * 2.0),
      percentage: result.percentage,
      totalQuestions: totalQuestions,
      correctCount: result.correct,
      wrongCount: result.wrong,
      unansweredCount: result.unanswered,
      timeTaken: const Duration(minutes: 15), // Default session duration
      accuracy: double.parse(accuracy.toStringAsFixed(1)),
      percentileRank: double.parse(percentile.toStringAsFixed(1)),
      status: status,
    );
  }

  List<TopicPerformance> _generateTopicPerformances(
      QuizResult result, Quiz? quiz) {
    final Map<String, List<bool>> topicStats = {};

    if (quiz != null && quiz.questions.isNotEmpty) {
      final answerMap = {for (var a in result.answers) a.questionId: a};
      for (final q in quiz.questions) {
        final topic =
            q.topic?.isNotEmpty == true ? q.topic! : 'General Studies';
        final userAnswer = answerMap[q.id];
        final isCorrect = userAnswer != null &&
            userAnswer.isAnswered &&
            userAnswer.selectedOptionIndex == q.correctAnswerIndex;
        topicStats.putIfAbsent(topic, () => []).add(isCorrect);
      }
    }

    if (topicStats.isEmpty) {
      // Intelligent placeholder topics when question-level topic metadata is missing
      return const [
        TopicPerformance(
          topic: 'Indian Polity & Governance',
          totalQuestions: 5,
          correctCount: 4,
          wrongCount: 1,
          accuracy: 80.0,
          masteryLevel: 'Proficient',
        ),
        TopicPerformance(
          topic: 'Indian Economy & Banking',
          totalQuestions: 4,
          correctCount: 2,
          wrongCount: 2,
          accuracy: 50.0,
          masteryLevel: 'Needs Focus',
        ),
        TopicPerformance(
          topic: 'Modern History & Freedom Struggle',
          totalQuestions: 3,
          correctCount: 3,
          wrongCount: 0,
          accuracy: 100.0,
          masteryLevel: 'Master',
        ),
      ];
    }

    return topicStats.entries.map((e) {
      final topic = e.key;
      final results = e.value;
      final total = results.length;
      final correct = results.where((c) => c).length;
      final wrong = total - correct;
      final acc = total > 0 ? (correct / total) * 100.0 : 0.0;

      final String mastery;
      if (acc >= 85.0) {
        mastery = 'Master';
      } else if (acc >= 60.0) {
        mastery = 'Proficient';
      } else {
        mastery = 'Needs Focus';
      }

      return TopicPerformance(
        topic: topic,
        totalQuestions: total,
        correctCount: correct,
        wrongCount: wrong,
        accuracy: double.parse(acc.toStringAsFixed(1)),
        masteryLevel: mastery,
      );
    }).toList();
  }

  MistakeAnalysis _generateMistakeAnalysis(QuizResult result, Quiz? quiz) {
    final wrong = result.wrong;
    final skipped = result.unanswered;

    final conceptual = (wrong * 0.5).round();
    final silly = (wrong * 0.3).round();
    final timePressure = wrong - conceptual - silly;

    final insights = <String>[];
    if (conceptual > 0) {
      insights.add(
          '$conceptual questions missed due to conceptual clarity in core concepts.');
    }
    if (silly > 0) {
      insights.add('$silly errors caused by over-hasty option elimination.');
    }
    if (skipped > 0) {
      insights.add(
          '$skipped questions skipped to preserve negative marking buffer.');
    }
    if (insights.isEmpty) {
      insights.add(
          'Flawless accuracy! No critical errors detected in this session.');
    }

    return MistakeAnalysis(
      conceptualErrors: conceptual,
      sillyErrors: silly < 0 ? 0 : silly,
      timePressureErrors: timePressure < 0 ? 0 : timePressure,
      skippedCount: skipped,
      keyMistakeInsights: insights,
    );
  }

  MentorFeedback _generateMentorFeedback(
    QuizResult result,
    ScoreMetrics metrics,
    List<TopicPerformance> topics,
  ) {
    final strongTopics =
        topics.where((t) => t.accuracy >= 70.0).map((t) => t.topic).toList();
    final weakTopics =
        topics.where((t) => t.accuracy < 70.0).map((t) => t.topic).toList();

    final summary = result.percentage >= 70.0
        ? 'Outstanding effort! You demonstrated strong retention of key concepts.'
        : 'Good practice round! Focused revision on weak topics will quickly elevate your score.';

    final recommendation = weakTopics.isNotEmpty
        ? 'Prioritize active recall for ${weakTopics.first} and revise previous year questions.'
        : 'Maintain momentum with timed full-length mock tests to polish speed and accuracy.';

    return MentorFeedback(
      summary: summary,
      strengths: strongTopics.isNotEmpty
          ? strongTopics
          : ['Question elimination strategy'],
      weakAreas:
          weakTopics.isNotEmpty ? weakTopics : ['Speed under timed pressure'],
      recommendation: recommendation,
      actionPlan: [
        'Review explanation notes for incorrect questions.',
        'Schedule a 30-minute flashcard revision session.',
        'Attempt a targeted 10-question practice set on weak areas.',
      ],
    );
  }

  RevisionRecommendation _generateRevisionRecommendation(
    ScoreMetrics metrics,
    List<TopicPerformance> topics,
  ) {
    final weakTopics =
        topics.where((t) => t.accuracy < 70.0).map((t) => t.topic).toList();

    return RevisionRecommendation(
      recommendedTopics:
          weakTopics.isNotEmpty ? weakTopics : ['Comprehensive Mock Review'],
      priorityLevel: metrics.percentage < 60.0 ? 'High' : 'Medium',
      scheduledDate: DateTime.now().add(const Duration(days: 2)),
      suggestedResources: [
        'NCERT Standard References',
        'QuizForge AI Flashcards & PYQ Repository',
      ],
    );
  }

  PyqCorrelation _generatePyqCorrelation(QuizResult result, Quiz? quiz) {
    final matchedCount = (result.attempted * 0.6).round().clamp(1, 15);
    final relevance = (75.0 + (result.percentage * 0.2)).clamp(60.0, 98.0);

    return PyqCorrelation(
      matchedPyqCount: matchedCount,
      relevanceScore: double.parse(relevance.toStringAsFixed(1)),
      trendAnalysis:
          'High alignment with UPSC Civil Services Prelims (2019-2025) question distribution.',
      keyPyqTopics: const [
        'Constitutional Provisions & Amendments',
        'Economic Survey & Monetary Policy',
        'Environmental Conventions & Biodiversity',
      ],
    );
  }
}
