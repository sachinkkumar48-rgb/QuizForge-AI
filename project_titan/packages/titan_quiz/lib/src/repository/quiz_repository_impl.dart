import 'package:titan_storage/titan_storage.dart';

import '../enums/quiz_category.dart';
import '../enums/quiz_difficulty.dart';
import '../enums/quiz_language.dart';
import '../exceptions/quiz_exception.dart';
import '../models/quiz.dart';
import '../models/quiz_metadata.dart';
import '../models/quiz_option.dart';
import '../models/quiz_question.dart';
import '../services/quiz_validation_service.dart';
import '../utils/quiz_utils.dart';
import 'quiz_repository.dart';

/// Concrete implementation of [QuizRepository] coordinating storage persistence and validation.
class QuizRepositoryImpl implements QuizRepository {
  final StorageService _storageService;
  final QuizValidationService _validationService;
  static const String _quizNamespace = 'quizzes';

  bool _isInitialized = false;
  bool _isDisposed = false;

  QuizRepositoryImpl({
    required StorageService storageService,
    QuizValidationService validationService = const QuizValidationService(),
  })  : _storageService = storageService,
        _validationService = validationService;

  @override
  bool get isInitialized => _isInitialized && !_isDisposed;

  @override
  Future<void> initialize() async {
    if (_isDisposed) {
      throw const QuizRepositoryException(
          'Cannot initialize a disposed QuizRepository.');
    }
    try {
      if (!_storageService.isInitialized) {
        await _storageService.initialize();
      }
      _isInitialized = true;
    } catch (e, st) {
      throw QuizRepositoryException(
          'Failed to initialize QuizRepository: $e', e, st);
    }
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
    _isDisposed = true;
  }

  void _checkState() {
    if (_isDisposed) {
      throw const QuizRepositoryException('QuizRepository has been disposed.');
    }
    if (!isInitialized) {
      throw const QuizRepositoryException('QuizRepository is not initialized.');
    }
  }

  @override
  void validateQuiz(Quiz quiz) {
    _validationService.validateQuiz(quiz);
  }

  @override
  Future<Quiz> createQuiz({
    required String title,
    String? description,
    String? sourceDocumentId,
    QuizDifficulty difficulty = QuizDifficulty.medium,
    QuizLanguage language = QuizLanguage.english,
    QuizCategory category = QuizCategory.upsc,
    required List<QuizQuestion> questions,
    QuizMetadata? metadata,
  }) async {
    _checkState();
    try {
      final quizId = QuizUtils.generateQuizId();

      final quiz = Quiz(
        id: quizId,
        title: title,
        description: description,
        sourceDocumentId: sourceDocumentId,
        difficulty: difficulty,
        language: language,
        category: category,
        questions: questions,
        metadata: metadata,
      );

      validateQuiz(quiz);
      await saveQuiz(quiz);
      return quiz;
    } on QuizValidationException {
      rethrow;
    } catch (e, st) {
      throw QuizRepositoryException('Failed to create quiz: $e', e, st);
    }
  }

  @override
  Future<Quiz?> loadQuiz(String quizId) async {
    _checkState();
    try {
      final key = StorageKey(quizId, namespace: _quizNamespace);
      final data = await _storageService.read<Map<String, dynamic>>(key);
      if (data == null) return null;

      return _deserializeQuiz(data);
    } catch (e, st) {
      if (e is QuizException) rethrow;
      throw QuizRepositoryException('Failed to load quiz [$quizId]: $e', e, st);
    }
  }

  @override
  Future<void> saveQuiz(Quiz quiz) async {
    _checkState();
    validateQuiz(quiz);
    try {
      final key = StorageKey(quiz.id, namespace: _quizNamespace);
      final serializedData = _serializeQuiz(quiz);
      await _storageService.write<Map<String, dynamic>>(key, serializedData);
    } catch (e, st) {
      if (e is QuizException) rethrow;
      throw QuizRepositoryException(
          'Failed to save quiz [${quiz.id}]: $e', e, st);
    }
  }

  @override
  Future<void> deleteQuiz(String quizId) async {
    _checkState();
    try {
      final key = StorageKey(quizId, namespace: _quizNamespace);
      await _storageService.delete(key);
    } catch (e, st) {
      throw QuizRepositoryException(
          'Failed to delete quiz [$quizId]: $e', e, st);
    }
  }

  @override
  Future<List<Quiz>> listQuizzes() async {
    _checkState();
    try {
      final keys = await _storageService.keys(namespace: _quizNamespace);
      final quizzes = <Quiz>[];

      for (final key in keys) {
        final data = await _storageService.read<Map<String, dynamic>>(key);
        if (data != null) {
          quizzes.add(_deserializeQuiz(data));
        }
      }

      return quizzes;
    } catch (e, st) {
      throw QuizRepositoryException('Failed to list quizzes: $e', e, st);
    }
  }

  Map<String, dynamic> _serializeQuiz(Quiz quiz) {
    return {
      'id': quiz.id,
      'title': quiz.title,
      'description': quiz.description,
      'sourceDocumentId': quiz.sourceDocumentId,
      'createdAt': quiz.createdAt.toIso8601String(),
      'updatedAt': quiz.updatedAt.toIso8601String(),
      'difficulty': quiz.difficulty.name,
      'language': quiz.language.name,
      'category': quiz.category.name,
      'metadata': {
        'totalQuestions': quiz.metadata.totalQuestions,
        'estimatedDurationMinutes': quiz.metadata.estimatedDurationMinutes,
        'generatedBy': quiz.metadata.generatedBy,
        'version': quiz.metadata.version,
        'tags': quiz.metadata.tags,
      },
      'questions': quiz.questions
          .map((q) => {
                'id': q.id,
                'question': q.question,
                'correctAnswerIndex': q.correctAnswerIndex,
                'explanation': q.explanation,
                'difficulty': q.difficulty.name,
                'topic': q.topic,
                'subtopic': q.subtopic,
                'pageReference': q.pageReference,
                'marks': q.marks,
                'negativeMarks': q.negativeMarks,
                'options': q.options
                    .map((o) => {
                          'id': o.id,
                          'text': o.text,
                          'isCorrect': o.isCorrect,
                        })
                    .toList(),
              })
          .toList(),
    };
  }

  Quiz _deserializeQuiz(Map<String, dynamic> data) {
    final rawMeta = data['metadata'] as Map<String, dynamic>? ?? {};
    final meta = QuizMetadata(
      totalQuestions: rawMeta['totalQuestions'] as int? ?? 0,
      estimatedDurationMinutes:
          rawMeta['estimatedDurationMinutes'] as int? ?? 0,
      generatedBy: rawMeta['generatedBy'] as String? ?? 'TITAN AI Generator',
      version: rawMeta['version'] as String? ?? '1.0.0',
      tags: (rawMeta['tags'] as List<dynamic>?)?.cast<String>(),
    );

    final rawQuestions = data['questions'] as List<dynamic>? ?? [];
    final questions = rawQuestions.map((qRaw) {
      final qMap = qRaw as Map<String, dynamic>;
      final rawOptions = qMap['options'] as List<dynamic>? ?? [];
      final options = rawOptions.map((oRaw) {
        final oMap = oRaw as Map<String, dynamic>;
        return QuizOption(
          id: oMap['id'] as String,
          text: oMap['text'] as String,
          isCorrect: oMap['isCorrect'] as bool? ?? false,
        );
      }).toList();

      return QuizQuestion(
        id: qMap['id'] as String,
        question: qMap['question'] as String,
        options: options,
        correctAnswerIndex: qMap['correctAnswerIndex'] as int,
        explanation: qMap['explanation'] as String?,
        difficulty: QuizDifficulty.values.firstWhere(
          (d) => d.name == qMap['difficulty'],
          orElse: () => QuizDifficulty.medium,
        ),
        topic: qMap['topic'] as String?,
        subtopic: qMap['subtopic'] as String?,
        pageReference: qMap['pageReference'] as int?,
        marks: (qMap['marks'] as num?)?.toDouble() ?? 1.0,
        negativeMarks: (qMap['negativeMarks'] as num?)?.toDouble() ?? 0.33,
      );
    }).toList();

    return Quiz(
      id: data['id'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      sourceDocumentId: data['sourceDocumentId'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      difficulty: QuizDifficulty.values.firstWhere(
        (d) => d.name == data['difficulty'],
        orElse: () => QuizDifficulty.medium,
      ),
      language: QuizLanguage.values.firstWhere(
        (l) => l.name == data['language'],
        orElse: () => QuizLanguage.english,
      ),
      category: QuizCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => QuizCategory.upsc,
      ),
      questions: questions,
      metadata: meta,
    );
  }
}
