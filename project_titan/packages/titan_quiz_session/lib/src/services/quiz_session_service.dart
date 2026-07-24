import 'package:titan_quiz/titan_quiz.dart';
import '../enums/quiz_session_status.dart';
import '../exceptions/quiz_session_exception.dart';
import '../models/question_attempt.dart';
import '../models/quiz_result_summary.dart';
import '../models/quiz_session.dart';
import '../models/session_configuration.dart';
import '../utils/quiz_session_utils.dart';
import '../validators/quiz_session_validator.dart';
import 'quiz_timer_service.dart';

/// Central domain service orchestrating the business lifecycle of quiz session attempts.
class QuizSessionService {
  final QuizTimerService _timerService;
  final QuizSessionValidator _validator;
  final QuizStatisticsService _statisticsService;

  const QuizSessionService({
    QuizTimerService timerService = const QuizTimerService(),
    QuizSessionValidator validator = const QuizSessionValidator(),
    QuizStatisticsService statisticsService = const QuizStatisticsService(),
  })  : _timerService = timerService,
        _validator = validator,
        _statisticsService = statisticsService;

  /// Starts a new quiz session for the provided [quiz] with optional [configuration].
  QuizSession startSession(
    Quiz quiz, {
    SessionConfiguration configuration = const SessionConfiguration.standard(),
  }) {
    if (quiz.questions.isEmpty) {
      throw const SessionStateException(
          'Cannot start a session for a quiz with no questions.');
    }

    final now = DateTime.now();
    final sessionId = QuizSessionUtils.generateSessionId();

    final initialAnswers =
        quiz.questions.map((q) => QuestionAttempt.unanswered(q.id)).toList();

    return QuizSession(
      sessionId: sessionId,
      quizId: quiz.id,
      startedAt: now,
      lastUpdatedAt: now,
      status: QuizSessionStatus.inProgress,
      answers: initialAnswers,
      currentQuestionIndex: 0,
      elapsedTime: Duration.zero,
      remainingTime: configuration.timeLimit,
      configuration: configuration,
    );
  }

  /// Pauses an active session, freezing timer accumulation.
  QuizSession pauseSession(QuizSession session) {
    if (session.status != QuizSessionStatus.inProgress) {
      throw SessionStateException(
        'Cannot pause session because it is currently in state "${session.status.name}".',
      );
    }

    final now = DateTime.now();
    final newElapsed = _timerService.calculateElapsedTime(session, now: now);

    return session.copyWith(
      status: QuizSessionStatus.paused,
      elapsedTime: newElapsed,
      lastUpdatedAt: now,
    );
  }

  /// Resumes a paused session.
  QuizSession resumeSession(QuizSession session) {
    if (session.status != QuizSessionStatus.paused) {
      throw SessionStateException(
        'Cannot resume session because it is currently in state "${session.status.name}".',
      );
    }

    final now = DateTime.now();
    return session.copyWith(
      status: QuizSessionStatus.inProgress,
      lastUpdatedAt: now,
    );
  }

  /// Records or updates an attempt for [questionId] within [session].
  QuizSession answerQuestion(
    QuizSession session,
    Quiz quiz,
    String questionId,
    String? selectedOptionId, {
    Duration timeSpent = Duration.zero,
  }) {
    _validator.validateActiveState(session);
    _validator.validateSessionAgainstQuiz(session, quiz);

    if (_timerService.isExpired(session)) {
      throw const TimerException(
          'Cannot answer question because the session time limit has expired.');
    }

    final questionIndex = quiz.questions.indexWhere((q) => q.id == questionId);
    if (questionIndex == -1) {
      throw ProgressException(
          'Question ID [$questionId] does not exist in quiz [${quiz.id}].');
    }

    final now = DateTime.now();
    final currentAnswers = List<QuestionAttempt>.from(session.answers);
    final existingIndex =
        currentAnswers.indexWhere((a) => a.questionId == questionId);

    final isAns =
        selectedOptionId != null && selectedOptionId.trim().isNotEmpty;
    final updatedAttempt = QuestionAttempt(
      questionId: questionId,
      selectedOptionId: isAns ? selectedOptionId : null,
      isAnswered: isAns,
      answeredAt: isAns ? now : null,
      timeSpent: (existingIndex != -1
              ? currentAnswers[existingIndex].timeSpent
              : Duration.zero) +
          timeSpent,
    );

    if (existingIndex != -1) {
      currentAnswers[existingIndex] = updatedAttempt;
    } else {
      currentAnswers.add(updatedAttempt);
    }

    return session.copyWith(
      answers: currentAnswers,
      lastUpdatedAt: now,
    );
  }

  /// Skips [questionId], marking it unanswered if allowed by configuration.
  QuizSession skipQuestion(QuizSession session, Quiz quiz, String questionId) {
    _validator.validateActiveState(session);
    _validator.validateSessionAgainstQuiz(session, quiz);

    if (!session.configuration.allowSkip) {
      throw const SessionStateException(
          'Skipping questions is disabled in current session configuration.');
    }

    final updatedSession = answerQuestion(session, quiz, questionId, null);

    if (updatedSession.currentQuestionIndex < quiz.questions.length - 1) {
      return updatedSession.copyWith(
        currentQuestionIndex: updatedSession.currentQuestionIndex + 1,
      );
    }

    return updatedSession;
  }

  /// Advances to the next question in sequence.
  QuizSession moveNext(QuizSession session, Quiz quiz) {
    _validator.validateActiveState(session);
    _validator.validateSessionAgainstQuiz(session, quiz);

    final nextIndex = session.currentQuestionIndex + 1;
    _validator.validateQuestionIndex(session, nextIndex, quiz.questions.length);

    return session.copyWith(
      currentQuestionIndex: nextIndex,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// Moves to the previous question in sequence.
  QuizSession movePrevious(QuizSession session, Quiz quiz) {
    _validator.validateActiveState(session);
    _validator.validateSessionAgainstQuiz(session, quiz);

    final prevIndex = session.currentQuestionIndex - 1;
    _validator.validateQuestionIndex(session, prevIndex, quiz.questions.length);

    return session.copyWith(
      currentQuestionIndex: prevIndex,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// Completes the quiz session and evaluates results using [QuizStatisticsService].
  QuizResultSummary completeSession(QuizSession session, Quiz quiz) {
    _validator.validateCompletionAllowed(session);
    _validator.validateSessionAgainstQuiz(session, quiz);

    final now = DateTime.now();
    final finalElapsedTime =
        _timerService.calculateElapsedTime(session, now: now);

    // Map QuestionAttempt list to UserAnswer domain entities for QuizStatisticsService
    final userAnswers = <UserAnswer>[];
    final attemptMap = {for (final a in session.answers) a.questionId: a};

    for (final question in quiz.questions) {
      final attempt = attemptMap[question.id];

      if (attempt == null ||
          !attempt.isAnswered ||
          attempt.selectedOptionId == null) {
        userAnswers.add(UserAnswer(
          questionId: question.id,
          selectedOptionIndex: null,
        ));
      } else {
        final optIdx = question.options
            .indexWhere((o) => o.id == attempt.selectedOptionId);
        userAnswers.add(UserAnswer(
          questionId: question.id,
          selectedOptionIndex: optIdx != -1 ? optIdx : null,
        ));
      }
    }

    final quizResult =
        _statisticsService.generateStatistics(quiz: quiz, answers: userAnswers);

    return QuizResultSummary(
      totalQuestions: quiz.questions.length,
      attempted: quizResult.attempted,
      correct: quizResult.correct,
      wrong: quizResult.wrong,
      unanswered: quizResult.unanswered,
      score: quizResult.score,
      maxScore: quizResult.maxScore,
      percentage: quizResult.percentage,
      timeTaken: finalElapsedTime,
    );
  }
}
