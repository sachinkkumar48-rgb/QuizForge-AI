/// Learner Dashboard & Control Center Domain State Entities (TITAN-KO-041.0 P41).
///
/// Encapsulates the immutable, strongly typed state model driving the learner-facing
/// dashboard: active/recoverable session continuation, authoritative progress metrics,
/// deterministic pedagogical next best actions, and persisted progress history.
library;

import 'package:meta/meta.dart';

/// Execution and presentation status for the learner dashboard.
enum LearnerDashboardStatus {
  /// Dashboard data is currently being fetched or recovered.
  loading,

  /// Dashboard state is fully loaded, validated, and ready for presentation.
  ready,

  /// First-time learner or empty curriculum context with no activity.
  empty,

  /// An error occurred during state recovery, persistence, or data loading.
  error;

  bool get isLoading => this == LearnerDashboardStatus.loading;
  bool get isReady => this == LearnerDashboardStatus.ready;
  bool get isEmpty => this == LearnerDashboardStatus.empty;
  bool get isError => this == LearnerDashboardStatus.error;
}

/// Categorical type of recommended next learning action.
enum AdaptiveActionType {
  /// Resume an uncompleted in-flight session.
  continueSession,

  /// Target a detected weak spot with a remedial lesson or micro-drill.
  startRemedialLesson,

  /// Spaced repetition review for previously achieved objectives.
  reviewWeakTopic,

  /// Continue regular practice on the active learning frontier.
  continuePractice,

  /// Diagnostic placement assessment for cold-start or unassessed objectives.
  takeDiagnostic,

  /// Targeted practice on previous year questions (PYQs).
  practicePyqs,

  /// No immediate action is required or curriculum is fully achieved.
  none;
}

/// Immutable state for the "Continue Learning" section of the dashboard.
@immutable
class ContinueLearningCardState {
  /// Whether an uncompleted, recoverable session exists for the learner.
  final bool hasRecoverableSession;

  /// Identifier of the recoverable session, if any.
  final String? sessionId;

  /// Examination identifier context (e.g. 'upsc', 'upsc_prelims_gs1').
  final String? examId;

  /// Primary syllabus topic name (e.g. 'Fundamental Rights').
  final String? topic;

  /// Target learning objective identifier.
  final String? activeObjectiveId;

  /// Current 0-based question cursor index.
  final int questionIndex;

  /// Total questions planned in this session, if known.
  final int? totalQuestions;

  /// Fractional progress completed [0.0, 1.0].
  final double progressPercentage;

  /// Timestamp of the most recent recorded activity in this session.
  final DateTime? lastActivityAt;

  /// Whether the session can be resumed.
  final bool canContinue;

  /// Whether a new learning session can be initiated.
  final bool canStartLearning;

  const ContinueLearningCardState({
    this.hasRecoverableSession = false,
    this.sessionId,
    this.examId,
    this.topic,
    this.activeObjectiveId,
    this.questionIndex = 0,
    this.totalQuestions,
    this.progressPercentage = 0.0,
    this.lastActivityAt,
    this.canContinue = false,
    this.canStartLearning = true,
  });

  /// Factory creating an empty continuation state when no recoverable session exists.
  factory ContinueLearningCardState.empty() => const ContinueLearningCardState(
        hasRecoverableSession: false,
        canContinue: false,
        canStartLearning: true,
      );

  /// Factory creating a recoverable session state.
  factory ContinueLearningCardState.recoverable({
    required String sessionId,
    required String examId,
    required String topic,
    String? activeObjectiveId,
    required int questionIndex,
    int? totalQuestions,
    double progressPercentage = 0.0,
    DateTime? lastActivityAt,
  }) =>
      ContinueLearningCardState(
        hasRecoverableSession: true,
        sessionId: sessionId,
        examId: examId,
        topic: topic,
        activeObjectiveId: activeObjectiveId,
        questionIndex: questionIndex,
        totalQuestions: totalQuestions,
        progressPercentage: progressPercentage.clamp(0.0, 1.0),
        lastActivityAt: lastActivityAt,
        canContinue: true,
        canStartLearning: false,
      );
}

/// Immutable state for the "Current Learning Progress" section.
///
/// Discloses only authoritative, evidence-backed values from the existing state model.
/// Unassessed or unavailable metrics are explicitly represented as `null` instead of inventing numbers.
@immutable
class LearnerProgressSummaryState {
  /// Total questions attempted across the current exam context.
  final int totalQuestionsAttempted;

  /// Total questions answered correctly.
  final int totalCorrectAnswers;

  /// Total questions answered incorrectly.
  final int totalIncorrectAnswers;

  /// Authoritative average accuracy percentage [0.0, 100.0], or `null` if unassessed.
  final double? averageAccuracy;

  /// Overall syllabus mastery percentage [0.0, 100.0], or `null` if unassessed.
  final double? overallMasteryPercentage;

  /// Identifier of the currently active learning objective.
  final String? activeObjectiveId;

  /// Human-readable title of the active objective/topic.
  final String? activeObjectiveTitle;

  /// Descriptive learner proficiency status ("New Aspirant", "Active Practice", "Proficient", "Needs Remediation").
  final String learningStatus;

  /// Timestamp of the latest learning attempt or checkpoint.
  final DateTime? lastLearningActivityAt;

  /// Number of learning objectives currently flagged for remedial reinforcement.
  final int remedialCount;

  /// Whether the learner has completed at least one attempt or diagnostic assessment.
  final bool isAssessed;

  const LearnerProgressSummaryState({
    required this.totalQuestionsAttempted,
    required this.totalCorrectAnswers,
    required this.totalIncorrectAnswers,
    this.averageAccuracy,
    this.overallMasteryPercentage,
    this.activeObjectiveId,
    this.activeObjectiveTitle,
    required this.learningStatus,
    this.lastLearningActivityAt,
    this.remedialCount = 0,
    required this.isAssessed,
  });

  /// Factory creating an initial unassessed progress summary for a new learner.
  factory LearnerProgressSummaryState.initial() =>
      const LearnerProgressSummaryState(
        totalQuestionsAttempted: 0,
        totalCorrectAnswers: 0,
        totalIncorrectAnswers: 0,
        averageAccuracy: null,
        overallMasteryPercentage: null,
        activeObjectiveId: null,
        activeObjectiveTitle: null,
        learningStatus: 'New Aspirant',
        lastLearningActivityAt: null,
        remedialCount: 0,
        isAssessed: false,
      );
}

/// Immutable state representing the "Next Best Learning Action".
///
/// Driven directly by pedagogical evaluation (e.g. AdaptiveLearningDecisionEngine,
/// DiagnosticAssessmentService, or RemedialLessonService) without UI logic.
@immutable
class NextBestActionState {
  /// Typed category of the action.
  final AdaptiveActionType actionType;

  /// Clear, user-facing action title (e.g. "Continue Session", "Remedial Reinforcement").
  final String title;

  /// Contextual pedagogical rationale explaining why this action is recommended.
  final String description;

  /// Target identifier (session ID, objective ID, or lesson ID).
  final String? targetId;

  /// Syllabus topic name associated with the action.
  final String? targetTopic;

  /// Target learning objective ID.
  final String? targetObjectiveId;

  /// Associated remedial lesson identifier, if applicable.
  final String? remedialLessonId;

  /// Whether this recommendation is actionable.
  final bool isAvailable;

  const NextBestActionState({
    required this.actionType,
    required this.title,
    required this.description,
    this.targetId,
    this.targetTopic,
    this.targetObjectiveId,
    this.remedialLessonId,
    this.isAvailable = true,
  });

  /// Factory creating an unavailable recommendation state.
  factory NextBestActionState.none({
    String reason = 'Curriculum objectives are currently up to date.',
  }) =>
      NextBestActionState(
        actionType: AdaptiveActionType.none,
        title: 'All Caught Up',
        description: reason,
        isAvailable: false,
      );
}

/// Immutable summary of a historical learning session or checkpoint.
@immutable
class LearnerHistoryItem {
  /// Session identifier.
  final String sessionId;

  /// Examination identifier context.
  final String examId;

  /// Topic or objective title.
  final String topic;

  /// Canonical objective identifier, if available.
  final String? objectiveId;

  /// UTC timestamp of the session activity.
  final DateTime timestamp;

  /// Question cursor index reached.
  final int questionIndex;

  /// Total questions in the session.
  final int totalQuestions;

  /// List of completed question IDs.
  final List<String> completedQuestionIds;

  /// Whether the session reached full completion.
  final bool isCompleted;

  /// Whether this session can currently be resumed.
  final bool canResume;

  LearnerHistoryItem({
    required String sessionId,
    required String examId,
    required this.topic,
    this.objectiveId,
    required DateTime timestamp,
    required this.questionIndex,
    required this.totalQuestions,
    required List<String> completedQuestionIds,
    this.isCompleted = false,
    this.canResume = false,
  })  : sessionId = sessionId.trim(),
        examId = examId.trim().toLowerCase(),
        timestamp = timestamp.toUtc(),
        completedQuestionIds = List<String>.unmodifiable(completedQuestionIds);
}

/// Complete, immutable snapshot of the Learner Dashboard and Control Center state.
@immutable
class LearnerDashboardState {
  /// Lifecycle and presentation status.
  final LearnerDashboardStatus status;

  /// Normalized learner identifier.
  final String learnerId;

  /// Normalized examination identifier.
  final String examId;

  /// State for Continue Learning banner/action.
  final ContinueLearningCardState continueLearning;

  /// State for Current Learning Progress metrics.
  final LearnerProgressSummaryState progressSummary;

  /// State for Next Best Learning Action recommendation.
  final NextBestActionState nextAction;

  /// Ordered list of historical learning sessions/checkpoints.
  final List<LearnerHistoryItem> history;

  /// Diagnostic error message, if status is error.
  final String? errorMessage;

  LearnerDashboardState({
    required this.status,
    required String learnerId,
    required String examId,
    required this.continueLearning,
    required this.progressSummary,
    required this.nextAction,
    List<LearnerHistoryItem> history = const [],
    this.errorMessage,
  })  : learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        history = List<LearnerHistoryItem>.unmodifiable(history);

  /// Factory creating an initial loading state.
  factory LearnerDashboardState.loading({
    String learnerId = '',
    String examId = '',
  }) =>
      LearnerDashboardState(
        status: LearnerDashboardStatus.loading,
        learnerId: learnerId,
        examId: examId,
        continueLearning: ContinueLearningCardState.empty(),
        progressSummary: LearnerProgressSummaryState.initial(),
        nextAction: NextBestActionState.none(),
      );

  /// Factory creating an initial empty/first-time learner state.
  factory LearnerDashboardState.empty({
    required String learnerId,
    required String examId,
    NextBestActionState? nextAction,
  }) =>
      LearnerDashboardState(
        status: LearnerDashboardStatus.empty,
        learnerId: learnerId,
        examId: examId,
        continueLearning: ContinueLearningCardState.empty(),
        progressSummary: LearnerProgressSummaryState.initial(),
        nextAction: nextAction ??
            const NextBestActionState(
              actionType: AdaptiveActionType.takeDiagnostic,
              title: 'Take Diagnostic Assessment',
              description:
                  'Establish your initial knowledge baseline across UPSC Civil Services syllabus.',
            ),
      );

  /// Factory creating a ready state with verified data.
  factory LearnerDashboardState.ready({
    required String learnerId,
    required String examId,
    required ContinueLearningCardState continueLearning,
    required LearnerProgressSummaryState progressSummary,
    required NextBestActionState nextAction,
    List<LearnerHistoryItem> history = const [],
  }) =>
      LearnerDashboardState(
        status: LearnerDashboardStatus.ready,
        learnerId: learnerId,
        examId: examId,
        continueLearning: continueLearning,
        progressSummary: progressSummary,
        nextAction: nextAction,
        history: history,
      );

  /// Factory creating an error state with message.
  factory LearnerDashboardState.error({
    required String learnerId,
    required String examId,
    required String message,
  }) =>
      LearnerDashboardState(
        status: LearnerDashboardStatus.error,
        learnerId: learnerId,
        examId: examId,
        continueLearning: ContinueLearningCardState.empty(),
        progressSummary: LearnerProgressSummaryState.initial(),
        nextAction: NextBestActionState.none(),
        errorMessage: message,
      );
}
