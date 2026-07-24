import 'package:meta/meta.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';

/// Presentation-only workflow stages for PDF import and quiz generation.
enum QuizWorkflowStage {
  idle,
  selectingFile,
  importingPdf,
  extractingText,
  creatingChunks,
  generatingQuiz,
  creatingSession,
  ready,
  error,
}

@immutable
class QuizWorkflowState {
  final QuizWorkflowStage stage;
  final String? selectedFilePath;
  final String? selectedFileName;
  final QuizSession? session;
  final String? errorMessage;

  const QuizWorkflowState({
    required this.stage,
    this.selectedFilePath,
    this.selectedFileName,
    this.session,
    this.errorMessage,
  });

  const QuizWorkflowState.idle() : this(stage: QuizWorkflowStage.idle);

  bool get canStartQuiz => session != null;

  bool get isBusy {
    return stage == QuizWorkflowStage.selectingFile ||
        stage == QuizWorkflowStage.importingPdf ||
        stage == QuizWorkflowStage.extractingText ||
        stage == QuizWorkflowStage.creatingChunks ||
        stage == QuizWorkflowStage.generatingQuiz ||
        stage == QuizWorkflowStage.creatingSession;
  }

  String get operationMessage {
    switch (stage) {
      case QuizWorkflowStage.idle:
        return 'Choose a PDF to begin.';
      case QuizWorkflowStage.selectingFile:
        return 'Selecting file...';
      case QuizWorkflowStage.importingPdf:
        return 'Importing PDF...';
      case QuizWorkflowStage.extractingText:
        return 'Extracting Text...';
      case QuizWorkflowStage.creatingChunks:
        return 'Creating Chunks...';
      case QuizWorkflowStage.generatingQuiz:
        return 'Generating Questions...';
      case QuizWorkflowStage.creatingSession:
        return 'Creating Session...';
      case QuizWorkflowStage.ready:
        return 'Quiz is ready.';
      case QuizWorkflowStage.error:
        return errorMessage ?? 'Unable to prepare quiz.';
    }
  }

  QuizWorkflowState copyWith({
    QuizWorkflowStage? stage,
    String? selectedFilePath,
    String? selectedFileName,
    QuizSession? session,
    String? errorMessage,
    bool clearError = false,
  }) {
    return QuizWorkflowState(
      stage: stage ?? this.stage,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      selectedFileName: selectedFileName ?? this.selectedFileName,
      session: session ?? this.session,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
