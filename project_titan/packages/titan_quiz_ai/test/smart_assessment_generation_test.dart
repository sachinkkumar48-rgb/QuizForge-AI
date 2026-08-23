import 'dart:async';
import 'package:test/test.dart';
import 'package:titan_ai/titan_ai.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';

void main() {
  group('Phase 8B: Smart Assessment Domain & Blueprint Tests', () {
    test('1. AssessmentQuestionType parses codes correctly', () {
      expect(AssessmentQuestionType.mcq.typeCode, 'mcq');
      expect(AssessmentQuestionType.trueFalse.typeCode, 'true_false');
      expect(AssessmentQuestionType.multipleSelect.typeCode, 'multiple_select');

      expect(
          AssessmentQuestionType.fromCode('mcq'), AssessmentQuestionType.mcq);
      expect(AssessmentQuestionType.fromCode('true_false'),
          AssessmentQuestionType.trueFalse);
      expect(AssessmentQuestionType.fromCode('multiple_select'),
          AssessmentQuestionType.multipleSelect);
      expect(AssessmentQuestionType.fromCode('statement_based'),
          AssessmentQuestionType.statementBased);
    });

    test(
        '2. AssessmentBlueprint initializes with default values and supports copyWith',
        () {
      final blueprint = AssessmentBlueprint(
        documentId: 'doc_polity_101',
        targetQuestions: 10,
        difficulty: QuizDifficulty.hard,
        language: QuizLanguage.hindi,
        category: QuizCategory.upsc,
        topicHint: 'Fundamental Rights & Writs',
      );

      expect(blueprint.documentId, 'doc_polity_101');
      expect(blueprint.targetQuestions, 10);
      expect(blueprint.difficulty, QuizDifficulty.hard);
      expect(blueprint.language, QuizLanguage.hindi);
      expect(blueprint.explanationRequired, isTrue);

      final modified = blueprint.copyWith(targetQuestions: 15);
      expect(modified.targetQuestions, 15);
      expect(modified.documentId, 'doc_polity_101');
    });

    test(
        '3. AssessmentSource creates from LearningDocumentChunk preserving provenance and script',
        () {
      final chunk = LearningDocumentChunk(
        chunkId: 'chk_p1_0',
        documentId: 'doc_eco',
        index: 0,
        text: 'Monetary policy is controlled by the Reserve Bank of India.',
        startPage: 1,
        endPage: 1,
        provenance: TextProvenance.nativePdf,
        script: 'latin',
        tokenEstimate: 12,
        sectionHeadings: const ['Macroeconomics', 'Monetary Policy'],
      );

      final source = AssessmentSource.fromLearningChunk(chunk);
      expect(source.chunkId, 'chk_p1_0');
      expect(source.documentId, 'doc_eco');
      expect(source.pageNumber, 1);
      expect(source.provenance, TextProvenance.nativePdf);
      expect(source.sectionHeading, 'Macroeconomics');
      expect(source.tokenEstimate, 12);
    });

    test(
        '4. GeneratedQuestion converts cleanly to canonical QuizQuestion entity',
        () {
      const metadata = QuestionGenerationMetadata(
        sourceDocumentId: 'doc_polity',
        sourceChunkId: 'chk_1',
        pageNumber: 3,
        questionType: AssessmentQuestionType.mcq,
        confidenceScore: 0.98,
        isGroundingVerified: true,
      );

      final genQuestion = GeneratedQuestion(
        id: 'gq_101',
        questionText:
            'Which Article of the Constitution guarantees the Right to Equality?',
        options: ['Article 14', 'Article 19', 'Article 21', 'Article 32'],
        correctAnswers: const [0],
        explanation:
            'Article 14 guarantees equality before law and equal protection of laws.',
        difficulty: QuizDifficulty.medium,
        topic: 'Fundamental Rights',
        metadata: metadata,
      );

      final quizQuestion = genQuestion.toQuizQuestion();
      expect(quizQuestion.id, 'gq_101');
      expect(quizQuestion.question, contains('Right to Equality'));
      expect(quizQuestion.options.length, 4);
      expect(quizQuestion.correctAnswerIndex, 0);
      expect(quizQuestion.pageReference, 3);
      expect(quizQuestion.explanation, contains('Article 14'));
    });

    test(
        '5. AssessmentCancellationToken triggers listeners and throws on cancellation',
        () {
      final token = AssessmentCancellationToken();
      expect(token.isCancelled, isFalse);

      var listenerFired = false;
      token.onCancel(() => listenerFired = true);

      token.cancel();
      expect(token.isCancelled, isTrue);
      expect(listenerFired, isTrue);

      expect(() => token.throwIfCancelled(),
          throwsA(isA<AssessmentCancellationException>()));
    });
  });

  group('Phase 8B: Assessment Source Bridge & Chunk Selection Tests', () {
    test(
        '6. AssessmentSourceBridge converts LearningDocument into ordered AssessmentSources',
        () {
      const bridge = AssessmentSourceBridge();
      final chunk1 = LearningDocumentChunk(
        chunkId: 'chk_1',
        documentId: 'doc_test',
        index: 0,
        text: 'Chunk 1 text content.',
        startPage: 1,
        endPage: 1,
        tokenEstimate: 10,
      );
      final chunk2 = LearningDocumentChunk(
        chunkId: 'chk_2',
        documentId: 'doc_test',
        index: 1,
        text: 'Chunk 2 text content.',
        startPage: 2,
        endPage: 2,
        tokenEstimate: 10,
      );

      final doc = LearningDocument(
        id: 'doc_test',
        fileName: 'test.pdf',
        displayName: 'Test',
        totalPages: 2,
        sizeBytes: 1024,
        createdAt: DateTime.now(),
        chunks: [chunk1, chunk2],
      );

      final sources = bridge.fromLearningDocument(document: doc);
      expect(sources.length, 2);
      expect(sources[0].chunkId, 'chk_1');
      expect(sources[1].chunkId, 'chk_2');
    });

    test(
        '7. AssessmentChunkSelector partitions sources into batches respecting maxTokensPerBatch',
        () {
      const selector = AssessmentChunkSelector();
      final blueprint = AssessmentBlueprint(
        documentId: 'doc_large',
        maxTokensPerBatch: 25,
      );

      const src1 = AssessmentSource(
        documentId: 'doc_large',
        chunkId: 'chk_1',
        pageNumber: 1,
        text: 'Passage 1 with roughly 15 tokens.',
        tokenEstimate: 15,
      );
      const src2 = AssessmentSource(
        documentId: 'doc_large',
        chunkId: 'chk_2',
        pageNumber: 2,
        text: 'Passage 2 with roughly 15 tokens.',
        tokenEstimate: 15,
      );
      const src3 = AssessmentSource(
        documentId: 'doc_large',
        chunkId: 'chk_3',
        pageNumber: 3,
        text: 'Passage 3 with roughly 10 tokens.',
        tokenEstimate: 10,
      );

      final batches = selector.createBatches(
        sources: [src1, src2, src3],
        blueprint: blueprint,
      );

      expect(batches.length, 2);
      expect(batches[0].length, 1); // src1 (15 tokens)
      expect(batches[1].length, 2); // src2 (15) + src3 (10) = 25 tokens
    });
  });

  group('Phase 8B: Prompt Engineering, Parser & Validator Tests', () {
    test('8. AssessmentPromptBuilder formats grounded system and user prompts',
        () {
      const promptBuilder = AssessmentPromptBuilder();
      final blueprint = AssessmentBlueprint(
        documentId: 'doc_env',
        category: QuizCategory.upsc,
        difficulty: QuizDifficulty.medium,
        language: QuizLanguage.english,
        targetQuestions: 3,
        topicHint: 'Biodiversity Hotspots',
      );

      const src = AssessmentSource(
        documentId: 'doc_env',
        chunkId: 'chk_env_01',
        pageNumber: 5,
        text:
            'The Western Ghats and Eastern Himalayas are major biodiversity hotspots in India.',
        tokenEstimate: 20,
      );

      final systemPrompt = promptBuilder.buildSystemPrompt(
        allowedTypes: blueprint.allowedQuestionTypes,
      );
      expect(systemPrompt, contains('STRICT SOURCE GROUNDING'));
      expect(systemPrompt, contains('sourceChunkId'));

      final userPrompt = promptBuilder.buildUserPrompt(
        sources: [src],
        blueprint: blueprint,
      );
      expect(userPrompt, contains('=== SOURCE DOCUMENT PASSAGES ==='));
      expect(userPrompt, contains('CHUNK_ID: chk_env_01'));
      expect(userPrompt, contains('Western Ghats'));
    });

    test(
        '9. AssessmentJsonParser parses structured JSON with MCQ and True/False types',
        () {
      const parser = AssessmentJsonParser();
      final blueprint = AssessmentBlueprint(documentId: 'doc_polity');
      final src = const AssessmentSource(
        documentId: 'doc_polity',
        chunkId: 'chk_01',
        pageNumber: 1,
        text: 'Sample text.',
      );
      final request = AssessmentGenerationRequest(
        blueprint: blueprint,
        sources: [src],
      );

      const jsonStr = '''
```json
{
  "title": "Indian Constitution Quiz",
  "description": "Fundamental Rights Overview",
  "questions": [
    {
      "question": "What is the role of the Supreme Court under Article 32?",
      "type": "mcq",
      "options": ["Issue writs for enforcement of rights", "Pass ordinary bills", "Appoint governors", "Declare financial emergencies"],
      "correctAnswers": [0],
      "explanation": "Article 32 empowers the Supreme Court to issue writs.",
      "sourceChunkId": "chk_01",
      "pageNumber": 1,
      "topic": "Constitutional Remedies",
      "difficulty": "medium"
    },
    {
      "question": "Article 21 protects right to life.",
      "type": "true_false",
      "options": ["True", "False"],
      "correctAnswers": [0],
      "explanation": "Article 21 explicitly guarantees right to life and personal liberty.",
      "sourceChunkId": "chk_01",
      "pageNumber": 1
    }
  ]
}
```
''';

      final jsonMap = parser.extractJsonMap(jsonStr);
      expect(jsonMap['title'], 'Indian Constitution Quiz');

      final questions = parser.parseQuestions(map: jsonMap, request: request);
      expect(questions.length, 2);
      expect(questions[0].metadata.questionType, AssessmentQuestionType.mcq);
      expect(
          questions[1].metadata.questionType, AssessmentQuestionType.trueFalse);
      expect(questions[0].metadata.sourceChunkId, 'chk_01');
    });

    test(
        '10. AssessmentValidator validates grounding and rejects ungrounded or malformed questions',
        () {
      const validator = AssessmentValidator();
      final blueprint =
          AssessmentBlueprint(documentId: 'doc_1', explanationRequired: true);
      final src = const AssessmentSource(
        documentId: 'doc_1',
        chunkId: 'valid_chunk_1',
        pageNumber: 1,
        text: 'Valid text.',
      );
      final request =
          AssessmentGenerationRequest(blueprint: blueprint, sources: [src]);

      // Valid question
      final validQ = GeneratedQuestion(
        id: 'q1',
        questionText: 'What is photosynthesis?',
        options: const ['Process by plants', 'Animal digestion'],
        correctAnswers: const [0],
        explanation: 'Plants produce food via photosynthesis.',
        metadata: const QuestionGenerationMetadata(
          sourceDocumentId: 'doc_1',
          sourceChunkId: 'valid_chunk_1',
          pageNumber: 1,
        ),
      );

      final validErrors = validator.validateGeneratedQuestions(
        questions: [validQ],
        request: request,
      );
      expect(validErrors, isEmpty);

      // Ungrounded question (invalid chunk ID)
      final ungroundedQ = GeneratedQuestion(
        id: 'q2',
        questionText: 'What is cellular respiration?',
        options: const ['Option 1', 'Option 2'],
        correctAnswers: const [0],
        explanation: 'Explanation text.',
        metadata: const QuestionGenerationMetadata(
          sourceDocumentId: 'doc_1',
          sourceChunkId: 'hallucinated_chunk_99',
          pageNumber: 1,
        ),
      );

      final groundErrors = validator.validateGeneratedQuestions(
        questions: [ungroundedQ],
        request: request,
      );
      expect(groundErrors.isNotEmpty, isTrue);
      expect(groundErrors.first, contains('does not exist in request sources'));
    });

    test(
        '11. QuestionDeduplicator eliminates duplicate and near-identical questions',
        () {
      const deduplicator = QuestionDeduplicator();
      const metadata = QuestionGenerationMetadata(
        sourceDocumentId: 'doc_1',
        sourceChunkId: 'chunk_1',
        pageNumber: 1,
      );

      final q1 = GeneratedQuestion(
        id: 'q1',
        questionText: 'What is the capital of India?',
        options: const ['New Delhi', 'Mumbai'],
        correctAnswers: const [0],
        metadata: metadata,
      );

      final q2Duplicate = GeneratedQuestion(
        id: 'q2',
        questionText:
            'What is the capital of India??', // Near identical punctuation
        options: const ['New Delhi', 'Mumbai'],
        correctAnswers: const [0],
        metadata: metadata,
      );

      final q3Unique = GeneratedQuestion(
        id: 'q3',
        questionText: 'What is the official currency of India?',
        options: const ['Rupee', 'Dollar'],
        correctAnswers: const [0],
        metadata: metadata,
      );

      final deduplicated =
          deduplicator.deduplicate([q1, q2Duplicate, q3Unique]);
      expect(deduplicated.length, 2);
      expect(deduplicated[0].id, 'q1');
      expect(deduplicated[1].id, 'q3');
    });
  });

  group('Phase 8B: End-to-End Smart Assessment Pipeline & Generator Tests', () {
    test(
        '12. DefaultAssessmentGenerator successfully executes end-to-end generation with AIService',
        () async {
      final mockAi = _MockAIService(
        responseJson: '''
{
  "title": "Indian Polity & Governance",
  "description": "Assessment generated from Document Intelligence",
  "questions": [
    {
      "question": "Which body functions as the highest judicial court of appeal in India?",
      "type": "mcq",
      "options": ["Supreme Court", "High Court", "District Court", "Tribunal"],
      "correctAnswers": [0],
      "explanation": "The Supreme Court of India is the highest court of appeal.",
      "sourceChunkId": "chunk_polity_01",
      "pageNumber": 1,
      "topic": "Judiciary",
      "difficulty": "medium"
    }
  ]
}
''',
      );

      final generator = DefaultAssessmentGenerator(aiService: mockAi);
      final blueprint = AssessmentBlueprint(
        documentId: 'doc_polity',
        targetQuestions: 1,
      );
      final src = const AssessmentSource(
        documentId: 'doc_polity',
        chunkId: 'chunk_polity_01',
        pageNumber: 1,
        text:
            'The Supreme Court is the apex judicial body and highest court of appeal.',
        tokenEstimate: 20,
      );

      final request = AssessmentGenerationRequest(
        blueprint: blueprint,
        sources: [src],
      );

      final result = await generator.generateAssessment(request);

      expect(result.quiz, isNotNull);
      expect(result.quiz.title, 'Indian Polity & Governance');
      expect(result.quiz.questions.length, 1);
      expect(result.quiz.questions.first.question,
          contains('highest judicial court'));
      expect(result.statistics.chunksProcessed, 1);
      expect(result.generatedQuestions.length, 1);
    });

    test(
        '13. FakeAssessmentGenerator handles simulated errors, timeouts, and cancellation cleanly',
        () async {
      // 1. Success case
      final fakeSuccess = FakeAssessmentGenerator();
      final blueprint =
          AssessmentBlueprint(documentId: 'doc_fake', targetQuestions: 2);
      final src = const AssessmentSource(
        documentId: 'doc_fake',
        chunkId: 'chk_1',
        pageNumber: 1,
        text: 'Sample text.',
      );
      final request =
          AssessmentGenerationRequest(blueprint: blueprint, sources: [src]);

      final res = await fakeSuccess.generateAssessment(request);
      expect(res.quiz.questions.length, 2);

      // 2. Failure case
      final fakeFailure = FakeAssessmentGenerator(shouldFail: true);
      expect(
        () => fakeFailure.generateAssessment(request),
        throwsA(isA<QuizGenerationException>()),
      );

      // 3. Timeout case
      final fakeTimeout = FakeAssessmentGenerator(shouldTimeout: true);
      expect(
        () => fakeTimeout.generateAssessment(request),
        throwsA(isA<TimeoutException>()),
      );

      // 4. Cancellation case
      final cancelToken = AssessmentCancellationToken()..cancel();
      final cancelRequest = AssessmentGenerationRequest(
        blueprint: blueprint,
        sources: [src],
        cancellationToken: cancelToken,
      );
      expect(
        () => fakeSuccess.generateAssessment(cancelRequest),
        throwsA(isA<AssessmentCancellationException>()),
      );
    });
  });
}

class _MockAIService implements AIService {
  final String responseJson;

  _MockAIService({required this.responseJson});

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> close() async {}

  @override
  Future<AIResponse<T>> generate<T>(AIRequest request) async {
    return AIResponse<T>(
      text: responseJson,
      usage: const AITokenUsage(
          promptTokens: 50, completionTokens: 50, totalTokens: 100),
      model: 'mock-gemini',
      provider: 'google',
      finishReason: 'stop',
    );
  }

  @override
  List<AIModel> availableModels() => const [];

  @override
  AIModel defaultModel() => const AIModel(
        id: 'mock-gemini',
        displayName: 'Mock Gemini',
        contextWindow: 4096,
        maxOutputTokens: 1024,
      );
}
