/// Adaptive Learning Journey UI Controller (TITAN-KO-041.0 P41).
///
/// Production UI integration controller presenting state, handling user interactions,
/// exposing progress metrics, and managing journey resumption for Flutter widgets.
library;

import 'package:garuda_pyq/garuda_pyq.dart';

import '../domain/entities/diagnostic_placement_result.dart';
import '../domain/entities/learning_journey_error.dart';
import '../domain/entities/learning_journey_session.dart';
import '../domain/entities/learning_journey_status.dart';
import '../domain/entities/practice_execution_state.dart';
import '../service/adaptive_learning_journey_orchestrator.dart';

/// Production presentation controller managing adaptive learning journey interactions for UI.
class AdaptiveLearningJourneyController {
  final AdaptiveLearningJourneyOrchestrator _orchestrator;
  final List<void Function()> _listeners = [];

  LearningJourneySession? _session;
  PracticeQuestionResult? _lastAnswerResult;
  String? _errorMessage;
  LearningJourneyErrorCode? _lastErrorCode;
  bool _isLoading = false;

  AdaptiveLearningJourneyController({
    required AdaptiveLearningJourneyOrchestrator orchestrator,
    LearningJourneySession? initialSession,
  })  : _orchestrator = orchestrator,
        _session = initialSession;

  /// Registers a closure to be called when the controller state changes.
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Removes a previously registered closure.
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  /// Notifies all registered listeners of state changes.
  void notifyListeners() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  /// Releases resources and unregisters all listeners.
  void dispose() {
    _listeners.clear();
  }

  /// Current active journey session snapshot.
  LearningJourneySession? get session => _session;

  /// Current lifecycle execution status.
  LearningJourneyStatus get status =>
      _session?.status ?? LearningJourneyStatus.created;

  /// Currently presented question.
  NormalizedQuestion? get currentQuestion => _session?.currentQuestion;

  /// 0-based index of the currently presented question.
  int get currentQuestionIndex => _session?.currentQuestionIndex ?? 0;

  /// Total questions planned in this session.
  int get totalQuestions => _session?.totalQuestions ?? 0;

  /// Number of completed questions.
  int get completedCount => _session?.answeredCount ?? 0;

  /// Fractional progress completed [0.0, 1.0].
  double get progressPercentage => _session?.progressPercentage ?? 0.0;

  /// Direct result of the last answer submitted.
  PracticeQuestionResult? get lastAnswerResult => _lastAnswerResult;

  /// Last diagnostic error message, if an operation failed.
  String? get errorMessage => _errorMessage;

  /// Last typed error code, if an operation failed.
  LearningJourneyErrorCode? get lastErrorCode => _lastErrorCode;

  /// Whether an asynchronous operation is in flight.
  bool get isLoading => _isLoading;

  /// Whether the session is complete.
  bool get isCompleted => _session?.isCompleted ?? false;

  /// Whether an answer can currently be submitted.
  bool get canSubmitAnswer =>
      !_isLoading && (_session?.status.canAcceptAnswer ?? false);

  /// Starts a new journey session.
  Future<bool> startJourney({
    required String learnerId,
    required String examId,
    required List<NormalizedQuestion> corpus,
    String? targetObjectiveId,
    int questionCount = 5,
    DateTime? startedAt,
  }) async {
    _setLoading(true);
    _clearErrors();

    final result = await _orchestrator.startJourney(
      learnerId: learnerId,
      examId: examId,
      corpus: corpus,
      targetObjectiveId: targetObjectiveId,
      questionCount: questionCount,
      startedAt: startedAt,
    );

    _setLoading(false);

    if (result.isSuccess) {
      _session = result.session;
      _lastAnswerResult = null;
      notifyListeners();
      return true;
    } else {
      _setError(result.error?.code, result.message);
      return false;
    }
  }

  /// Submits an answer for the currently presented question.
  Future<bool> submitAnswer({
    required String answer,
    DateTime? submittedAt,
  }) async {
    final currentQ = currentQuestion;
    if (_session == null || currentQ == null) {
      _setError(LearningJourneyErrorCode.missingSession,
          'No active question available to submit answer');
      return false;
    }

    _setLoading(true);
    _clearErrors();

    final result = await _orchestrator.submitAnswer(
      session: _session!,
      questionId: currentQ.id,
      answer: answer,
      submittedAt: submittedAt,
    );

    _setLoading(false);

    if (result.isSuccess) {
      _session = result.session;
      _lastAnswerResult = result.lastAnswerResult;
      notifyListeners();
      return true;
    } else {
      _setError(result.error?.code, result.message);
      return false;
    }
  }

  /// Pauses or interrupts the active journey session.
  bool interruptJourney({
    String reason = 'user_paused',
    DateTime? interruptedAt,
  }) {
    if (_session == null) return false;

    final result = _orchestrator.interruptJourney(
      session: _session!,
      reason: reason,
      interruptedAt: interruptedAt,
    );

    if (result.isSuccess) {
      _session = result.session;
      notifyListeners();
      return true;
    } else {
      _setError(result.error?.code, result.message);
      return false;
    }
  }

  /// Recovers and resumes an interrupted journey session.
  Future<bool> resumeJourney({
    required String learnerId,
    required String examId,
    required String sessionId,
    required List<NormalizedQuestion> corpus,
    DateTime? resumedAt,
  }) async {
    _setLoading(true);
    _clearErrors();

    final result = await _orchestrator.recoverAndResumeJourney(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
      corpus: corpus,
      resumedAt: resumedAt,
    );

    _setLoading(false);

    if (result.isSuccess) {
      _session = result.session;
      _lastAnswerResult = null;
      notifyListeners();
      return true;
    } else {
      _setError(result.error?.code, result.message);
      return false;
    }
  }

  /// Whether diagnostic assessment capability is available.
  bool get hasDiagnosticService => _orchestrator.hasDiagnosticService;

  /// Executes diagnostic placement evaluation if diagnostic service is available.
  DiagnosticPlacementResult? executeDiagnosticPlacement({
    required String learnerId,
    required List<String> targetObjectiveIds,
    DateTime? requestedAt,
  }) {
    return _orchestrator.executeDiagnosticPlacement(
      learnerId: learnerId,
      targetObjectiveIds: targetObjectiveIds,
      requestedAt: requestedAt,
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(LearningJourneyErrorCode? code, String message) {
    _lastErrorCode = code;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearErrors() {
    _errorMessage = null;
    _lastErrorCode = null;
  }
}
