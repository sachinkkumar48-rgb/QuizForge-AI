import 'dart:async';
import '../models/quiz_model.dart';

class QuizSessionController {
  final List<QuizQuestion> questions;
  final void Function() onStateChanged;
  final Duration duration;
  final void Function(int score, int total, int attempted) onTimeUp;

  int currentQuestionIndex = 0;
  final Map<int, String?> answers = {};
  final Map<int, QuestionStatus> statuses = {};

  late int _remainingSeconds;
  Timer? _timer;

  QuizSessionController({
    required this.questions,
    required this.onStateChanged,
    this.duration = const Duration(hours: 2),
    required this.onTimeUp,
  }) {
    _remainingSeconds = duration.inSeconds;
    if (questions.isNotEmpty) {
      _updateVisitedStatus();
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

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        onStateChanged();
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

  void _submitOnTimeUp() {
    int correct = 0;
    answers.forEach((index, selected) {
      if (selected == questions[index].answer) {
        correct++;
      }
    });
    final attempted = answers.values.where((e) => e != null).length;
    onTimeUp(correct, questions.length, attempted);
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
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      currentQuestionIndex--;
      _updateVisitedStatus();
      onStateChanged();
    }
  }

  void nextQuestion({
    required void Function(int score, int total, int attempted) onFinished,
  }) {
    if (currentQuestionIndex < questions.length - 1) {
      currentQuestionIndex++;
      _updateVisitedStatus();
      onStateChanged();
    } else {
      submitQuiz(onFinished: onFinished);
    }
  }

  void submitQuiz({
    required void Function(int score, int total, int attempted) onFinished,
  }) {
    _stopTimer();
    int correct = 0;
    answers.forEach((index, selected) {
      if (selected == questions[index].answer) {
        correct++;
      }
    });
    final attempted = answers.values.where((e) => e != null).length;
    onFinished(correct, questions.length, attempted);
  }

  void jumpToQuestion(int index) {
    if (index >= 0 && index < questions.length) {
      currentQuestionIndex = index;
      _updateVisitedStatus();
      onStateChanged();
    }
  }

  void dispose() {
    _stopTimer();
  }
}
