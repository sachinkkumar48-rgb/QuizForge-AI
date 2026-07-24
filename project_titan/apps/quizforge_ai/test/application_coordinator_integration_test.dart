import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ai/titan_ai.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';
import 'package:quizforge_ai/quizforge_ai.dart';

class MockPdfRepository implements PdfRepository {
  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<PdfImportResult> importPdf(
    String filePath, {
    String? displayName,
    int? sizeBytes,
    int? pageCount,
    PdfMetadata? metadata,
    List<int>? headerBytes,
    bool isEncrypted = false,
    bool isCorrupted = false,
    bool isEmpty = false,
  }) async {
    final doc = PdfDocument(
      id: 'doc_integration_1',
      fileName: 'polity_notes.pdf',
      displayName: displayName ?? 'Polity Notes',
      sizeBytes: sizeBytes ?? 1024,
      pageCount: pageCount ?? 2,
    );
    return PdfImportResult(document: doc);
  }

  @override
  Future<String> extractText(String documentId) async {
    return 'Article 14 guarantees equality before law.';
  }

  @override
  Future<List<PdfChunk>> createChunks(String documentId,
      {ChunkOptions? options}) async {
    return [
      PdfChunk(
        chunkId: 'chk_1',
        documentId: documentId,
        index: 0,
        text: 'Article 14 guarantees equality before law.',
        startPage: 1,
        endPage: 1,
        tokenEstimate: 20,
      )
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAIService implements AIService {
  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> close() async {}

  @override
  Future<AIResponse<T>> generate<T>(AIRequest request) async {
    const jsonText = '''
{
  "title": "UPSC Polity Mock",
  "description": "Integration Test Quiz",
  "questions": [
    {
      "question": "What does Article 14 guarantee?",
      "options": ["Equality before law", "Right to property", "Right to title", "Right to assembly"],
      "correctAnswer": 0,
      "explanation": "Article 14 guarantees equality before law.",
      "topic": "Fundamental Rights",
      "difficulty": "medium"
    }
  ]
}
''';
    return AIResponse<T>(
      text: jsonText,
      usage: const AITokenUsage(
          promptTokens: 50, completionTokens: 50, totalTokens: 100),
      model: 'mock-ai-model',
      provider: 'mock-provider',
      finishReason: 'stop',
    );
  }

  @override
  List<AIModel> availableModels() => const [];

  @override
  AIModel defaultModel() => const AIModel(
        id: 'mock',
        displayName: 'mock',
        contextWindow: 1000,
        maxOutputTokens: 1000,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockQuizRepository implements QuizRepository {
  bool _initialized = true;
  final Map<String, Quiz> _quizzes = {};

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> saveQuiz(Quiz quiz) async {
    _quizzes[quiz.id] = quiz;
  }

  @override
  Future<Quiz?> loadQuiz(String quizId) async {
    return _quizzes[quizId];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('QuizForge AI End-to-End Application Coordinator Integration Tests',
      () {
    late MockPdfRepository pdfRepo;
    late MockAIService aiService;
    late MockQuizRepository quizRepo;
    late QuizGenerationRepositoryImpl quizGenRepo;
    late QuizSessionRepositoryImpl sessionRepo;
    late ApplicationCoordinator coordinator;

    setUp(() async {
      pdfRepo = MockPdfRepository();
      aiService = MockAIService();
      quizRepo = MockQuizRepository();
      await quizRepo.initialize();

      final genService = AIQuizGenerationService(
        pdfRepository: pdfRepo,
        aiService: aiService,
      );

      quizGenRepo = QuizGenerationRepositoryImpl(
        generationService: genService,
        quizRepository: quizRepo,
      );
      await quizGenRepo.initialize();

      sessionRepo = QuizSessionRepositoryImpl();
      await sessionRepo.initialize();

      coordinator = ApplicationCoordinator(
        pdfRepository: pdfRepo,
        quizGenerationRepository: quizGenRepo,
        quizSessionRepository: sessionRepo,
        quizRepository: quizRepo,
      );
    });

    test(
        'Complete Workflow: PDF Import -> Quiz Generation -> Session Creation -> Attempt -> Result',
        () async {
      expect(coordinator.state.isIdle, isTrue);

      // Step 1 - 5: Import PDF, Generate Quiz, Create Quiz Session
      final session = await coordinator.createQuizSessionFromPdf(
        filePath: 'c:/docs/polity.pdf',
        category: QuizCategory.upsc,
        difficulty: QuizDifficulty.medium,
      );

      expect(coordinator.state.isReady, isTrue);
      expect(session.status, equals(QuizSessionStatus.inProgress));
      expect(session.answers.length, equals(1));
      expect(session.answers.first.isAnswered, isFalse);

      // Answer question in session
      final questionId = session.answers.first.questionId;
      final loadedQuiz = await quizRepo.loadQuiz(session.quizId);
      expect(loadedQuiz, isNotNull);

      final selectedOptId = loadedQuiz!.questions.first.options.first.id;

      final updatedSession = await coordinator.answerQuestion(
        sessionId: session.sessionId,
        questionId: questionId,
        selectedOptionId: selectedOptId,
        sessionService: const QuizSessionService(),
      );

      expect(updatedSession.answers.first.isAnswered, isTrue);
      expect(
          updatedSession.answers.first.selectedOptionId, equals(selectedOptId));

      // Complete session and generate result summary
      final summary =
          await coordinator.completeSession(sessionId: session.sessionId);

      expect(summary.totalQuestions, equals(1));
      expect(summary.attempted, equals(1));
      expect(summary.correct, equals(1));
      expect(summary.score, equals(2.0));
      expect(summary.percentage, equals(100.0));
    });

    test('Error Handling: Wraps lower level failures in ApplicationException',
        () async {
      final badPdfRepo = MockPdfRepository();
      final badCoordinator = ApplicationCoordinator(
        pdfRepository: badPdfRepo,
        quizGenerationRepository: quizGenRepo,
        quizSessionRepository: sessionRepo,
        quizRepository: quizRepo,
      );

      await expectLater(
        badCoordinator.completeSession(sessionId: 'non_existent_session'),
        throwsA(isA<ApplicationException>()),
      );

      expect(badCoordinator.state.hasError, isTrue);
      expect(badCoordinator.state.errorMessage,
          contains('Session [non_existent_session] not found'));
    });
  });
}
