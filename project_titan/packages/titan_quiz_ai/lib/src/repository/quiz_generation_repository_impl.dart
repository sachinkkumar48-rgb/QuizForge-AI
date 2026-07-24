import 'package:titan_quiz/titan_quiz.dart';
import '../exceptions/quiz_generation_exception.dart';
import '../models/quiz_generation_request.dart';
import '../models/quiz_generation_result.dart';
import '../services/ai_quiz_generation_service.dart';
import 'quiz_generation_repository.dart';

/// Concrete implementation of [QuizGenerationRepository] coordinating generation and persistence.
class QuizGenerationRepositoryImpl implements QuizGenerationRepository {
  final AIQuizGenerationService _generationService;
  final QuizRepository _quizRepository;

  bool _isInitialized = false;
  bool _isDisposed = false;

  QuizGenerationRepositoryImpl({
    required AIQuizGenerationService generationService,
    required QuizRepository quizRepository,
  })  : _generationService = generationService,
        _quizRepository = quizRepository;

  @override
  bool get isInitialized => _isInitialized && !_isDisposed;

  @override
  Future<void> initialize() async {
    if (_isDisposed) {
      throw const JsonParsingException(
          'Cannot initialize disposed QuizGenerationRepository.');
    }
    if (!_quizRepository.isInitialized) {
      await _quizRepository.initialize();
    }
    _isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
    _isDisposed = true;
  }

  void _checkState() {
    if (_isDisposed) {
      throw const JsonParsingException(
          'QuizGenerationRepository has been disposed.');
    }
    if (!isInitialized) {
      throw const JsonParsingException(
          'QuizGenerationRepository is not initialized.');
    }
  }

  @override
  Future<QuizGenerationResult> generateQuiz(
      QuizGenerationRequest request) async {
    _checkState();
    try {
      final result = await _generationService.generateQuiz(request);
      await _quizRepository.saveQuiz(result.quiz);
      return result;
    } catch (e, st) {
      if (e is QuizGenerationException) rethrow;
      throw JsonParsingException(
          'Quiz generation pipeline failed: ${e.toString()}', e, st);
    }
  }
}
