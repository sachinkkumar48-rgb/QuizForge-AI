import 'package:titan_domain/titan_domain.dart';
import '../models/quiz_generation_request.dart';
import '../models/quiz_generation_result.dart';

/// Repository contract for coordinating AI quiz generation, validation, and storage persistence.
abstract class QuizGenerationRepository
    implements Repository<QuizGenerationResult> {
  /// Generates a validated [QuizGenerationResult] from [request] and persists the quiz.
  Future<QuizGenerationResult> generateQuiz(QuizGenerationRequest request);
}
