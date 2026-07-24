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
      ),
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

Future<ApplicationCoordinator> buildMockCoordinator() async {
  final pdfRepo = MockPdfRepository();
  final aiService = MockAIService();
  final quizRepo = MockQuizRepository();
  await quizRepo.initialize();

  final genService = AIQuizGenerationService(
    pdfRepository: pdfRepo,
    aiService: aiService,
  );

  final quizGenRepo = QuizGenerationRepositoryImpl(
    generationService: genService,
    quizRepository: quizRepo,
  );
  await quizGenRepo.initialize();

  final sessionRepo = QuizSessionRepositoryImpl();
  await sessionRepo.initialize();

  return ApplicationCoordinator(
    pdfRepository: pdfRepo,
    quizGenerationRepository: quizGenRepo,
    quizSessionRepository: sessionRepo,
    quizRepository: quizRepo,
  );
}
