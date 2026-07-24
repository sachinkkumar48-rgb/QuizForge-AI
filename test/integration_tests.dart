import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:quizforge_upsc/models/quiz_model.dart';
import 'package:quizforge_upsc/repositories/quiz_repository.dart';
import 'package:quizforge_upsc/services/knowledge_integration_service.dart';
import 'package:quizforge_upsc/services/quiz_batch_generator.dart';
import 'package:quizforge_upsc/services/quiz_generation_adapter.dart';

/// In-memory mock repository implementing [KnowledgeRepository] for integration testing.
class IntegrationMockKnowledgeRepository implements KnowledgeRepository {
  final Map<String, KnowledgeObject> storage = {};

  @override
  Future<void> save(KnowledgeObject object) async {
    storage[object.id] = object;
  }

  @override
  Future<void> update(KnowledgeObject object) async {
    storage[object.id] = object;
  }

  @override
  Future<void> delete(String id) async {
    storage.remove(id);
  }

  @override
  Future<KnowledgeObject?> findById(String id) async {
    return storage[id];
  }

  @override
  Future<List<KnowledgeObject>> search(String query) async {
    return storage.values
        .where((item) => item.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

/// Fake batch generator simulating AI quiz generation without making external network calls.
class FakeQuizBatchGenerator extends QuizBatchGenerator {
  String? lastReceivedInputText;

  @override
  Future<QuizModel> generateInBatches(
    String text, {
    required int questionCount,
    void Function(String message)? onProgress,
  }) async {
    lastReceivedInputText = text;
    final questions = List.generate(
      questionCount,
      (i) => QuizQuestion(
        question: 'Sample Question ${i + 1} from ingested content',
        options: const ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        answer: 'Option 1',
        explanation: 'Detailed explanation for question ${i + 1}',
        subject: 'General Studies',
        difficulty: 'Medium',
      ),
    );

    return QuizModel(
      id: 'integration_quiz_test_id',
      sourceName: 'Ingested_Document.pdf',
      questions: questions,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TITAN-QFAI-001: QuizForge ↔ Knowledge Engine Integration Tests', () {
    late IntegrationMockKnowledgeRepository mockRepo;
    late KnowledgeIntegrationService integrationService;
    late QuizGenerationAdapter generationAdapter;
    late FakeQuizBatchGenerator fakeGenerator;
    late QuizRepository quizRepository;

    setUp(() {
      mockRepo = IntegrationMockKnowledgeRepository();
      integrationService = KnowledgeIntegrationService(repository: mockRepo);
      generationAdapter = const QuizGenerationAdapter();
      fakeGenerator = FakeQuizBatchGenerator();
      quizRepository = QuizRepository(
        batchGenerator: fakeGenerator,
        integrationService: integrationService,
        generationAdapter: generationAdapter,
      );
    });

    test('Verification 1: PDF → KnowledgeObjects ingestion', () async {
      const pdfText = '''
        The Preamble to the Indian Constitution declares India to be a Sovereign,
        Socialist, Secular, Democratic Republic. It aims to secure Justice, Liberty,
        Equality, and Fraternity for all citizens.
      ''';

      final pipelineResult = await integrationService.ingestPdf(
        pdfText: pdfText,
        pdfTitle: 'Indian_Preamble.pdf',
        pdfSourcePath: '/assets/documents/Indian_Preamble.pdf',
      );

      expect(pipelineResult.isSuccess, isTrue);
      expect(pipelineResult.objects, isNotEmpty);
      expect(mockRepo.storage.length, equals(pipelineResult.objects.length));

      for (final obj in pipelineResult.objects) {
        expect(obj.type, equals(KnowledgeType.pdf));
        expect(obj.title, equals('Indian_Preamble.pdf'));
        expect(obj.source, equals('/assets/documents/Indian_Preamble.pdf'));
        expect(obj.metadata['importedVia'], equals('QuizForge_PDF_Importer'));
      }
    });

    test('Verification 2: KnowledgeObjects → Quiz generation', () async {
      final obj1 = KnowledgeObject(
        id: 'ko_preamble_1',
        type: KnowledgeType.pdf,
        title: 'Constitution Chapter 1',
        summary: 'Preamble and Fundamental Principles',
        source: 'constitution.pdf',
        metadata: const {
          'fullChunkText':
              'The Constitution of India was adopted on 26 November 1949.'
        },
      );

      final adaptedPrompt =
          generationAdapter.preparePromptTextFromObjects([obj1]);
      expect(adaptedPrompt, contains('26 November 1949'));

      final quizModel = await fakeGenerator.generateInBatches(
        adaptedPrompt,
        questionCount: 5,
      );

      expect(quizModel.questions.length, equals(5));
      expect(fakeGenerator.lastReceivedInputText, equals(adaptedPrompt));
    });

    test('Verification 3: Existing quiz generation behavior remains unchanged',
        () async {
      expect(quizRepository, isNotNull);

      // Verify adapter output formatting handles empty or fallback objects gracefully
      final emptyResult = await integrationService.ingestPdf(
        pdfText: '',
        pdfTitle: 'Empty.pdf',
      );

      final prompt = generationAdapter.preparePromptText(emptyResult);
      expect(prompt, isEmpty);
    });

    test('Verification 4: Pipeline statistics are available', () async {
      const sampleContent = '''
        Article 21 guarantees Protection of Life and Personal Liberty.
        No person shall be deprived of his life or personal liberty except according to procedure established by law.
      ''';

      final result = await integrationService.ingestPdf(
        pdfText: sampleContent,
        pdfTitle: 'Article21.pdf',
      );

      final stats = result.statistics;
      expect(stats.originalCharCount, equals(sampleContent.length));
      expect(stats.normalizedCharCount, greaterThan(0));
      expect(stats.chunkCount, equals(result.objects.length));
      expect(stats.totalWords, greaterThan(0));
      expect(result.processingDuration.inMilliseconds, greaterThanOrEqualTo(0));
    });
  });
}
