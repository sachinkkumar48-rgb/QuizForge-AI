import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';
import '../../coordinator/application_coordinator.dart';
import 'application_provider.dart';

/// Immutable presentation state for active interactive assessment.
class InteractiveQuizState {
  final Quiz? quiz;
  final QuizSession? session;
  final int currentIndex;
  final Map<String, InteractiveQuestionState> questionStates;
  final bool isLoading;
  final bool isCompleted;
  final String? errorMessage;
  final AssessmentPerformance? performance;
  final List<RemedialStudyRecommendation> recommendations;

  InteractiveQuizState({
    this.quiz,
    this.session,
    this.currentIndex = 0,
    Map<String, InteractiveQuestionState>? questionStates,
    this.isLoading = false,
    this.isCompleted = false,
    this.errorMessage,
    this.performance,
    List<RemedialStudyRecommendation>? recommendations,
  })  : questionStates = Map.unmodifiable(
            questionStates ?? const <String, InteractiveQuestionState>{}),
        recommendations = List.unmodifiable(
            recommendations ?? const <RemedialStudyRecommendation>[]);

  const InteractiveQuizState.initial()
      : quiz = null,
        session = null,
        currentIndex = 0,
        questionStates = const {},
        isLoading = false,
        isCompleted = false,
        errorMessage = null,
        performance = null,
        recommendations = const [];

  QuizQuestion? get currentQuestion {
    if (quiz == null || quiz!.questions.isEmpty) return null;
    if (currentIndex < 0 || currentIndex >= quiz!.questions.length) return null;
    return quiz!.questions[currentIndex];
  }

  InteractiveQuestionState? get currentQuestionState {
    final q = currentQuestion;
    if (q == null) return null;
    return questionStates[q.id];
  }

  int get totalQuestions => quiz?.questions.length ?? 0;

  double get progress =>
      totalQuestions > 0 ? (currentIndex + 1) / totalQuestions : 0.0;

  InteractiveQuizState copyWith({
    Quiz? quiz,
    QuizSession? session,
    int? currentIndex,
    Map<String, InteractiveQuestionState>? questionStates,
    bool? isLoading,
    bool? isCompleted,
    String? errorMessage,
    AssessmentPerformance? performance,
    List<RemedialStudyRecommendation>? recommendations,
  }) {
    return InteractiveQuizState(
      quiz: quiz ?? this.quiz,
      session: session ?? this.session,
      currentIndex: currentIndex ?? this.currentIndex,
      questionStates: questionStates ?? this.questionStates,
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      errorMessage: errorMessage,
      performance: performance ?? this.performance,
      recommendations: recommendations ?? this.recommendations,
    );
  }
}

/// Controller managing rich interactive quiz answering, immediate feedback, and remedial study loop.
class InteractiveQuizController extends StateNotifier<InteractiveQuizState> {
  final ApplicationCoordinator _coordinator;
  final AssessmentPerformanceAnalyzer _analyzer;
  final QuizSessionService _sessionService;

  InteractiveQuizController({
    required ApplicationCoordinator coordinator,
    AssessmentPerformanceAnalyzer analyzer =
        const AssessmentPerformanceAnalyzer(),
    QuizSessionService sessionService = const QuizSessionService(),
  })  : _coordinator = coordinator,
        _analyzer = analyzer,
        _sessionService = sessionService,
        super(const InteractiveQuizState.initial());

  /// Initializes the controller with the active quiz and session.
  void initialize({
    required Quiz quiz,
    required QuizSession session,
  }) {
    final states = <String, InteractiveQuestionState>{};

    for (final q in quiz.questions) {
      final attempt = session.answers.firstWhere(
        (a) => a.questionId == q.id,
        orElse: () => QuestionAttempt.unanswered(q.id),
      );

      final selectedIndices = <int>{};
      if (attempt.selectedOptionId != null) {
        final parsed = int.tryParse(attempt.selectedOptionId!);
        if (parsed != null && parsed >= 0 && parsed < q.options.length) {
          selectedIndices.add(parsed);
        }
      }

      var qType = AssessmentQuestionType.mcq;
      if (q.options.length == 2 &&
          (q.options[0].text.toLowerCase().contains('true') ||
              q.options[1].text.toLowerCase().contains('false'))) {
        qType = AssessmentQuestionType.trueFalse;
      }

      final status = attempt.isAnswered
          ? (selectedIndices.contains(q.correctAnswerIndex)
              ? AnswerStatus.correct
              : AnswerStatus.incorrect)
          : (selectedIndices.isNotEmpty
              ? AnswerStatus.selected
              : AnswerStatus.unanswered);

      states[q.id] = InteractiveQuestionState(
        question: q,
        selectedOptionIndices: selectedIndices,
        status: status,
        questionType: qType,
        pageNumber: q.pageReference,
      );
    }

    state = InteractiveQuizState(
      quiz: quiz,
      session: session,
      currentIndex: session.currentQuestionIndex.clamp(
        0,
        (quiz.questions.length - 1).clamp(0, double.infinity).toInt(),
      ),
      questionStates: states,
    );
  }

  /// Selects or toggles an option for the current question.
  void selectOption(int optionIndex) {
    final currentQ = state.currentQuestion;
    if (currentQ == null) return;
    final currentState = state.questionStates[currentQ.id];
    if (currentState == null || currentState.isSubmitted) return;

    final updatedMap =
        Map<String, InteractiveQuestionState>.from(state.questionStates);

    if (currentState.questionType == AssessmentQuestionType.multipleSelect) {
      updatedMap[currentQ.id] = currentState.toggleMultipleOption(optionIndex);
    } else {
      updatedMap[currentQ.id] = currentState.selectSingleOption(optionIndex);
    }

    state = state.copyWith(questionStates: updatedMap);
  }

  /// Submits the current question answer and triggers immediate evaluation.
  Future<void> submitCurrentAnswer() async {
    final currentQ = state.currentQuestion;
    final currentSession = state.session;
    if (currentQ == null || currentSession == null) return;
    final currentState = state.questionStates[currentQ.id];
    if (currentState == null ||
        !currentState.isSelected ||
        currentState.isSubmitted) {
      return;
    }

    final evaluatedState = currentState.submitAndEvaluate();
    final updatedMap =
        Map<String, InteractiveQuestionState>.from(state.questionStates);
    updatedMap[currentQ.id] = evaluatedState;

    state = state.copyWith(questionStates: updatedMap, isLoading: true);

    try {
      final selectedId = evaluatedState.primarySelectedOptionIndex != null
          ? '${evaluatedState.primarySelectedOptionIndex}'
          : null;

      final updatedSession = await _coordinator.answerQuestion(
        sessionId: currentSession.sessionId,
        questionId: currentQ.id,
        selectedOptionId: selectedId,
        sessionService: _sessionService,
      );

      state = state.copyWith(
        session: updatedSession,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Advances to next question if available.
  void nextQuestion() {
    if (state.currentIndex < state.totalQuestions - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  /// Navigates to previous question if available.
  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  /// Jumps directly to a specific question index.
  void jumpToQuestion(int index) {
    if (index >= 0 && index < state.totalQuestions) {
      state = state.copyWith(currentIndex: index);
    }
  }

  /// Toggles review flag on the current question.
  void toggleMarkForReview([String? questionId]) {
    final targetId = questionId ?? state.currentQuestion?.id;
    if (targetId == null) return;
    final currentState = state.questionStates[targetId];
    if (currentState == null) return;

    final updatedMap =
        Map<String, InteractiveQuestionState>.from(state.questionStates);
    updatedMap[targetId] = currentState.toggleReviewFlag();

    state = state.copyWith(questionStates: updatedMap);
  }

  /// Finalizes the interactive assessment, calculates performance metrics and remedial recommendations.
  Future<AssessmentPerformance?> completeAssessment() async {
    final currentQuiz = state.quiz;
    final currentSession = state.session;
    if (currentQuiz == null || currentSession == null) return null;

    state = state.copyWith(isLoading: true);

    try {
      final performance = _analyzer.analyzePerformance(
        quiz: currentQuiz,
        questionStates: state.questionStates,
      );

      final recommendations = _analyzer.generateRemedialRecommendations(
        quiz: currentQuiz,
        performance: performance,
        questionStates: state.questionStates,
      );

      await _coordinator.completeSession(sessionId: currentSession.sessionId);

      state = state.copyWith(
        isLoading: false,
        isCompleted: true,
        performance: performance,
        recommendations: recommendations,
      );

      return performance;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to complete assessment: $e',
      );
      return null;
    }
  }

  /// Deep link navigates into TITAN Reader for remedial source review.
  Future<bool> studySourceInReader(ReaderDeepLinkRequest request) async {
    return await _coordinator.navigateToReaderSource(request);
  }
}

/// Provider for interactive assessment UI controller.
final interactiveQuizControllerProvider = StateNotifierProvider.autoDispose<
    InteractiveQuizController, InteractiveQuizState>((ref) {
  final coordinator = ref.watch(applicationCoordinatorProvider);
  return InteractiveQuizController(coordinator: coordinator);
});
