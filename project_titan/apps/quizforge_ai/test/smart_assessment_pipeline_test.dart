import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/quizforge_ai.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';

void main() {
  late _MockPdfRepository pdfRepository;
  late _MockQuizRepository quizRepository;
  late _MockQuizSessionRepository quizSessionRepository;
  late _MockQuizGenerationRepository quizGenerationRepository;
  late ApplicationCoordinator coordinator;
  late FakeAssessmentGenerator fakeGenerator;

  setUp(() {
    pdfRepository = _MockPdfRepository();
    quizRepository = _MockQuizRepository();
    quizSessionRepository = _MockQuizSessionRepository();
    quizGenerationRepository = _MockQuizGenerationRepository();
    fakeGenerator = FakeAssessmentGenerator();

    coordinator = ApplicationCoordinator(
      pdfRepository: pdfRepository,
      quizRepository: quizRepository,
      quizSessionRepository: quizSessionRepository,
      quizGenerationRepository: quizGenerationRepository,
    );
  });

  group('Phase 8B: QuizForge AI Smart Assessment Pipeline Tests', () {
    test(
        '1. End-to-end: Digital PDF LearningDocument -> Smart Assessment -> Ready QuizSession',
        () async {
      final chunk1 = LearningDocumentChunk(
        chunkId: 'chk_p1_0',
        documentId: 'doc_digital_101',
        index: 0,
        text:
            'The Preamble to the Indian Constitution declares India to be a Sovereign Socialist Secular Democratic Republic.',
        startPage: 1,
        endPage: 1,
        provenance: TextProvenance.nativePdf,
        script: 'latin',
        tokenEstimate: 20,
      );

      final doc = LearningDocument(
        id: 'doc_digital_101',
        fileName: 'constitution.pdf',
        displayName: 'Constitution Overview',
        totalPages: 1,
        sizeBytes: 2048,
        createdAt: DateTime.now(),
        chunks: [chunk1],
        primaryLanguage: 'latin',
      );

      final blueprint = AssessmentBlueprint(
        documentId: 'doc_digital_101',
        targetQuestions: 2,
        difficulty: QuizDifficulty.medium,
        language: QuizLanguage.english,
        category: QuizCategory.upsc,
        topicHint: 'Preamble',
      );

      final stagesRecorded = <QuizWorkflowStage>[];

      final session = await coordinator.generateSmartAssessment(
        document: doc,
        blueprint: blueprint,
        assessmentGenerator: fakeGenerator,
        onStageChanged: (stage) => stagesRecorded.add(stage),
      );

      expect(session, isNotNull);
      expect(session.quizId, isNotEmpty);
      expect(coordinator.state.isReady, isTrue);
      expect(
          stagesRecorded,
          containsAll([
            QuizWorkflowStage.importingPdf,
            QuizWorkflowStage.generatingQuiz,
            QuizWorkflowStage.creatingSession,
            QuizWorkflowStage.ready,
          ]));

      // Verify quiz is persisted in repository
      final loadedQuiz = await quizRepository.loadQuiz(session.quizId);
      expect(loadedQuiz, isNotNull);
      expect(loadedQuiz!.questions.length, 2);
      expect(loadedQuiz.sourceDocumentId, isNotEmpty);
    });

    test(
        '2. End-to-end: Scanned OCR LearningDocument -> Smart Assessment preserves OCR provenance',
        () async {
      final ocrChunk = LearningDocumentChunk(
        chunkId: 'chk_ocr_p1',
        documentId: 'doc_scanned_202',
        index: 0,
        text:
            'Extract from historical archives regarding ancient trade routes.',
        startPage: 1,
        endPage: 1,
        provenance: TextProvenance.ocr,
        script: 'latin',
        tokenEstimate: 15,
      );

      final doc = LearningDocument(
        id: 'doc_scanned_202',
        fileName: 'scanned_archives.pdf',
        displayName: 'Historical Archives',
        totalPages: 1,
        sizeBytes: 5120,
        createdAt: DateTime.now(),
        chunks: [ocrChunk],
      );

      final blueprint = AssessmentBlueprint(
        documentId: 'doc_scanned_202',
        targetQuestions: 1,
        difficulty: QuizDifficulty.easy,
      );

      final session = await coordinator.generateSmartAssessment(
        document: doc,
        blueprint: blueprint,
        assessmentGenerator: fakeGenerator,
      );

      final loadedQuiz = await quizRepository.loadQuiz(session.quizId);
      expect(loadedQuiz, isNotNull);
      expect(loadedQuiz!.questions.length, 1);
      expect(loadedQuiz.questions.first.pageReference, 1);
    });

    test(
        '3. End-to-end: Bilingual Hindi-English document generates grounded assessment',
        () async {
      final hindiChunk = LearningDocumentChunk(
        chunkId: 'chk_hi_01',
        documentId: 'doc_bilingual_303',
        index: 0,
        text:
            'भारत का संविधान दुनिया का सबसे बड़ा लिखित संविधान है। The Constitution of India is the longest written constitution.',
        startPage: 1,
        endPage: 1,
        provenance: TextProvenance.mixed,
        script: 'bilingual',
        tokenEstimate: 25,
      );

      final doc = LearningDocument(
        id: 'doc_bilingual_303',
        fileName: 'bilingual_polity.pdf',
        displayName: 'Bilingual Polity',
        totalPages: 1,
        sizeBytes: 3000,
        createdAt: DateTime.now(),
        chunks: [hindiChunk],
        primaryLanguage: 'bilingual',
      );

      final blueprint = AssessmentBlueprint(
        documentId: 'doc_bilingual_303',
        targetQuestions: 1,
        language: QuizLanguage.bilingual,
        difficulty: QuizDifficulty.medium,
      );

      final session = await coordinator.generateSmartAssessment(
        document: doc,
        blueprint: blueprint,
        assessmentGenerator: fakeGenerator,
      );

      final loadedQuiz = await quizRepository.loadQuiz(session.quizId);
      expect(loadedQuiz, isNotNull);
      expect(loadedQuiz!.language, QuizLanguage.bilingual);
      expect(loadedQuiz.questions.length, 1);
    });

    test(
        '4. Graceful handling of Cancellation during smart assessment generation',
        () async {
      final chunk = LearningDocumentChunk(
        chunkId: 'chk_1',
        documentId: 'doc_cancel',
        index: 0,
        text: 'Some source text.',
        startPage: 1,
        endPage: 1,
        tokenEstimate: 5,
      );

      final doc = LearningDocument(
        id: 'doc_cancel',
        fileName: 'cancel.pdf',
        displayName: 'Cancel Test',
        totalPages: 1,
        sizeBytes: 1000,
        createdAt: DateTime.now(),
        chunks: [chunk],
      );

      final cancelToken = AssessmentCancellationToken()..cancel();
      final blueprint = AssessmentBlueprint(documentId: 'doc_cancel');

      try {
        await coordinator.generateSmartAssessment(
          document: doc,
          blueprint: blueprint,
          assessmentGenerator: fakeGenerator,
          cancellationToken: cancelToken,
        );
        fail('Expected ApplicationException on cancellation');
      } catch (e) {
        expect(e, isA<ApplicationException>());
      }

      expect(coordinator.state.hasError, isTrue);
    });

    test(
        '5. Rejects malformed / ungrounded AI output cleanly through ApplicationCoordinator',
        () async {
      final chunk = LearningDocumentChunk(
        chunkId: 'chk_valid',
        documentId: 'doc_fail',
        index: 0,
        text: 'Valid source passage.',
        startPage: 1,
        endPage: 1,
        tokenEstimate: 5,
      );

      final doc = LearningDocument(
        id: 'doc_fail',
        fileName: 'fail.pdf',
        displayName: 'Fail Test',
        totalPages: 1,
        sizeBytes: 1000,
        createdAt: DateTime.now(),
        chunks: [chunk],
      );

      final failGenerator = FakeAssessmentGenerator(
        customJson: '''
{
  "title": "Invalid Quiz",
  "questions": [
    {
      "question": "Ungrounded question",
      "type": "mcq",
      "options": ["Opt A", "Opt B"],
      "correctAnswers": [0],
      "sourceChunkId": "non_existent_chunk_id",
      "pageNumber": 1
    }
  ]
}
''',
      );

      final blueprint = AssessmentBlueprint(documentId: 'doc_fail');

      try {
        await coordinator.generateSmartAssessment(
          document: doc,
          blueprint: blueprint,
          assessmentGenerator: failGenerator,
        );
        fail('Expected ApplicationException on malformed AI output');
      } catch (e) {
        expect(e, isA<ApplicationException>());
      }

      expect(coordinator.state.hasError, isTrue);
    });
  });
}

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockQuizGenerationRepository implements QuizGenerationRepository {
  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<QuizGenerationResult> generateQuiz(
      QuizGenerationRequest request) async {
    final quiz = Quiz(
      id: 'quiz_mock',
      title: 'Mock Quiz',
      sourceDocumentId: request.documentId,
      questions: const [],
    );
    return QuizGenerationResult(
      quiz: quiz,
      statistics: GenerationStatistics(
        chunksProcessed: 1,
        questionsGenerated: 0,
        tokensUsed: 50,
        generationTime: Duration.zero,
      ),
      processingTime: Duration.zero,
    );
  }
}
