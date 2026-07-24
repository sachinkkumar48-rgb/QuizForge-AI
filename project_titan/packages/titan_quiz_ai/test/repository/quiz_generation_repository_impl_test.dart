import 'package:test/test.dart';
import 'package:titan_ai/titan_ai.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';

class MockQuizRepository implements QuizRepository {
  bool _initialized = false;
  Quiz? _savedQuiz;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
  }

  @override
  Future<void> saveQuiz(Quiz quiz) async {
    _savedQuiz = quiz;
  }

  @override
  Future<Quiz?> loadQuiz(String quizId) async {
    return _savedQuiz?.id == quizId ? _savedQuiz : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummyPdfRepository implements PdfRepository {
  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<List<PdfChunk>> createChunks(String documentId,
      {ChunkOptions? options}) async {
    return [
      PdfChunk(
        chunkId: 'c1',
        documentId: documentId,
        index: 0,
        text: 'Sample PDF passage text for testing.',
        startPage: 1,
        endPage: 1,
        tokenEstimate: 20,
      )
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummyAIService implements AIService {
  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> close() async {}

  @override
  Future<AIResponse<T>> generate<T>(AIRequest request) async {
    return AIResponse<T>(
      text: '''
{
  "title": "Repo Pipeline Quiz",
  "questions": [
    {
      "question": "Sample Repo Q?",
      "options": ["A", "B"],
      "correctAnswer": 0
    }
  ]
}
''',
      usage: const AITokenUsage(
          promptTokens: 10, completionTokens: 10, totalTokens: 20),
      model: 'dummy-model',
      provider: 'dummy',
      finishReason: 'stop',
    );
  }

  @override
  List<AIModel> availableModels() => const [];

  @override
  AIModel defaultModel() => const AIModel(
        id: 'dummy',
        displayName: 'dummy',
        contextWindow: 1000,
        maxOutputTokens: 1000,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('QuizGenerationRepositoryImpl Tests', () {
    late MockQuizRepository mockQuizRepo;
    late AIQuizGenerationService generationService;
    late QuizGenerationRepositoryImpl repo;

    setUp(() {
      mockQuizRepo = MockQuizRepository();
      generationService = AIQuizGenerationService(
        pdfRepository: DummyPdfRepository(),
        aiService: DummyAIService(),
      );
      repo = QuizGenerationRepositoryImpl(
        generationService: generationService,
        quizRepository: mockQuizRepo,
      );
    });

    test('Throws exception when calling generateQuiz before initialize',
        () async {
      final request = QuizGenerationRequest(documentId: 'doc1');
      expect(() => repo.generateQuiz(request),
          throwsA(isA<QuizGenerationException>()));
    });

    test('Initializes repo and persists generated Quiz into QuizRepository',
        () async {
      await repo.initialize();
      expect(repo.isInitialized, isTrue);

      final request = QuizGenerationRequest(documentId: 'doc_test_1');
      final result = await repo.generateQuiz(request);

      expect(result.quiz.title, equals('Repo Pipeline Quiz'));

      // Verify stored in QuizRepository
      final savedQuiz = await mockQuizRepo.loadQuiz(result.quiz.id);
      expect(savedQuiz, isNotNull);
      expect(savedQuiz!.title, equals('Repo Pipeline Quiz'));
    });
  });
}
