import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';
import '../models/answer_status.dart';
import '../models/assessment_performance.dart';
import '../models/assessment_question_type.dart';
import '../models/interactive_question_state.dart';
import '../models/remedial_study_recommendation.dart';

/// Deterministic performance evaluation and remedial study recommendation service.
class AssessmentPerformanceAnalyzer {
  final double weakTopicThreshold;
  final double strongTopicThreshold;

  const AssessmentPerformanceAnalyzer({
    this.weakTopicThreshold = 0.60,
    this.strongTopicThreshold = 0.80,
  });

  /// Evaluates an interactive session's performance metrics deterministically.
  AssessmentPerformance analyzePerformance({
    required Quiz quiz,
    required Map<String, InteractiveQuestionState> questionStates,
  }) {
    final totalQuestions = quiz.questions.length;
    var correctCount = 0;
    var incorrectCount = 0;
    var unansweredCount = 0;
    var totalScore = 0.0;
    var maxPossibleScore = 0.0;

    final typeCorrect = <AssessmentQuestionType, int>{};
    final typeTotal = <AssessmentQuestionType, int>{};

    final topicCorrect = <String, int>{};
    final topicTotal = <String, int>{};

    final reviewQuestionIds = <String>[];
    final incorrectQuestionIds = <String>[];
    final unansweredQuestionIds = <String>[];

    for (final q in quiz.questions) {
      maxPossibleScore += q.marks;
      final state = questionStates[q.id];
      final topic =
          q.topic?.trim().isNotEmpty == true ? q.topic!.trim() : 'General';
      final qType = state?.questionType ?? AssessmentQuestionType.mcq;

      typeTotal[qType] = (typeTotal[qType] ?? 0) + 1;
      topicTotal[topic] = (topicTotal[topic] ?? 0) + 1;

      if (state == null || state.status == AnswerStatus.unanswered) {
        unansweredCount++;
        unansweredQuestionIds.add(q.id);
      } else if (state.status == AnswerStatus.correct) {
        correctCount++;
        totalScore += q.marks;
        typeCorrect[qType] = (typeCorrect[qType] ?? 0) + 1;
        topicCorrect[topic] = (topicCorrect[topic] ?? 0) + 1;
      } else if (state.status == AnswerStatus.incorrect) {
        incorrectCount++;
        totalScore = (totalScore - q.negativeMarks).clamp(0.0, double.infinity);
        incorrectQuestionIds.add(q.id);
      }

      if (state?.isMarkedForReview == true) {
        reviewQuestionIds.add(q.id);
      }
    }

    final percentage = maxPossibleScore > 0
        ? ((totalScore / maxPossibleScore) * 100).clamp(0.0, 100.0)
        : 0.0;

    final accuracyByType = <AssessmentQuestionType, double>{};
    for (final entry in typeTotal.entries) {
      final correct = typeCorrect[entry.key] ?? 0;
      accuracyByType[entry.key] = correct / entry.value;
    }

    final accuracyByTopic = <String, double>{};
    final weakTopics = <String>[];
    final strongTopics = <String>[];

    for (final entry in topicTotal.entries) {
      final topic = entry.key;
      final total = entry.value;
      final correct = topicCorrect[topic] ?? 0;
      final acc = correct / total;
      accuracyByTopic[topic] = acc;

      if (acc < weakTopicThreshold) {
        weakTopics.add(topic);
      } else if (acc >= strongTopicThreshold) {
        strongTopics.add(topic);
      }
    }

    return AssessmentPerformance(
      totalQuestions: totalQuestions,
      answeredQuestions: correctCount + incorrectCount,
      correctAnswers: correctCount,
      incorrectAnswers: incorrectCount,
      unansweredQuestions: unansweredCount,
      score: totalScore,
      maxScore: maxPossibleScore,
      percentage: percentage,
      accuracyByType: accuracyByType,
      accuracyByTopic: accuracyByTopic,
      weakTopics: weakTopics,
      strongTopics: strongTopics,
      reviewQuestionIds: reviewQuestionIds,
      incorrectQuestionIds: incorrectQuestionIds,
      unansweredQuestionIds: unansweredQuestionIds,
    );
  }

  /// Generates structured remedial recommendations connecting weak topics back to source document pages.
  List<RemedialStudyRecommendation> generateRemedialRecommendations({
    required Quiz quiz,
    required AssessmentPerformance performance,
    required Map<String, InteractiveQuestionState> questionStates,
  }) {
    final recommendations = <RemedialStudyRecommendation>[];
    final docId = quiz.sourceDocumentId ?? 'document';

    for (var i = 0; i < performance.weakTopics.length; i++) {
      final topic = performance.weakTopics[i];
      final topicQuestions = quiz.questions.where((q) {
        final qTopic =
            q.topic?.trim().isNotEmpty == true ? q.topic!.trim() : 'General';
        return qTopic == topic;
      }).toList();

      final sourceChunks = <String>{};
      final pages = <int>{};

      for (final q in topicQuestions) {
        final state = questionStates[q.id];
        if (state?.sourceChunkId != null) {
          sourceChunks.add(state!.sourceChunkId!);
        }
        if (state?.pageNumber != null) {
          pages.add(state!.pageNumber!);
        } else if (q.pageReference != null) {
          pages.add(q.pageReference!);
        }
      }

      final pageList = pages.toList()..sort();
      final primaryPage = pageList.isNotEmpty ? pageList.first : 1;
      final primaryChunk = sourceChunks.isNotEmpty ? sourceChunks.first : null;
      final accuracy = performance.accuracyByTopic[topic] ?? 0.0;

      final deepLink = ReaderDeepLinkRequest(
        documentId: docId,
        pageNumber: primaryPage,
        chunkId: primaryChunk,
        source: 'remedial_study_loop',
      );

      recommendations.add(
        RemedialStudyRecommendation(
          id: 'rem_${quiz.id}_$i',
          documentId: docId,
          topic: topic,
          sourceChunkIds: sourceChunks.toList(),
          pageNumbers: pageList,
          reason:
              'Accuracy on "$topic" was ${(accuracy * 100).toStringAsFixed(0)}% (${topicQuestions.length} questions attempted).',
          priority: accuracy == 0.0 ? 1 : 2,
          recommendedAction: RemedialActionType.reviewSource,
          deepLinkRequest: deepLink,
        ),
      );
    }

    return List.unmodifiable(recommendations);
  }
}
