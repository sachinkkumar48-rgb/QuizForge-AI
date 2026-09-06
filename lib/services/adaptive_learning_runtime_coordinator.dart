import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:titan_core/titan_core.dart';

import '../models/quiz_model.dart';
import 'active_learner_service.dart';

/// Production-grade Runtime Coordinator connecting QuizForge AI application runtime
/// (presentation, controllers, and pages) to the authoritative Project TITAN / GARUDA
/// adaptive learning services (P38/P39 state reconciliation, P40 progressive mastery).
class AdaptiveLearningRuntimeCoordinator {
  final AuthoritativeLearningStateRecoveryService _recoveryService;
  final AdaptiveLearningStateReconciliationPipeline _reconciliationPipeline;
  final ProgressiveMasteryEngine _masteryEngine;
  final AuthoritativeLearningStateRepository _repository;
  final ActiveLearnerService? _activeLearnerService;
  final String defaultExamId;

  AuthoritativeLearnerState? _cachedState;
  LearnerMasterySnapshot? _cachedMasterySnapshot;

  /// Reactive notifier alerting UI components when mastery snapshot updates.
  final ValueNotifier<LearnerMasterySnapshot?> masteryNotifier =
      ValueNotifier<LearnerMasterySnapshot?>(null);

  /// Reactive notifier alerting UI components when authoritative learner state updates.
  final ValueNotifier<AuthoritativeLearnerState?> stateNotifier =
      ValueNotifier<AuthoritativeLearnerState?>(null);

  AdaptiveLearningRuntimeCoordinator({
    AuthoritativeLearningStateRecoveryService? recoveryService,
    AdaptiveLearningStateReconciliationPipeline? reconciliationPipeline,
    ProgressiveMasteryEngine? masteryEngine,
    AuthoritativeLearningStateRepository? repository,
    ActiveLearnerService? activeLearnerService,
    this.defaultExamId = 'upsc_prelims_gs1',
  })  : _repository = repository ??
            (TitanServiceLocator.instance
                    .isRegistered<AuthoritativeLearningStateRepository>()
                ? TitanServiceLocator.instance
                    .get<AuthoritativeLearningStateRepository>()
                : InMemoryAuthoritativeLearningStateRepository()),
        _recoveryService = recoveryService ??
            (TitanServiceLocator.instance
                    .isRegistered<AuthoritativeLearningStateRecoveryService>()
                ? TitanServiceLocator.instance
                    .get<AuthoritativeLearningStateRecoveryService>()
                : AuthoritativeLearningStateRecoveryService(
                    repository: repository ??
                        (TitanServiceLocator.instance.isRegistered<
                                AuthoritativeLearningStateRepository>()
                            ? TitanServiceLocator.instance
                                .get<AuthoritativeLearningStateRepository>()
                            : InMemoryAuthoritativeLearningStateRepository()),
                  )),
        _reconciliationPipeline = reconciliationPipeline ??
            (TitanServiceLocator.instance.isRegistered<
                    AdaptiveLearningStateReconciliationPipeline>()
                ? TitanServiceLocator.instance
                    .get<AdaptiveLearningStateReconciliationPipeline>()
                : AdaptiveLearningStateReconciliationPipeline(
                    repository: repository ??
                        (TitanServiceLocator.instance.isRegistered<
                                AuthoritativeLearningStateRepository>()
                            ? TitanServiceLocator.instance
                                .get<AuthoritativeLearningStateRepository>()
                            : InMemoryAuthoritativeLearningStateRepository()),
                    recoveryService: recoveryService ??
                        AuthoritativeLearningStateRecoveryService(
                          repository: repository ??
                              (TitanServiceLocator.instance.isRegistered<
                                      AuthoritativeLearningStateRepository>()
                                  ? TitanServiceLocator.instance
                                      .get<AuthoritativeLearningStateRepository>()
                                  : InMemoryAuthoritativeLearningStateRepository()),
                        ),
                  )),
        _masteryEngine = masteryEngine ??
            (TitanServiceLocator.instance
                    .isRegistered<ProgressiveMasteryEngine>()
                ? TitanServiceLocator.instance.get<ProgressiveMasteryEngine>()
                : const ProgressiveMasteryEngine()),
        _activeLearnerService = activeLearnerService ??
            (TitanServiceLocator.instance.isRegistered<ActiveLearnerService>()
                ? TitanServiceLocator.instance.get<ActiveLearnerService>()
                : null);

  /// Resolved active learner identifier.
  String get activeLearnerId {
    try {
      final id = _activeLearnerService?.activeLearnerId;
      if (id != null && id.trim().isNotEmpty) {
        return id.trim();
      }
    } catch (_) {}
    return 'user_garuda_01';
  }

  /// Initialized or cached authoritative learner state.
  AuthoritativeLearnerState? get cachedState => _cachedState;

  /// Cached learner progressive mastery snapshot.
  LearnerMasterySnapshot? get cachedMasterySnapshot => _cachedMasterySnapshot;

  /// Initializes or recovers authoritative learner state from persistence across application restarts.
  Future<AuthoritativeRecoveryResult> initialize({
    String? learnerId,
    String? examId,
    DateTime? requestedAt,
  }) async {
    final targetLearner = (learnerId ?? activeLearnerId).trim();
    final targetExam = (examId ?? defaultExamId).trim().toLowerCase();
    final effectiveTs = (requestedAt ?? DateTime.now()).toUtc();

    final result = await _recoveryService.recover(
      learnerId: targetLearner,
      examId: targetExam,
      requestedAt: effectiveTs,
      persistInitialIfAbsent: true,
    );

    if (result.isSuccess && result.state != null) {
      _cachedState = result.state;
      _cachedMasterySnapshot = _masteryEngine.evaluateFromAuthoritativeState(
        authoritativeState: _cachedState!,
        evaluatedAt: effectiveTs,
      );
      stateNotifier.value = _cachedState;
      masteryNotifier.value = _cachedMasterySnapshot;
    }

    return result;
  }

  /// Consolidates and reconciles completed quiz questions and answers into authoritative learner state
  /// and updates progressive topic mastery profiles.
  Future<ReconciliationPipelineResult> recordQuizCompletion({
    required String sessionId,
    required String sourceName,
    required List<QuizQuestion> questions,
    required Map<int, String?> answers,
    String? learnerId,
    String? examId,
    DateTime? startedAt,
    DateTime? completedAt,
  }) async {
    final targetLearner = (learnerId ?? activeLearnerId).trim();
    final targetExam = (examId ?? defaultExamId).trim().toLowerCase();
    final effectiveCompletedAt = (completedAt ?? DateTime.now()).toUtc();
    final effectiveStartedAt = (startedAt ??
            effectiveCompletedAt.subtract(Duration(seconds: questions.length * 30)))
        .toUtc();

    final outcome = _buildConsolidatedOutcome(
      sessionId: sessionId,
      sourceName: sourceName,
      learnerId: targetLearner,
      examId: targetExam,
      questions: questions,
      answers: answers,
      startedAt: effectiveStartedAt,
      completedAt: effectiveCompletedAt,
    );

    final pipelineResult = await _reconciliationPipeline.executeFromRepository(
      learnerId: targetLearner,
      examId: targetExam,
      outcome: outcome,
      timestamp: effectiveCompletedAt,
    );

    if (pipelineResult.isSuccess && pipelineResult.resultingState != null) {
      _cachedState = pipelineResult.resultingState;
      final previous = (_cachedMasterySnapshot != null &&
              _cachedMasterySnapshot!.learnerId == targetLearner &&
              _cachedMasterySnapshot!.examId == targetExam)
          ? _cachedMasterySnapshot
          : null;
      _cachedMasterySnapshot = _masteryEngine.evaluateFromAuthoritativeState(
        authoritativeState: _cachedState!,
        evaluatedAt: effectiveCompletedAt,
        previousSnapshot: previous,
      );
      stateNotifier.value = _cachedState;
      masteryNotifier.value = _cachedMasterySnapshot;
    }

    return pipelineResult;
  }

  /// Retrieves the current [LearnerMasterySnapshot], recovering from repository if not yet loaded.
  Future<LearnerMasterySnapshot?> getCurrentMasterySnapshot({
    String? learnerId,
    String? examId,
  }) async {
    final targetLearner = (learnerId ?? activeLearnerId).trim();
    final targetExam = (examId ?? defaultExamId).trim().toLowerCase();

    if (_cachedMasterySnapshot != null &&
        _cachedMasterySnapshot!.learnerId == targetLearner &&
        _cachedMasterySnapshot!.examId == targetExam) {
      return _cachedMasterySnapshot;
    }

    await initialize(learnerId: targetLearner, examId: targetExam);
    return _cachedMasterySnapshot;
  }

  /// Retrieves the current [AuthoritativeLearnerState], recovering from repository if not yet loaded.
  Future<AuthoritativeLearnerState?> getAuthoritativeState({
    String? learnerId,
    String? examId,
  }) async {
    final targetLearner = (learnerId ?? activeLearnerId).trim();
    final targetExam = (examId ?? defaultExamId).trim().toLowerCase();

    if (_cachedState != null &&
        _cachedState!.learnerId == targetLearner &&
        _cachedState!.examId == targetExam) {
      return _cachedState;
    }

    await initialize(learnerId: targetLearner, examId: targetExam);
    return _cachedState;
  }

  /// Derives next adaptive learning recommendations (weakest topics, difficulty band, next action).
  Future<AdaptiveMasteryDecisionOutput?> getNextAdaptiveRecommendation({
    String? learnerId,
    String? examId,
  }) async {
    final snapshot = await getCurrentMasterySnapshot(
      learnerId: learnerId,
      examId: examId,
    );
    return snapshot?.decisionOutput;
  }

  /// Constructs a validated, compliant [ConsolidatedPracticeOutcome] satisfying all
  /// P36/P37 invariant requirements.
  ConsolidatedPracticeOutcome _buildConsolidatedOutcome({
    required String sessionId,
    required String sourceName,
    required String learnerId,
    required String examId,
    required List<QuizQuestion> questions,
    required Map<int, String?> answers,
    required DateTime startedAt,
    required DateTime completedAt,
  }) {
    final totalQuestions = questions.length;
    int attemptedCount = 0;
    int correctCount = 0;
    int incorrectCount = 0;
    int skippedCount = 0;

    final questionEvidenceList = <PracticeQuestionEvidence>[];
    final handoffAttempts = <QuestionAttempt>[];

    final topicAccumulator = <String, _Accumulator>{};
    final objectiveAccumulator = <String, _Accumulator>{};
    final difficultyAccumulator = <String, _Accumulator>{};

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final userAns = answers[i];
      final isAnswered = userAns != null && userAns.trim().isNotEmpty;

      bool isCorrect = false;
      if (isAnswered) {
        attemptedCount++;
        final cleanUser = userAns.trim().toLowerCase();
        final cleanTarget = q.answer.trim().toLowerCase();
        isCorrect = (cleanUser == cleanTarget || cleanUser.startsWith(cleanTarget));
        if (isCorrect) {
          correctCount++;
        } else {
          incorrectCount++;
        }
      } else {
        skippedCount++;
      }

      final qId = 'quiz_q_${i + 1}_${q.question.hashCode.abs()}';
      final topicKey = q.subject.trim().isNotEmpty ? q.subject.trim() : 'General Studies';
      final objId = topicKey;
      final diffKey = q.difficulty.trim().isNotEmpty ? q.difficulty.trim() : 'Medium';

      final qEvidence = PracticeQuestionEvidence(
        questionId: qId,
        examId: examId,
        subject: q.subject,
        topic: topicKey,
        objectiveIds: [objId],
        difficulty: diffKey,
        questionIndex: i,
        status: isAnswered
            ? (isCorrect
                ? PracticeQuestionStatus.answeredCorrect
                : PracticeQuestionStatus.answeredIncorrect)
            : PracticeQuestionStatus.skipped,
        submittedAnswer: userAns,
        correctAnswer: q.answer,
        isCorrect: isCorrect,
        isAnswered: isAnswered,
        isSkipped: !isAnswered,
        elapsedSeconds: 30,
        presentedAt: startedAt.add(Duration(seconds: i * 30)),
        answeredAt: startedAt.add(Duration(seconds: (i + 1) * 30)),
        feedbackPolicy: PracticeFeedbackPolicy.immediate,
        isExplanationExposed: true,
        evaluationMethod: EvaluationMethod.multipleChoice,
      );
      questionEvidenceList.add(qEvidence);

      if (isAnswered) {
        handoffAttempts.add(QuestionAttempt(
          attemptId: 'att_${sessionId}_$qId',
          learnerId: learnerId,
          questionId: qId,
          objectiveId: objId,
          submittedAnswer: userAns,
          attemptedAt: completedAt,
          sessionId: sessionId,
        ));
      }

      // Record in dimensional accumulators
      topicAccumulator
          .putIfAbsent(topicKey, () => _Accumulator(topicKey))
          .record(isAnswered: isAnswered, isCorrect: isCorrect, isSkipped: !isAnswered);
      objectiveAccumulator
          .putIfAbsent(objId, () => _Accumulator(objId))
          .record(isAnswered: isAnswered, isCorrect: isCorrect, isSkipped: !isAnswered);
      difficultyAccumulator
          .putIfAbsent(diffKey, () => _Accumulator(diffKey))
          .record(isAnswered: isAnswered, isCorrect: isCorrect, isSkipped: !isAnswered);
    }

    final unansweredCount = totalQuestions - attemptedCount - skippedCount;
    final completionRate = totalQuestions > 0
        ? ((attemptedCount + skippedCount) / totalQuestions).clamp(0.0, 1.0)
        : 1.0;
    final double? accuracy = attemptedCount > 0 ? (correctCount / attemptedCount) : null;
    final double? accuracyPercentage = accuracy != null ? accuracy * 100.0 : null;
    final double scoreRatio =
        totalQuestions > 0 ? (correctCount / totalQuestions).clamp(0.0, 1.0) : 0.0;
    final totalDuration =
        completedAt.difference(startedAt).inSeconds.clamp(1, 86400);
    final avgSeconds = attemptedCount > 0 ? (totalDuration / attemptedCount) : 0.0;

    final feedbackSummary = PracticeFeedbackSummary(
      policy: PracticeFeedbackPolicy.immediate,
      totalFeedbackGenerated: attemptedCount,
      explanationsExposedCount: attemptedCount,
      explanationsWithheldCount: 0,
      exposureRate: attemptedCount > 0 ? 1.0 : 0.0,
    );

    // Build dimensional evidence maps
    final topicEvidence = SplayTreeMap<String, PracticeTopicEvidence>();
    topicAccumulator.forEach((k, acc) {
      topicEvidence[k] = acc.toTopicEvidence(k);
    });

    final objectiveEvidence = SplayTreeMap<String, PracticeObjectiveEvidence>();
    objectiveAccumulator.forEach((k, acc) {
      objectiveEvidence[k] = acc.toObjectiveEvidence(k);
    });

    final sectionEvidence = SplayTreeMap<String, PracticeSectionEvidence>();
    sectionEvidence['sec_1'] = PracticeSectionEvidence(
      sectionIndex: 0,
      sectionTitle: sourceName,
      totalQuestions: totalQuestions,
      attemptedCount: attemptedCount,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      skippedCount: skippedCount,
      unansweredCount: unansweredCount,
      completionRate: completionRate,
      accuracy: accuracy,
      accuracyPercentage: accuracyPercentage,
      skipRate: totalQuestions > 0 ? (skippedCount / totalQuestions).clamp(0.0, 1.0) : 0.0,
      totalElapsedSeconds: totalDuration,
      averageSecondsPerAttempt: avgSeconds,
    );

    final difficultyEvidence = SplayTreeMap<String, PracticeDifficultyEvidence>();
    difficultyAccumulator.forEach((k, acc) {
      difficultyEvidence[k] = acc.toDifficultyEvidence(k);
    });

    final rawFingerprint =
        '$examId|$sessionId|$learnerId|$totalQuestions|$correctCount|$totalDuration';
    final fingerprint =
        sha256.convert(utf8.encode(rawFingerprint)).toString().substring(0, 16);

    return ConsolidatedPracticeOutcome(
      sessionId: sessionId,
      examId: examId,
      learnerId: learnerId,
      sessionMode: PracticeSessionMode.standard,
      sessionStatus: PracticeExecutionStatus.completed,
      startedAt: startedAt,
      completedAt: completedAt,
      totalQuestions: totalQuestions,
      attemptedCount: attemptedCount,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      skippedCount: skippedCount,
      unansweredCount: unansweredCount,
      completionRate: completionRate,
      accuracy: accuracy,
      accuracyPercentage: accuracyPercentage,
      scoreRatio: scoreRatio,
      totalDurationSeconds: totalDuration,
      averageSecondsPerQuestion: avgSeconds,
      feedbackSummary: feedbackSummary,
      topicEvidence: topicEvidence,
      objectiveEvidence: objectiveEvidence,
      sectionEvidence: sectionEvidence,
      difficultyEvidence: difficultyEvidence,
      questionEvidence: questionEvidenceList,
      handoffAttempts: handoffAttempts,
      fingerprint: fingerprint,
    );
  }
}

class _Accumulator {
  final String key;
  int total = 0;
  int attempted = 0;
  int correct = 0;
  int incorrect = 0;
  int skipped = 0;
  int elapsed = 0;

  _Accumulator(this.key);

  void record({
    required bool isAnswered,
    required bool isCorrect,
    required bool isSkipped,
    int seconds = 30,
  }) {
    total++;
    elapsed += seconds;
    if (isAnswered) {
      attempted++;
      if (isCorrect) {
        correct++;
      } else {
        incorrect++;
      }
    } else if (isSkipped) {
      skipped++;
    }
  }

  PracticeTopicEvidence toTopicEvidence(String topic) {
    final compRate = total > 0 ? ((attempted + skipped) / total).clamp(0.0, 1.0) : 0.0;
    final double? acc = attempted > 0 ? (correct / attempted).clamp(0.0, 1.0) : null;
    return PracticeTopicEvidence(
      topic: topic,
      totalQuestions: total,
      attemptedCount: attempted,
      correctCount: correct,
      incorrectCount: incorrect,
      skippedCount: skipped,
      unansweredCount: total - attempted - skipped,
      completionRate: compRate,
      accuracy: acc,
      accuracyPercentage: acc != null ? acc * 100.0 : null,
      skipRate: total > 0 ? (skipped / total).clamp(0.0, 1.0) : 0.0,
      totalElapsedSeconds: elapsed,
      averageSecondsPerAttempt: attempted > 0 ? elapsed / attempted : 0.0,
    );
  }

  PracticeObjectiveEvidence toObjectiveEvidence(String objId) {
    final compRate = total > 0 ? ((attempted + skipped) / total).clamp(0.0, 1.0) : 0.0;
    final double? acc = attempted > 0 ? (correct / attempted).clamp(0.0, 1.0) : null;
    return PracticeObjectiveEvidence(
      objectiveId: objId,
      totalQuestions: total,
      attemptedCount: attempted,
      correctCount: correct,
      incorrectCount: incorrect,
      skippedCount: skipped,
      unansweredCount: total - attempted - skipped,
      completionRate: compRate,
      accuracy: acc,
      accuracyPercentage: acc != null ? acc * 100.0 : null,
      skipRate: total > 0 ? (skipped / total).clamp(0.0, 1.0) : 0.0,
      totalElapsedSeconds: elapsed,
      averageSecondsPerAttempt: attempted > 0 ? elapsed / attempted : 0.0,
    );
  }

  PracticeDifficultyEvidence toDifficultyEvidence(String diff) {
    final compRate = total > 0 ? ((attempted + skipped) / total).clamp(0.0, 1.0) : 0.0;
    final double? acc = attempted > 0 ? (correct / attempted).clamp(0.0, 1.0) : null;
    return PracticeDifficultyEvidence(
      difficulty: diff,
      totalQuestions: total,
      attemptedCount: attempted,
      correctCount: correct,
      incorrectCount: incorrect,
      skippedCount: skipped,
      unansweredCount: total - attempted - skipped,
      completionRate: compRate,
      accuracy: acc,
      accuracyPercentage: acc != null ? acc * 100.0 : null,
      skipRate: total > 0 ? (skipped / total).clamp(0.0, 1.0) : 0.0,
      totalElapsedSeconds: elapsed,
      averageSecondsPerAttempt: attempted > 0 ? elapsed / attempted : 0.0,
    );
  }
}
