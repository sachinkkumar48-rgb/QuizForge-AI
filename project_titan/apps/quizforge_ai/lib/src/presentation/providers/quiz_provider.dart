import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';
import 'application_provider.dart';
import '../../states/quiz_workflow_state.dart';

/// AsyncNotifier managing quiz creation UI state via [ApplicationCoordinator].
class QuizAsyncNotifier extends Notifier<QuizWorkflowState> {
  @override
  QuizWorkflowState build() {
    return const QuizWorkflowState.idle();
  }

  /// Opens the native platform picker for PDF selection.
  Future<void> selectPdf() async {
    state = state.copyWith(
      stage: QuizWorkflowStage.selectingFile,
      clearError: true,
    );

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        allowMultiple: false,
      );

      final file = result?.files.single;
      if (file == null || file.path == null) {
        state = state.copyWith(stage: QuizWorkflowStage.idle);
        return;
      }

      state = QuizWorkflowState(
        stage: QuizWorkflowStage.idle,
        selectedFilePath: file.path,
        selectedFileName: file.name,
      );
    } catch (_) {
      state = state.copyWith(
        stage: QuizWorkflowStage.error,
        errorMessage: 'Unable to select the PDF. Please try again.',
      );
    }
  }

  /// Triggers PDF import and quiz session creation workflow.
  Future<QuizSession?> createQuizFromPdf([String? filePath]) async {
    final targetPath = filePath ?? state.selectedFilePath;
    if (targetPath == null || targetPath.trim().isEmpty) {
      state = state.copyWith(
        stage: QuizWorkflowStage.error,
        errorMessage: 'Select a PDF before generating a quiz.',
      );
      return null;
    }

    try {
      final coordinator = ref.read(applicationCoordinatorProvider);
      final session = await coordinator.importPdf(
        filePath: targetPath,
        onStageChanged: (stage) {
          state = state.copyWith(stage: stage, clearError: true);
        },
      );
      ref.read(applicationStateProvider.notifier).updateState();
      state = state.copyWith(
        stage: QuizWorkflowStage.ready,
        session: session,
        clearError: true,
      );
      return session;
    } catch (_) {
      ref.read(applicationStateProvider.notifier).updateState();
      state = state.copyWith(
        stage: QuizWorkflowStage.error,
        errorMessage: 'We could not prepare your quiz. Please try again.',
      );
      return null;
    }
  }

  /// Retries the currently selected PDF workflow.
  Future<QuizSession?> retry() {
    return createQuizFromPdf();
  }
}

/// Provider for quiz generation state.
final quizProvider = NotifierProvider<QuizAsyncNotifier, QuizWorkflowState>(
    QuizAsyncNotifier.new);
