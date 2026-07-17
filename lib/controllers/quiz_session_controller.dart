import 'dart:async';
import '../models/quiz_analytics.dart';
import '../models/quiz_attempt.dart';
import '../models/quiz_model.dart';
import '../models/quiz_session.dart';
import '../repositories/quiz_history_repository.dart';
import '../repositories/quiz_session_repository.dart';

class QuizSessionController {
  final String sessionId;
  final DateTime createdAt;
  final String sourceName;
  final List<QuizQuestion> questions;
  final void Function() onStateChanged;
  final Duration duration;
  final void Function(QuizAnalytics analytics) onTimeUp;

  int currentQuestionIndex = 0;
  final Map<int, String?> answers = {};
  final Map<int, QuestionStatus> statuses = {};

  late int _remainingSeconds;
  Timer? _timer;

  QuizSessionController({
    this.sourceName = "Practice Quiz",
    required this.questions,
    required this.onStateChanged,
    this.duration = const Duration(hours: 2),
    required this.onTimeUp,
    QuizSession? restoredSession,
  })  : sessionId = restoredSession?.sessionId ??
            "${DateTime.now().microsecondsSinceEpoch}",
        createdAt = restoredSession?.createdAt ?? DateTime.now() {
    if (restoredSession != null) {
      currentQuestionIndex = restoredSession.currentQuestionIndex;
      answers.addAll(restoredSession.selectedAnswers);
      statuses.addAll(restoredSession.questionStatuses);
      _remainingSeconds = restoredSession.remainingTime.inSeconds;
    } else {
      _remainingSeconds = duration.inSeconds;
      if (questions.isNotEmpty) {
        _updateVisitedStatus();
      }
    }
    _startTimer();
  }

  QuizQuestion get currentQuestion => questions[currentQuestionIndex];

  Duration get remainingTime => Duration(seconds: _remainingSeconds);

  bool get isTimeUp => _remainingSeconds <= 0;

  String get formattedRemainingTime {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;

    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    return "$hStr:$mStr:$sStr";
  }

  QuizAnalytics generateAnalytics() {
    int correct = 0;
    answers.forEach((index, selected) {
      if (selected == questions[index].answer) {
        correct++;
      }
    });

    final attemptedVal = answers.values.where((e) => e != null).length;
    final skippedVal = questions.length - attemptedVal;
    final incorrectVal = attemptedVal - correct;
    final accuracyVal =
        questions.isEmpty ? 0.0 : (correct / questions.length) * 100;

    PerformanceLevel level;
    if (accuracyVal >= 80) {
      level = PerformanceLevel.excellent;
    } else if (accuracyVal >= 60) {
      level = PerformanceLevel.good;
    } else if (accuracyVal >= 40) {
      level = PerformanceLevel.average;
    } else {
      level = PerformanceLevel.needsImprovement;
    }

    final Map<QuestionStatus, int> counts = {
      QuestionStatus.notVisited: 0,
      QuestionStatus.visited: 0,
      QuestionStatus.answered: 0,
      QuestionStatus.markedForReview: 0,
    };

    for (int i = 0; i < questions.length; i++) {
      final s = statuses[i] ?? QuestionStatus.notVisited;
      counts[s] = (counts[s] ?? 0) + 1;
    }

    final spentSeconds = duration.inSeconds - _remainingSeconds;

    return QuizAnalytics(
      score: correct,
      totalQuestions: questions.length,
      attempted: attemptedVal,
      skipped: skippedVal,
      incorrect: incorrectVal,
      accuracy: accuracyVal,
      performanceLevel: level,
      timeSpent: Duration(seconds: spentSeconds),
      remainingTime: remainingTime,
      totalDuration: duration,
      statusCounts: counts,
    );
  }

  Future<void> saveSession() async {
    final session = QuizSession(
      sessionId: sessionId,
      sourceName: sourceName,
      createdAt: createdAt,
      lastSavedAt: DateTime.now(),
      totalQuestions: questions.length,
      currentQuestionIndex: currentQuestionIndex,
      remainingTime: Duration(seconds: _remainingSeconds),
      selectedAnswers: answers,
      questionStatuses: statuses,
      quizQuestions: questions,
    );
    await QuizSessionRepository().saveSession(session);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        onStateChanged();

        final spentSeconds = duration.inSeconds - _remainingSeconds;
        if (spentSeconds > 0 && spentSeconds % 30 == 0) {
          saveSession();
        }

        if (_remainingSeconds <= 0) {
          _stopTimer();
          _submitOnTimeUp();
        }
      } else {
        _stopTimer();
        _submitOnTimeUp();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _saveQuizAttempt(QuizAnalytics analytics) async {
    final attempt = QuizAttempt(
      id: "${DateTime.now().microsecondsSinceEpoch}_${analytics.score}",
      completedAt: DateTime.now(),
      sourceName: sourceName,
      analytics: analytics,
    );
    await QuizHistoryRepository().saveAttempt(attempt);
  }

  void _submitOnTimeUp() async {
    final analytics = generateAnalytics();
    await _saveQuizAttempt(analytics);
    await QuizSessionRepository().deleteSession();
    onTimeUp(analytics);
  }

  void _updateVisitedStatus() {
    final status = statuses[currentQuestionIndex] ?? QuestionStatus.notVisited;
    if (status == QuestionStatus.notVisited) {
      statuses[currentQuestionIndex] = QuestionStatus.visited;
    }
  }

  void selectAnswer(String option) {
    answers[currentQuestionIndex] = option;
    statuses[currentQuestionIndex] = QuestionStatus.answered;
    onStateChanged();
    saveSession();
  }

  void toggleMarkForReview() {
    final currentStatus =
        statuses[currentQuestionIndex] ?? QuestionStatus.notVisited;
    if (currentStatus == QuestionStatus.markedForReview) {
      if (answers[currentQuestionIndex] != null) {
        statuses[currentQuestionIndex] = QuestionStatus.answered;
      } else {
        statuses[currentQuestionIndex] = QuestionStatus.visited;
      }
    } else {
      statuses[currentQuestionIndex] = QuestionStatus.markedForReview;
    }
    onStateChanged();
    saveSession();
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      currentQuestionIndex--;
      _updateVisitedStatus();
      onStateChanged();
      saveSession();
    }
  }

  void nextQuestion({
    required void Function(QuizAnalytics analytics) onFinished,
  }) {
    if (currentQuestionIndex < questions.length - 1) {
      currentQuestionIndex++;
      _updateVisitedStatus();
      onStateChanged();
      saveSession();
    } else {
      submitQuiz(onFinished: onFinished);
    }
  }

  Future<void> submitQuiz({
    required void Function(QuizAnalytics analytics) onFinished,
  }) async {
    _stopTimer();
    final analytics = generateAnalytics();
    await _saveQuizAttempt(analytics);
    await QuizSessionRepository().deleteSession();
    onFinished(analytics);
  }

  void jumpToQuestion(int index) {
    if (index >= 0 && index < questions.length) {
      currentQuestionIndex = index;
      _updateVisitedStatus();
      onStateChanged();
      saveSession();
    }
  }

  void dispose() {
    _stopTimer();
  }
}
