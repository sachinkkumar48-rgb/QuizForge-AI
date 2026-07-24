import 'package:meta/meta.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';
import '../exceptions/application_exception.dart';

/// Enumeration of all application workflow states.
enum ApplicationStateStatus {
  idle,
  loading,
  generatingQuiz,
  ready,
  error,
}

/// Immutable model representing the overall application state.
@immutable
class ApplicationState {
  final ApplicationStateStatus status;
  final QuizSession? currentSession;
  final QuizResultSummary? currentResult;
  final String? errorMessage;
  final ApplicationException? exception;

  const ApplicationState({
    this.status = ApplicationStateStatus.idle,
    this.currentSession,
    this.currentResult,
    this.errorMessage,
    this.exception,
  });

  const ApplicationState.idle()
      : status = ApplicationStateStatus.idle,
        currentSession = null,
        currentResult = null,
        errorMessage = null,
        exception = null;

  const ApplicationState.loading()
      : status = ApplicationStateStatus.loading,
        currentSession = null,
        currentResult = null,
        errorMessage = null,
        exception = null;

  const ApplicationState.generatingQuiz()
      : status = ApplicationStateStatus.generatingQuiz,
        currentSession = null,
        currentResult = null,
        errorMessage = null,
        exception = null;

  const ApplicationState.ready(QuizSession session)
      : status = ApplicationStateStatus.ready,
        currentSession = session,
        currentResult = null,
        errorMessage = null,
        exception = null;

  const ApplicationState.completed(
      QuizSession session, QuizResultSummary result)
      : status = ApplicationStateStatus.ready,
        currentSession = session,
        currentResult = result,
        errorMessage = null,
        exception = null;

  const ApplicationState.error(String message, [ApplicationException? exc])
      : status = ApplicationStateStatus.error,
        currentSession = null,
        currentResult = null,
        errorMessage = message,
        exception = exc;

  bool get isIdle => status == ApplicationStateStatus.idle;
  bool get isLoading => status == ApplicationStateStatus.loading;
  bool get isGeneratingQuiz => status == ApplicationStateStatus.generatingQuiz;
  bool get isReady => status == ApplicationStateStatus.ready;
  bool get hasError => status == ApplicationStateStatus.error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          currentSession == other.currentSession &&
          currentResult == other.currentResult &&
          errorMessage == other.errorMessage &&
          exception == other.exception;

  @override
  int get hashCode => Object.hash(
        status,
        currentSession,
        currentResult,
        errorMessage,
        exception,
      );

  @override
  String toString() =>
      'ApplicationState(status: ${status.name}, session: ${currentSession?.sessionId}, error: $errorMessage)';
}
