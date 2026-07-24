import 'package:titan_domain/titan_domain.dart';

import '../enums/quiz_category.dart';
import '../enums/quiz_difficulty.dart';
import '../enums/quiz_language.dart';
import '../models/quiz.dart';
import '../models/quiz_metadata.dart';
import '../models/quiz_question.dart';

/// Repository contract for managing Quiz entities, storage, and validation in Project TITAN.
abstract class QuizRepository implements Repository<Quiz> {
  /// Creates and validates a new [Quiz] instance.
  Future<Quiz> createQuiz({
    required String title,
    String? description,
    String? sourceDocumentId,
    QuizDifficulty difficulty = QuizDifficulty.medium,
    QuizLanguage language = QuizLanguage.english,
    QuizCategory category = QuizCategory.upsc,
    required List<QuizQuestion> questions,
    QuizMetadata? metadata,
  });

  /// Loads a [Quiz] by [quizId]. Returns null if not found.
  Future<Quiz?> loadQuiz(String quizId);

  /// Deletes a [Quiz] by [quizId].
  Future<void> deleteQuiz(String quizId);

  /// Returns a list of all persisted [Quiz] documents.
  Future<List<Quiz>> listQuizzes();

  /// Persists a [Quiz] into storage.
  Future<void> saveQuiz(Quiz quiz);

  /// Validates a [Quiz] entity against domain rules.
  void validateQuiz(Quiz quiz);
}
