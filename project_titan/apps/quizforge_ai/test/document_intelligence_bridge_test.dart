import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/quizforge_ai.dart';
import 'package:titan_ai/titan_ai.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';

class _MockPdfRepository implements PdfRepository {
  final Map<String, PdfDocument> _documents = {};
  final Map<String, List<PdfChunk>> _chunks = {};

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
    final docId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
    final doc = PdfDocument(
      id: docId,
      fileName: filePath.split(RegExp(r'[/\\]')).last,
      displayName: displayName ?? 'Test Document',
      sizeBytes: sizeBytes ?? 1024,
      pageCount: pageCount ?? 1,
      metadata: metadata ?? const PdfMetadata.empty(),
    );
    _documents[docId] = doc;
    return PdfImportResult(document: doc);
  }

  @override
  Future<PdfDocument?> loadPdf(String documentId) async =>
      _documents[documentId];

  @override
  Future<void> deletePdf(String documentId) async {
    _documents.remove(documentId);
    _chunks.remove(documentId);
  }

  @override
  Future<List<PdfDocument>> listDocuments() async => _documents.values.toList();

  @override
  Future<String> extractText(String documentId) async =>
      'Extracted text for $documentId';

  @override
  Future<List<PdfChunk>> createChunks(String documentId,
      {ChunkOptions? options}) async {
    return _chunks[documentId] ??
        [
          PdfChunk(
            chunkId: '${documentId}_chk_0',
            documentId: documentId,
            index: 0,
            text: 'Default chunk text content for $documentId',
            startPage: 1,
            endPage: 1,
            tokenEstimate: 20,
          )
        ];
  }

  @override
  Future<void> saveChunks(String documentId, List<PdfChunk> chunks) async {
    _chunks[documentId] = chunks;
  }
}

class _MockAiService implements AIService {
  const _MockAiService();

  static const String _defaultQuizJson = '''
{
  "title": "Smart Assessment Quiz",
  "description": "Assessment generated from TITAN Document Intelligence",
  "questions": [
    {
      "question": "What is the primary role of the Supreme Court?",
      "options": ["Apex judicial body", "Legislative assembly", "Executive branch", "Electoral council"],
      "correctAnswer": 0,
      "explanation": "The Supreme Court is the apex judicial body in India.",
      "topic": "Judiciary",
      "difficulty": "medium"
    }
  ]
}
''';

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> close() async {}

  @override
  Future<AIResponse<T>> generate<T>(AIRequest request) async {
    return AIResponse<T>(
      text: _defaultQuizJson,
      usage: const AITokenUsage(
          promptTokens: 40, completionTokens: 40, totalTokens: 80),
      model: 'mock-gemini-pro',
      provider: 'google',
      finishReason: 'stop',
    );
  }

  @override
  List<AIModel> availableModels() => const [];

  @override
  AIModel defaultModel() => const AIModel(
        id: 'mock-gemini-pro',
        displayName: 'Mock Gemini Pro',
        contextWindow: 8192,
        maxOutputTokens: 2048,
      );
}

class _MockQuizRepository implements QuizRepository {
  final Map<String, Quiz> _quizzes = {};

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> saveQuiz(Quiz quiz) async {
    _quizzes[quiz.id] = quiz;
  }

  @override
  Future<Quiz?> loadQuiz(String quizId) async => _quizzes[quizId];

  @override
  Future<List<Quiz>> listQuizzes() async => _quizzes.values.toList();

  @override
  Future<void> deleteQuiz(String quizId) async {
    _quizzes.remove(quizId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockQuizSessionRepository implements QuizSessionRepository {
  final Map<String, QuizSession> _sessions = {};

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<QuizSession> createSession(Quiz quiz,
      {SessionConfiguration? configuration}) async {
    final session = QuizSession(
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      quizId: quiz.id,
      startedAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
      status: QuizSessionStatus.inProgress,
      configuration: configuration ?? const SessionConfiguration.standard(),
    );
    _sessions[session.sessionId] = session;
    return session;
  }

  @override
  Future<QuizSession?> loadSession(String sessionId) async =>
      _sessions[sessionId];

  @override
  Future<void> saveSession(QuizSession session) async {
    _sessions[session.sessionId] = session;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    _sessions.remove(sessionId);
  }

  @override
  Future<QuizSession> resumeSession(String sessionId) async {
    final s = _sessions[sessionId];
    if (s == null) throw Exception('Session not found');
    return s;
  }

  @override
  Future<QuizResultSummary> completeSession(String sessionId, Quiz quiz) async {
    throw UnimplementedError();
  }
}

void main() {
  group('Phase 8A: QuizForge AI Document Intelligence Bridge Integration Tests',
      () {
    late _MockPdfRepository pdfRepo;
    late _MockAiService aiService;
    late _MockQuizRepository quizRepo;
    late _MockQuizSessionRepository sessionRepo;
    late QuizGenerationRepository quizGenRepo;
    late ApplicationCoordinator coordinator;

    setUp(() async {
      pdfRepo = _MockPdfRepository();
      aiService = _MockAiService();
      quizRepo = _MockQuizRepository();
      sessionRepo = _MockQuizSessionRepository();

      final genService = AIQuizGenerationService(
        pdfRepository: pdfRepo,
        aiService: aiService,
      );

      quizGenRepo = QuizGenerationRepositoryImpl(
        generationService: genService,
        quizRepository: quizRepo,
      );
      await quizGenRepo.initialize();

      coordinator = ApplicationCoordinator(
        pdfRepository: pdfRepo,
        quizGenerationRepository: quizGenRepo,
        quizSessionRepository: sessionRepo,
        quizRepository: quizRepo,
      );
    });

    test(
        '1. End-to-End: DocumentSource -> DocumentIntelligenceService -> Ingestion -> QuizSession',
        () async {
      // Step 1: Document Intelligence pipeline creates LearningDocument
      final extractor = DefaultPdfTextExtractor(
        nativeExtractor: (source, pageNumber) async =>
            'The Supreme Court of India is the supreme judicial authority. It resolves constitutional disputes.',
        pageCountResolver: (source) async => 1,
      );
      final docIntelService =
          DefaultDocumentIntelligenceService(textExtractor: extractor);

      final source = DocumentSource.fromFilePath(
        filePath: 'C:/docs/indian_judiciary.pdf',
        displayName: 'Indian Judiciary Overview',
        sizeBytes: 4096,
      );

      final ingestionResult = await docIntelService.ingestDocument(source);
      expect(ingestionResult.isSuccess, isTrue);
      expect(ingestionResult.document, isNotNull);
      final learningDoc = ingestionResult.document!;

      // Step 2: QuizForge AI imports LearningDocument directly
      final stages = <QuizWorkflowStage>[];
      final session = await coordinator.importLearningDocument(
        document: learningDoc,
        category: QuizCategory.upsc,
        difficulty: QuizDifficulty.medium,
        onStageChanged: (stage) => stages.add(stage),
      );

      expect(session, isNotNull);
      expect(session.quizId, isNotEmpty);

      final generatedQuiz = await quizRepo.loadQuiz(session.quizId);
      expect(generatedQuiz, isNotNull);
      expect(generatedQuiz!.questions.isNotEmpty, isTrue);
      expect(generatedQuiz.questions.first.question, contains('Supreme Court'));

      expect(coordinator.state.isReady, isTrue);
      expect(stages, [
        QuizWorkflowStage.importingPdf,
        QuizWorkflowStage.generatingQuiz,
        QuizWorkflowStage.creatingSession,
        QuizWorkflowStage.ready,
      ]);
    });

    test('2. Scanned PDF with OCR Fallback generates QuizSession cleanly',
        () async {
      // Setup text extractor with OCR fallback
      final extractor = DefaultPdfTextExtractor(
        nativeExtractor: (source, pageNumber) async => null, // No native text
        ocrFallback: _MockTestOcrProvider(
          onRecognize: (source, pageNumber, lang) async => ExtractedPageText(
            pageNumber: pageNumber,
            text:
                'Article 32 provides the right to constitutional remedies via writs.',
            provenance: TextProvenance.ocr,
            confidence: 0.95,
          ),
        ),
        pageCountResolver: (source) async => 1,
      );

      final docIntelService =
          DefaultDocumentIntelligenceService(textExtractor: extractor);
      final source = DocumentSource.fromFilePath(
        filePath: 'scanned_remedies.pdf',
        displayName: 'Constitutional Remedies',
        sizeBytes: 8192,
      );

      final ingestionResult = await docIntelService.ingestDocument(source);
      expect(ingestionResult.isSuccess, isTrue);
      expect(ingestionResult.document!.provenance, TextProvenance.ocr);

      final session = await coordinator.importLearningDocument(
        document: ingestionResult.document!,
      );

      expect(session.quizId, isNotEmpty);
      final generatedQuiz = await quizRepo.loadQuiz(session.quizId);
      expect(generatedQuiz, isNotNull);
      expect(generatedQuiz!.questions.length, 1);
      expect(coordinator.state.isReady, isTrue);
    });

    test(
        '3. Bilingual Hindi + English Document Ingestion generates QuizSession',
        () async {
      final extractor = DefaultPdfTextExtractor(
        nativeExtractor: (source, pageNumber) async =>
            'Bilingual Context: भारतीय संविधान (Constitution of India) guarantees fundamental rights.',
        pageCountResolver: (source) async => 1,
      );

      final docIntelService =
          DefaultDocumentIntelligenceService(textExtractor: extractor);
      final source = DocumentSource.fromFilePath(
        filePath: 'bilingual_constitution.pdf',
        displayName: 'Bilingual Constitution',
        sizeBytes: 2048,
      );

      final ingestionResult = await docIntelService.ingestDocument(source);
      expect(ingestionResult.isSuccess, isTrue);
      expect(ingestionResult.document!.primaryLanguage, 'bilingual');

      final session = await coordinator.importLearningDocument(
        document: ingestionResult.document!,
        language: QuizLanguage.hindi,
      );

      expect(session, isNotNull);
      expect(coordinator.state.isReady, isTrue);
    });
  });
}

class _MockTestOcrProvider implements OcrFallbackProvider {
  final Future<ExtractedPageText> Function(
    DocumentSource source,
    int pageNumber,
    String? preferredLanguage,
  ) onRecognize;

  const _MockTestOcrProvider({required this.onRecognize});

  @override
  Future<ExtractedPageText> recognizePage({
    required DocumentSource source,
    required int pageNumber,
    String? preferredLanguage,
  }) {
    return onRecognize(source, pageNumber, preferredLanguage);
  }
}
