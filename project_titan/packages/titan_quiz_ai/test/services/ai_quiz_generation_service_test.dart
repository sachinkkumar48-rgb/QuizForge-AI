import 'package:test/test.dart';
import 'package:titan_ai/titan_ai.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';

class MockPdfRepository implements PdfRepository {
  final List<PdfChunk> chunksToReturn;

  MockPdfRepository({this.chunksToReturn = const []});

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<List<PdfChunk>> createChunks(String documentId,
      {ChunkOptions? options}) async {
    return chunksToReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAIService implements AIService {
  final String responseText;

  MockAIService({required this.responseText});

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> close() async {}

  @override
  Future<AIResponse<T>> generate<T>(AIRequest request) async {
    return AIResponse<T>(
      text: responseText,
      usage: const AITokenUsage(
          promptTokens: 120, completionTokens: 80, totalTokens: 200),
      model: 'gemini-1.5-flash',
      provider: 'google',
      finishReason: 'stop',
    );
  }

  @override
  List<AIModel> availableModels() => const [];

  @override
  AIModel defaultModel() => const AIModel(
        id: 'gemini-1.5-flash',
        displayName: 'Gemini Flash',
        contextWindow: 1000000,
        maxOutputTokens: 8192,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AIQuizGenerationService Integration Flow Tests', () {
    test(
        'generateQuiz successfully orchestrates PDF chunks, LLM completion, validation, and parsing',
        () async {
      final sampleChunks = [
        PdfChunk(
          chunkId: 'chk_1',
          documentId: 'doc_polity_32',
          index: 0,
          text:
              'Article 32 provides the right to move the Supreme Court for enforcement of fundamental rights.',
          startPage: 1,
          endPage: 1,
          tokenEstimate: 50,
        ),
      ];

      const validAiResponseText = '''
{
  "title": "Article 32 UPSC Mock",
  "description": "Quiz on Constitutional Remedies",
  "questions": [
    {
      "question": "Which article is known as the heart and soul of the Constitution?",
      "options": ["Article 32", "Article 21", "Article 19", "Article 14"],
      "correctAnswer": 0,
      "explanation": "Dr. B.R. Ambedkar called Article 32 the heart and soul of the Constitution.",
      "topic": "Fundamental Rights",
      "difficulty": "medium"
    }
  ]
}
''';

      final mockPdfRepo = MockPdfRepository(chunksToReturn: sampleChunks);
      final mockAI = MockAIService(responseText: validAiResponseText);

      final service = AIQuizGenerationService(
        pdfRepository: mockPdfRepo,
        aiService: mockAI,
      );

      final request = QuizGenerationRequest(
        documentId: 'doc_polity_32',
        category: QuizCategory.upsc,
        difficulty: QuizDifficulty.medium,
      );

      final result = await service.generateQuiz(request);

      expect(result.quiz.title, equals('Article 32 UPSC Mock'));
      expect(result.quiz.questions.length, equals(1));
      expect(result.quiz.questions.first.question, contains('heart and soul'));
      expect(result.statistics.chunksProcessed, equals(1));
      expect(result.statistics.questionsGenerated, equals(1));
      expect(result.statistics.tokensUsed, equals(200));
    });

    test('Throws exception when no PDF chunks exist for document', () async {
      final mockPdfRepo = MockPdfRepository(chunksToReturn: const []);
      final mockAI = MockAIService(responseText: '{}');

      final service = AIQuizGenerationService(
        pdfRepository: mockPdfRepo,
        aiService: mockAI,
      );

      final request = QuizGenerationRequest(documentId: 'doc_missing');

      expect(
        () => service.generateQuiz(request),
        throwsA(isA<JsonParsingException>()),
      );
    });
  });
}
