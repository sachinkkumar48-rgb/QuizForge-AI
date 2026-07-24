import 'package:meta/meta.dart';
import '../enums/quiz_session_status.dart';
import 'question_attempt.dart';
import 'session_configuration.dart';

/// Immutable aggregate root model representing a user's quiz attempt session.
@immutable
class QuizSession {
  final String sessionId;
  final String quizId;
  final DateTime startedAt;
  final DateTime lastUpdatedAt;
  final DateTime? completedAt;
  final QuizSessionStatus status;
  final List<QuestionAttempt> answers;
  final int currentQuestionIndex;
  final Duration elapsedTime;
  final Duration? remainingTime;
  final SessionConfiguration configuration;

  QuizSession({
    required this.sessionId,
    required this.quizId,
    required this.startedAt,
    required this.lastUpdatedAt,
    this.completedAt,
    this.status = QuizSessionStatus.notStarted,
    List<QuestionAttempt>? answers,
    this.currentQuestionIndex = 0,
    this.elapsedTime = Duration.zero,
    this.remainingTime,
    this.configuration = const SessionConfiguration.standard(),
  }) : answers = List<QuestionAttempt>.unmodifiable(answers ?? const []);

  const QuizSession.constSession({
    required this.sessionId,
    required this.quizId,
    required this.startedAt,
    required this.lastUpdatedAt,
    required this.completedAt,
    required this.status,
    required this.answers,
    required this.currentQuestionIndex,
    required this.elapsedTime,
    required this.remainingTime,
    required this.configuration,
  });

  QuizSession copyWith({
    String? sessionId,
    String? quizId,
    DateTime? startedAt,
    DateTime? lastUpdatedAt,
    DateTime? completedAt,
    QuizSessionStatus? status,
    List<QuestionAttempt>? answers,
    int? currentQuestionIndex,
    Duration? elapsedTime,
    Duration? remainingTime,
    SessionConfiguration? configuration,
  }) {
    return QuizSession(
      sessionId: sessionId ?? this.sessionId,
      quizId: quizId ?? this.quizId,
      startedAt: startedAt ?? this.startedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      answers: answers ?? this.answers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      remainingTime: remainingTime ?? this.remainingTime,
      configuration: configuration ?? this.configuration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! QuizSession || runtimeType != other.runtimeType) return false;
    if (sessionId != other.sessionId ||
        quizId != other.quizId ||
        startedAt != other.startedAt ||
        lastUpdatedAt != other.lastUpdatedAt ||
        completedAt != other.completedAt ||
        status != other.status ||
        currentQuestionIndex != other.currentQuestionIndex ||
        elapsedTime != other.elapsedTime ||
        remainingTime != other.remainingTime ||
        configuration != other.configuration) {
      return false;
    }
    if (answers.length != other.answers.length) return false;
    for (var i = 0; i < answers.length; i++) {
      if (answers[i] != other.answers[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        sessionId,
        quizId,
        startedAt,
        lastUpdatedAt,
        completedAt,
        status,
        Object.hashAll(answers),
        currentQuestionIndex,
        elapsedTime,
        remainingTime,
        configuration,
      );

  @override
  String toString() =>
      'QuizSession(id: $sessionId, quiz: $quizId, status: ${status.name}, index: $currentQuestionIndex, answers: ${answers.length})';
}
