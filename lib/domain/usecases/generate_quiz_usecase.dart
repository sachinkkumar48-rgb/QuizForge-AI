import 'package:file_picker/file_picker.dart';

import '../../models/quiz_model.dart';
import '../../repositories/titan_quiz_repository.dart';

/// Domain use case contract encapsulating quiz generation from a PDF document.
abstract class GenerateQuizUseCase {
  Future<QuizModel> execute(
    PlatformFile pdf, {
    int questionCount = 10,
    void Function(String message)? onProgress,
  });
}

/// Concrete implementation of [GenerateQuizUseCase] delegating to [TitanQuizRepository].
class GenerateQuizUseCaseImpl implements GenerateQuizUseCase {
  final TitanQuizRepository _repository;

  GenerateQuizUseCaseImpl({required TitanQuizRepository repository})
      : _repository = repository;

  @override
  Future<QuizModel> execute(
    PlatformFile pdf, {
    int questionCount = 10,
    void Function(String message)? onProgress,
  }) async {
    return await _repository.generateQuiz(
      pdf,
      questionCount: questionCount,
      onProgress: onProgress,
    );
  }
}
