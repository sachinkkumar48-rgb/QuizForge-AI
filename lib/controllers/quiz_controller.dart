import 'package:file_picker/file_picker.dart';

import '../models/quiz_model.dart';
import '../repositories/quiz_repository.dart';

class QuizController {
  final QuizRepository _repository = QuizRepository();

  Future<List<QuizQuestion>> generateQuiz(
      PlatformFile pdf,
      ) async {
    return await _repository.generateQuiz(pdf);
  }
}