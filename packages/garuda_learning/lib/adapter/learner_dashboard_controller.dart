/// Learner Dashboard UI Controller (TITAN-KO-041.0 P41).
///
/// Production presentation controller orchestrating the Learner Control Center:
/// queries authoritative state, recovers session checkpoints, computes real progress,
/// evaluates pedagogical next best actions, and exposes learning history.
library;

import '../domain/entities/adaptive_decision_policy.dart';
import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/authoritative_recovery_result.dart';
import '../domain/entities/learner_dashboard_state.dart';
import '../domain/entities/session_checkpoint.dart';
import '../repository/authoritative_learning_state_repository.dart';
import '../repository/session_checkpoint_repository.dart';
import '../service/adaptive_learning_decision_engine.dart';
import '../service/authoritative_learning_state_recovery_service.dart';
import '../service/curriculum_service.dart';
import '../service/deterministic_remedial_lesson_service.dart';
import '../service/diagnostic_assessment_service.dart';
import '../service/learning_session_recovery_service.dart';

/// Presentation controller coordinating the learner control center.
class LearnerDashboardController {
  final AuthoritativeLearningStateRepository _authRepository;
  final AuthoritativeLearningStateRecoveryService _authRecoveryService;
  final SessionCheckpointRepository _checkpointRepository;
  final LearningSessionRecoveryService _sessionRecoveryService;
  final AdaptiveLearningDecisionEngine _decisionEngine;
  final CurriculumService? _curriculumService;
  final DeterministicRemedialLessonService? _remedialService;
  final DiagnosticAssessmentService? _diagnosticService;

  final List<void Function()> _listeners = [];
  LearnerDashboardState _state = LearnerDashboardState.loading();
  bool _isDisposed = false;

  LearnerDashboardController({
    required AuthoritativeLearningStateRepository authRepository,
    required AuthoritativeLearningStateRecoveryService authRecoveryService,
    required SessionCheckpointRepository checkpointRepository,
    required LearningSessionRecoveryService sessionRecoveryService,
    AdaptiveLearningDecisionEngine? decisionEngine,
    CurriculumService? curriculumService,
    DeterministicRemedialLessonService? remedialService,
    DiagnosticAssessmentService? diagnosticService,
    LearnerDashboardState? initialState,
  })  : _authRepository = authRepository,
        _authRecoveryService = authRecoveryService,
        _checkpointRepository = checkpointRepository,
        _sessionRecoveryService = sessionRecoveryService,
        _decisionEngine = decisionEngine ?? AdaptiveLearningDecisionEngine(),
        _curriculumService = curriculumService,
        _remedialService = remedialService,
        _diagnosticService = diagnosticService,
        _state = initialState ?? LearnerDashboardState.loading();

  /// Current immutable dashboard state snapshot.
  LearnerDashboardState get state => _state;

  /// Whether diagnostic assessment capability is available.
  bool get hasDiagnosticService => _diagnosticService != null;

  /// Whether remedial lesson service is available.
  bool get hasRemedialService => _remedialService != null;

  /// Underlying session recovery service.
  LearningSessionRecoveryService get sessionRecoveryService =>
      _sessionRecoveryService;

  /// Registers a listener callback invoked when state transitions occur.
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Unregisters a previously registered listener callback.
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  /// Notifies all registered listeners of state changes.
  void notifyListeners() {
    if (_isDisposed) return;
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  /// Releases resources and cleans up listener subscriptions.
  void dispose() {
    _isDisposed = true;
    _listeners.clear();
  }

  /// Loads and synthesizes the complete learner dashboard state from authoritative sources.
  Future<void> loadDashboard({
    required String learnerId,
    required String examId,
    DateTime? asOfDate,
  }) async {
    final effectiveTs = (asOfDate ?? DateTime.now()).toUtc();
    final cleanLearner = learnerId.trim();
    final cleanExam = examId.trim().toLowerCase();

    if (cleanLearner.isEmpty || cleanExam.isEmpty) {
      _state = LearnerDashboardState.error(
        learnerId: cleanLearner,
        examId: cleanExam,
        message: 'learnerId and examId cannot be empty',
      );
      notifyListeners();
      return;
    }

    _state = LearnerDashboardState.loading(
      learnerId: cleanLearner,
      examId: cleanExam,
    );
    notifyListeners();

    try {
      // 1. Query Checkpoints for Continue Learning and History
      final allCheckpoints = await _checkpointRepository.listCheckpoints(
        learnerId: cleanLearner,
        examId: cleanExam,
      );

      // Sort checkpoints by timestamp descending
      final sortedCheckpoints = List<SessionCheckpoint>.from(allCheckpoints)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Separate uncompleted and completed checkpoints
      final uncompletedCheckpoints =
          sortedCheckpoints.where((cp) => !cp.isCompleted).toList();
      final SessionCheckpoint? latestActiveCheckpoint =
          uncompletedCheckpoints.isNotEmpty ? uncompletedCheckpoints.first : null;

      // 2. Build Continue Learning Card State
      ContinueLearningCardState continueLearningState;
      if (latestActiveCheckpoint != null) {
        final topicName = _resolveTopicName(
          activeObjectiveId: latestActiveCheckpoint.activeObjectiveId,
          metadata: latestActiveCheckpoint.metadata,
        );

        final totalQ = latestActiveCheckpoint.metadata['totalQuestions'] as int? ??
            (latestActiveCheckpoint.completedQuestionIds.length + 3);

        final double progressPct = totalQ > 0
            ? (latestActiveCheckpoint.completedQuestionIds.length / totalQ)
            : 0.0;

        continueLearningState = ContinueLearningCardState.recoverable(
          sessionId: latestActiveCheckpoint.sessionId,
          examId: latestActiveCheckpoint.examId,
          topic: topicName,
          activeObjectiveId: latestActiveCheckpoint.activeObjectiveId,
          questionIndex: latestActiveCheckpoint.questionIndex,
          totalQuestions: totalQ,
          progressPercentage: progressPct,
          lastActivityAt: latestActiveCheckpoint.timestamp,
        );
      } else {
        continueLearningState = ContinueLearningCardState.empty();
      }

      // 3. Recover Authoritative Learner State
      final recoveryResult = await _authRecoveryService.recover(
        learnerId: cleanLearner,
        examId: cleanExam,
        requestedAt: effectiveTs,
      );

      if (!recoveryResult.decision.isSuccess &&
          recoveryResult.decision == AuthoritativeRecoveryDecision.corrupted) {
        _state = LearnerDashboardState.error(
          learnerId: cleanLearner,
          examId: cleanExam,
          message:
              'Authoritative learner state integrity check failed: ${recoveryResult.error?.message ?? "Corrupted state"}',
        );
        notifyListeners();
        return;
      }

      final persisted = await _authRepository.load(
        learnerId: cleanLearner,
        examId: cleanExam,
      );

      final authState = recoveryResult.state ??
          persisted?.toAuthoritativeState() ??
          AuthoritativeLearnerState.empty(
            learnerId: cleanLearner,
            examId: cleanExam,
            createdAt: effectiveTs,
          );

      // 4. Compute Real Authoritative Progress Metrics
      int totalAttempts = 0;
      int totalCorrect = 0;
      int achievedCount = 0;
      DateTime? latestAttemptTime;
      String? activeObjId;
      String? activeObjTitle;

      for (final progress in authState.progressMap.values) {
        totalAttempts += progress.attemptCount.toInt();
        totalCorrect += progress.correctCount.toInt();
        if (progress.isAchieved) {
          achievedCount++;
        }
        if (progress.lastAttemptAt != null) {
          if (latestAttemptTime == null ||
              progress.lastAttemptAt!.isAfter(latestAttemptTime)) {
            latestAttemptTime = progress.lastAttemptAt;
            activeObjId = progress.objectiveId;
          }
        }
      }

      if (activeObjId != null) {
        activeObjTitle = _curriculumService?.getObjectiveById(activeObjId)?.title;
      }

      final bool isAssessed = totalAttempts > 0 || achievedCount > 0;
      final int totalIncorrect = totalAttempts - totalCorrect;
      final double? avgAccuracy = totalAttempts > 0
          ? ((totalCorrect / totalAttempts) * 100.0)
          : null;

      final totalCurriculumObjectives =
          _curriculumService?.framework.allObjectives.length ??
              (authState.progressMap.isNotEmpty ? authState.progressMap.length : 0);

      final double? overallMastery = (isAssessed && totalCurriculumObjectives > 0)
          ? ((achievedCount / totalCurriculumObjectives) * 100.0)
          : null;

      // Count weak objectives requiring remediation
      int remedialCount = 0;
      for (final progress in authState.progressMap.values) {
        if (progress.attemptCount >= 3 && progress.successRate < 0.6) {
          remedialCount++;
        }
      }
      final String learningStatus;
      if (!isAssessed) {
        learningStatus = 'New Aspirant';
      } else if (remedialCount > 0) {
        learningStatus = 'Needs Remediation';
      } else if (avgAccuracy != null && avgAccuracy >= 80.0) {
        learningStatus = 'Proficient';
      } else {
        learningStatus = 'Active Practice';
      }

      final progressSummary = LearnerProgressSummaryState(
        totalQuestionsAttempted: totalAttempts,
        totalCorrectAnswers: totalCorrect,
        totalIncorrectAnswers: totalIncorrect,
        averageAccuracy: avgAccuracy,
        overallMasteryPercentage: overallMastery,
        activeObjectiveId: activeObjId,
        activeObjectiveTitle: activeObjTitle,
        learningStatus: learningStatus,
        lastLearningActivityAt: latestAttemptTime ??
            (latestActiveCheckpoint?.timestamp),
        remedialCount: remedialCount,
        isAssessed: isAssessed,
      );

      // 5. Evaluate Next Best Learning Action
      NextBestActionState nextActionState;
      if (latestActiveCheckpoint != null) {
        final topic = _resolveTopicName(
          activeObjectiveId: latestActiveCheckpoint.activeObjectiveId,
          metadata: latestActiveCheckpoint.metadata,
        );
        nextActionState = NextBestActionState(
          actionType: AdaptiveActionType.continueSession,
          title: 'Resume Unfinished Session',
          description:
              'Continue your in-flight practice session on $topic from question cursor ${latestActiveCheckpoint.questionIndex + 1}.',
          targetId: latestActiveCheckpoint.sessionId,
          targetTopic: topic,
          targetObjectiveId: latestActiveCheckpoint.activeObjectiveId,
        );
      } else {
        nextActionState = await _formulateNextBestAction(
          authState: authState,
          effectiveTs: effectiveTs,
          isAssessed: isAssessed,
        );
      }

      // 6. Build Progress History List
      final historyItems = sortedCheckpoints.map((cp) {
        final topic = _resolveTopicName(
          activeObjectiveId: cp.activeObjectiveId,
          metadata: cp.metadata,
        );
        final totalQ = cp.metadata['totalQuestions'] as int? ??
            (cp.completedQuestionIds.length + (cp.isCompleted ? 0 : 3));

        return LearnerHistoryItem(
          sessionId: cp.sessionId,
          examId: cp.examId,
          topic: topic,
          objectiveId: cp.activeObjectiveId,
          timestamp: cp.timestamp,
          questionIndex: cp.questionIndex,
          totalQuestions: totalQ,
          completedQuestionIds: cp.completedQuestionIds,
          isCompleted: cp.isCompleted,
          canResume: !cp.isCompleted,
        );
      }).toList();

      // 7. Determine Final Dashboard Status
      final bool isEmptyState = !isAssessed &&
          latestActiveCheckpoint == null &&
          historyItems.isEmpty;

      _state = LearnerDashboardState(
        status: isEmptyState
            ? LearnerDashboardStatus.empty
            : LearnerDashboardStatus.ready,
        learnerId: cleanLearner,
        examId: cleanExam,
        continueLearning: continueLearningState,
        progressSummary: progressSummary,
        nextAction: nextActionState,
        history: historyItems,
      );
      notifyListeners();
    } catch (e) {
      _state = LearnerDashboardState.error(
        learnerId: cleanLearner,
        examId: cleanExam,
        message: 'Failed to load learner dashboard: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  Future<NextBestActionState> _formulateNextBestAction({
    required AuthoritativeLearnerState authState,
    required DateTime effectiveTs,
    required bool isAssessed,
  }) async {
    // If learner is brand new, recommend diagnostic placement assessment
    if (!isAssessed) {
      return const NextBestActionState(
        actionType: AdaptiveActionType.takeDiagnostic,
        title: 'Take Diagnostic Assessment',
        description:
            'Evaluate baseline knowledge on Indian Polity & Constitution to map your learning frontier.',
        targetTopic: 'Indian Polity & Constitution',
        isAvailable: true,
      );
    }

    try {
      final framework = _curriculumService?.framework;
      final decision = _decisionEngine.evaluate(
        authoritativeState: authState,
        framework: framework,
        asOfDate: effectiveTs,
      );

      switch (decision.type) {
        case LearningDecisionType.continuation:
          return NextBestActionState(
            actionType: AdaptiveActionType.continueSession,
            title: 'Resume Learning Session',
            description: decision.reason,
            targetId: decision.target.targetId,
            targetTopic: decision.target.topic,
            targetObjectiveId: decision.target.objectiveId,
          );

        case LearningDecisionType.remediation:
          String topic = decision.target.topic ??
              _curriculumService
                  ?.getObjectiveById(decision.target.objectiveId ?? '')
                  ?.title ??
              'Weak Topic';
          String? lessonId = decision.target.remedialLessonId;
          final remedial = _remedialService;
          if (remedial != null && decision.target.objectiveId != null) {
            final lesson = await remedial.findBestLessonForObjective(
              objectiveId: decision.target.objectiveId!,
            );
            if (lesson != null) {
              topic = lesson.title;
              lessonId = lesson.lessonId;
            }
          }
          return NextBestActionState(
            actionType: AdaptiveActionType.startRemedialLesson,
            title: 'Targeted Remedial Lesson: $topic',
            description: decision.reason,
            targetId: decision.target.targetId,
            targetTopic: topic,
            targetObjectiveId: decision.target.objectiveId,
            remedialLessonId: lessonId,
          );

        case LearningDecisionType.review:
          final topic = decision.target.topic ??
              _curriculumService
                  ?.getObjectiveById(decision.target.objectiveId ?? '')
                  ?.title ??
              'Spaced Review';
          return NextBestActionState(
            actionType: AdaptiveActionType.reviewWeakTopic,
            title: 'Spaced Repetition Review: $topic',
            description: decision.reason,
            targetId: decision.target.targetId,
            targetTopic: topic,
            targetObjectiveId: decision.target.objectiveId,
          );

        case LearningDecisionType.reinforcement:
        case LearningDecisionType.advancement:
          final topic = decision.target.topic ??
              _curriculumService
                  ?.getObjectiveById(decision.target.objectiveId ?? '')
                  ?.title ??
              'Active Frontier';
          return NextBestActionState(
            actionType: AdaptiveActionType.continuePractice,
            title: 'Practice: $topic',
            description: decision.reason,
            targetId: decision.target.targetId,
            targetTopic: topic,
            targetObjectiveId: decision.target.objectiveId,
          );

        case LearningDecisionType.complete:
          return NextBestActionState.none(
            reason:
                'Congratulations! All curriculum objectives for this examination have reached mastery.',
          );
      }
    } catch (_) {
      // Graceful fallback if decision engine has no active frontier
      return const NextBestActionState(
        actionType: AdaptiveActionType.practicePyqs,
        title: 'Practice PYQ Drill',
        description: 'Reinforce concepts with official previous year questions.',
        targetTopic: 'Fundamental Rights',
        isAvailable: true,
      );
    }
  }

  String _resolveTopicName({
    required String activeObjectiveId,
    required Map<String, dynamic> metadata,
  }) {
    if (metadata.containsKey('topic') &&
        metadata['topic'] is String &&
        (metadata['topic'] as String).isNotEmpty) {
      return metadata['topic'] as String;
    }

    final obj = _curriculumService?.getObjectiveById(activeObjectiveId);
    if (obj != null && obj.title.isNotEmpty) {
      return obj.title;
    }

    if (activeObjectiveId.contains('fr') ||
        activeObjectiveId.contains('fundamental_rights')) {
      return 'Fundamental Rights';
    }
    if (activeObjectiveId.contains('dpsp')) {
      return 'Directive Principles of State Policy';
    }
    if (activeObjectiveId.contains('preamble')) {
      return 'Preamble';
    }

    return activeObjectiveId.replaceAll('_', ' ').toUpperCase();
  }
}
