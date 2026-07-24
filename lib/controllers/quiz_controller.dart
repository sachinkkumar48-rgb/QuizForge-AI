import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/di/service_locator_init.dart';
import '../domain/usecases/generate_quiz_usecase.dart';
import '../models/quiz_model.dart';
import 'quiz_generation_state.dart';

/// Presentation Controller managing quiz generation workflow and state transitions
/// by delegating execution strictly to [GenerateQuizUseCase] in the Domain Layer.
class QuizController extends ValueNotifier<QuizGenerationState> {
  final GenerateQuizUseCase _generateQuizUseCase;

  QuizController({GenerateQuizUseCase? generateQuizUseCase})
      : _generateQuizUseCase =
            generateQuizUseCase ?? locate<GenerateQuizUseCase>(),
        super(QuizGenerationState.idle());

  QuizGenerationState get state => value;

  Future<QuizModel> generateQuiz(
    PlatformFile pdf, {
    int questionCount = 10,
    void Function(String message)? onProgress,
  }) async {
    value = QuizGenerationState.generating(
      message: "Initializing quiz generation...",
    );

    try {
      final quizModel = await _generateQuizUseCase.execute(
        pdf,
        questionCount: questionCount,
        onProgress: (msg) {
          value = QuizGenerationState.generating(message: msg);
          onProgress?.call(msg);
        },
      );

      value = QuizGenerationState.success(quizModel);
      return quizModel;
    } catch (e) {
      final errorMsg = e.toString().replaceAll("Exception: ", "");
      final isApiKeyError = errorMsg.contains("API Key") ||
          errorMsg.contains("API key") ||
          errorMsg.contains("apiKey");

      value = QuizGenerationState.error(
        errorMsg,
        error: e,
        isApiKeyError: isApiKeyError,
      );
      rethrow;
    }
  }

  void resetState() {
    value = QuizGenerationState.idle();
  }
}
