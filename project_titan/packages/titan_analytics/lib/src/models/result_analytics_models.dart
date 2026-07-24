import 'package:meta/meta.dart';
import 'package:titan_quiz/titan_quiz.dart';

/// Performance scoring metrics for a quiz attempt.
@immutable
class ScoreMetrics {
  final double scoreObtained;
  final double maxScore;
  final double percentage;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int unansweredCount;
  final Duration timeTaken;
  final double accuracy;
  final double percentileRank;
  final String status;

  const ScoreMetrics({
    required this.scoreObtained,
    required this.maxScore,
    required this.percentage,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.unansweredCount,
    required this.timeTaken,
    required this.accuracy,
    required this.percentileRank,
    required this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreMetrics &&
          runtimeType == other.runtimeType &&
          scoreObtained == other.scoreObtained &&
          maxScore == other.maxScore &&
          percentage == other.percentage &&
          totalQuestions == other.totalQuestions &&
          correctCount == other.correctCount &&
          wrongCount == other.wrongCount &&
          unansweredCount == other.unansweredCount &&
          timeTaken == other.timeTaken &&
          accuracy == other.accuracy &&
          percentileRank == other.percentileRank &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
        scoreObtained,
        maxScore,
        percentage,
        totalQuestions,
        correctCount,
        wrongCount,
        unansweredCount,
        timeTaken,
        accuracy,
        percentileRank,
        status,
      );
}

/// Performance analysis per topic.
@immutable
class TopicPerformance {
  final String topic;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final double accuracy;
  final String masteryLevel;

  const TopicPerformance({
    required this.topic,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.accuracy,
    required this.masteryLevel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicPerformance &&
          runtimeType == other.runtimeType &&
          topic == other.topic &&
          totalQuestions == other.totalQuestions &&
          correctCount == other.correctCount &&
          wrongCount == other.wrongCount &&
          accuracy == other.accuracy &&
          masteryLevel == other.masteryLevel;

  @override
  int get hashCode => Object.hash(
        topic,
        totalQuestions,
        correctCount,
        wrongCount,
        accuracy,
        masteryLevel,
      );
}

/// Categorized mistake analysis.
@immutable
class MistakeAnalysis {
  final int conceptualErrors;
  final int sillyErrors;
  final int timePressureErrors;
  final int skippedCount;
  final List<String> keyMistakeInsights;

  MistakeAnalysis({
    required this.conceptualErrors,
    required this.sillyErrors,
    required this.timePressureErrors,
    required this.skippedCount,
    required List<String> keyMistakeInsights,
  }) : keyMistakeInsights = List<String>.unmodifiable(keyMistakeInsights);

  const MistakeAnalysis.constAnalysis({
    required this.conceptualErrors,
    required this.sillyErrors,
    required this.timePressureErrors,
    required this.skippedCount,
    required this.keyMistakeInsights,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MistakeAnalysis &&
          runtimeType == other.runtimeType &&
          conceptualErrors == other.conceptualErrors &&
          sillyErrors == other.sillyErrors &&
          timePressureErrors == other.timePressureErrors &&
          skippedCount == other.skippedCount &&
          _listEquals(keyMistakeInsights, other.keyMistakeInsights);

  @override
  int get hashCode => Object.hash(
        conceptualErrors,
        sillyErrors,
        timePressureErrors,
        skippedCount,
        Object.hashAll(keyMistakeInsights),
      );
}

/// AI Mentor personalized guidance and insights.
@immutable
class MentorFeedback {
  final String summary;
  final List<String> strengths;
  final List<String> weakAreas;
  final String recommendation;
  final List<String> actionPlan;

  MentorFeedback({
    required this.summary,
    required List<String> strengths,
    required List<String> weakAreas,
    required this.recommendation,
    required List<String> actionPlan,
  })  : strengths = List<String>.unmodifiable(strengths),
        weakAreas = List<String>.unmodifiable(weakAreas),
        actionPlan = List<String>.unmodifiable(actionPlan);

  const MentorFeedback.constFeedback({
    required this.summary,
    required this.strengths,
    required this.weakAreas,
    required this.recommendation,
    required this.actionPlan,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentorFeedback &&
          runtimeType == other.runtimeType &&
          summary == other.summary &&
          recommendation == other.recommendation &&
          _listEquals(strengths, other.strengths) &&
          _listEquals(weakAreas, other.weakAreas) &&
          _listEquals(actionPlan, other.actionPlan);

  @override
  int get hashCode => Object.hash(
        summary,
        recommendation,
        Object.hashAll(strengths),
        Object.hashAll(weakAreas),
        Object.hashAll(actionPlan),
      );
}

/// Spaced-repetition and topic revision scheduling.
@immutable
class RevisionRecommendation {
  final List<String> recommendedTopics;
  final String priorityLevel;
  final DateTime scheduledDate;
  final List<String> suggestedResources;

  RevisionRecommendation({
    required List<String> recommendedTopics,
    required this.priorityLevel,
    required this.scheduledDate,
    required List<String> suggestedResources,
  })  : recommendedTopics = List<String>.unmodifiable(recommendedTopics),
        suggestedResources = List<String>.unmodifiable(suggestedResources);

  const RevisionRecommendation.constRecommendation({
    required this.recommendedTopics,
    required this.priorityLevel,
    required this.scheduledDate,
    required this.suggestedResources,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RevisionRecommendation &&
          runtimeType == other.runtimeType &&
          priorityLevel == other.priorityLevel &&
          scheduledDate == other.scheduledDate &&
          _listEquals(recommendedTopics, other.recommendedTopics) &&
          _listEquals(suggestedResources, other.suggestedResources);

  @override
  int get hashCode => Object.hash(
        priorityLevel,
        scheduledDate,
        Object.hashAll(recommendedTopics),
        Object.hashAll(suggestedResources),
      );
}

/// PYQ (Previous Year Questions) correlation metrics.
@immutable
class PyqCorrelation {
  final int matchedPyqCount;
  final double relevanceScore;
  final String trendAnalysis;
  final List<String> keyPyqTopics;

  PyqCorrelation({
    required this.matchedPyqCount,
    required this.relevanceScore,
    required this.trendAnalysis,
    required List<String> keyPyqTopics,
  }) : keyPyqTopics = List<String>.unmodifiable(keyPyqTopics);

  const PyqCorrelation.constCorrelation({
    required this.matchedPyqCount,
    required this.relevanceScore,
    required this.trendAnalysis,
    required this.keyPyqTopics,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PyqCorrelation &&
          runtimeType == other.runtimeType &&
          matchedPyqCount == other.matchedPyqCount &&
          relevanceScore == other.relevanceScore &&
          trendAnalysis == other.trendAnalysis &&
          _listEquals(keyPyqTopics, other.keyPyqTopics);

  @override
  int get hashCode => Object.hash(
        matchedPyqCount,
        relevanceScore,
        trendAnalysis,
        Object.hashAll(keyPyqTopics),
      );
}

/// Comprehensive analytics model for the Intelligent Results Dashboard.
@immutable
class ResultAnalytics {
  final QuizResult quizResult;
  final ScoreMetrics scoreMetrics;
  final List<TopicPerformance> topicPerformances;
  final MistakeAnalysis mistakeAnalysis;
  final MentorFeedback mentorFeedback;
  final RevisionRecommendation revisionRecommendation;
  final PyqCorrelation pyqCorrelation;

  ResultAnalytics({
    required this.quizResult,
    required this.scoreMetrics,
    required List<TopicPerformance> topicPerformances,
    required this.mistakeAnalysis,
    required this.mentorFeedback,
    required this.revisionRecommendation,
    required this.pyqCorrelation,
  }) : topicPerformances =
            List<TopicPerformance>.unmodifiable(topicPerformances);

  const ResultAnalytics.constAnalytics({
    required this.quizResult,
    required this.scoreMetrics,
    required this.topicPerformances,
    required this.mistakeAnalysis,
    required this.mentorFeedback,
    required this.revisionRecommendation,
    required this.pyqCorrelation,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultAnalytics &&
          runtimeType == other.runtimeType &&
          quizResult == other.quizResult &&
          scoreMetrics == other.scoreMetrics &&
          mistakeAnalysis == other.mistakeAnalysis &&
          mentorFeedback == other.mentorFeedback &&
          revisionRecommendation == other.revisionRecommendation &&
          pyqCorrelation == other.pyqCorrelation &&
          _listEquals(topicPerformances, other.topicPerformances);

  @override
  int get hashCode => Object.hash(
        quizResult,
        scoreMetrics,
        Object.hashAll(topicPerformances),
        mistakeAnalysis,
        mentorFeedback,
        revisionRecommendation,
        pyqCorrelation,
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
