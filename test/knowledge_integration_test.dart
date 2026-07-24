import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:quizforge_upsc/models/quiz_model.dart';
import 'package:quizforge_upsc/repositories/quiz_repository.dart';
import 'package:quizforge_upsc/services/knowledge_integration_service.dart';
import 'package:quizforge_upsc/services/quiz_batch_generator.dart';
import 'package:quizforge_upsc/services/quiz_generation_adapter.dart';

class MockKnowledgeRepository implements KnowledgeRepository {
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

class DummyBatchGenerator extends QuizBatchGenerator {
  @override
  Future<QuizModel> generateInBatches(
    String text, {
    required int questionCount,
    void Function(String message)? onProgress,
  }) async {
    final questions = List.generate(
      questionCount,
      (i) => QuizQuestion(
        question: 'Question ${i + 1} generated from Knowledge Engine content',
        options: const ['Option A', 'Option B', 'Option C', 'Option D'],
        answer: 'Option A',
        explanation: 'Explanation for question ${i + 1}',
        subject: 'Polity',
        difficulty: 'Medium',
      ),
    );

    return QuizModel(
      id: 'quiz_integration_test',
      sourceName: 'Sample.pdf',
      questions: questions,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuizForge ↔ Knowledge Engine Integration Tests (TITAN-QFAI-001)', () {
    late MockKnowledgeRepository mockRepo;
    late KnowledgeIntegrationService integrationService;
    late QuizGenerationAdapter generationAdapter;

    setUp(() {
      mockRepo = MockKnowledgeRepository();
      integrationService = KnowledgeIntegrationService(
        repository: mockRepo,
      );
      generationAdapter = const QuizGenerationAdapter();
    });

    test(
        'KnowledgeIntegrationService ingests raw PDF text into KnowledgeObjects',
        () async {
      const pdfText = '''
        Indian Constitution - Article 14
        
        The State shall not deny to any person equality before the law or the equal protection of the laws.
      ''';

      final result = await integrationService.ingestPdf(
        pdfText: pdfText,
        pdfTitle: 'Constitution_Article14.pdf',
        pdfSourcePath: '/storage/pdfs/Article14.pdf',
      );

      expect(result.isSuccess, isTrue);
      expect(result.objects.isNotEmpty, isTrue);
      expect(mockRepo.storage.length, equals(result.objects.length));

      final firstObj = result.objects.first;
      expect(firstObj.type, equals(KnowledgeType.pdf));
      expect(firstObj.title, equals('Constitution_Article14.pdf'));
      expect(firstObj.source, equals('/storage/pdfs/Article14.pdf'));
    });

    test('QuizGenerationAdapter transforms KnowledgeObjects into prompt text',
        () async {
      final obj1 = KnowledgeObject(
        id: 'ko_1',
        type: KnowledgeType.pdf,
        title: 'Polity Part 1',
        summary: 'Preamble and Fundamental Duties',
        source: 'polity.pdf',
        metadata: const {
          'fullChunkText':
              'Preamble values of Liberty, Equality, and Fraternity.'
        },
      );
      final obj2 = KnowledgeObject(
        id: 'ko_2',
        type: KnowledgeType.pdf,
        title: 'Polity Part 2',
        summary: 'Directive Principles',
        source: 'polity.pdf',
        metadata: const {'fullChunkText': 'DPSP contained in Part IV.'},
      );

      final adaptedText =
          generationAdapter.preparePromptTextFromObjects([obj1, obj2]);

      expect(adaptedText,
          contains('Preamble values of Liberty, Equality, and Fraternity.'));
      expect(adaptedText, contains('DPSP contained in Part IV.'));
    });

    test(
        'QuizRepository end-to-end flow ingests PDF to Knowledge Engine & generates Quiz',
        () async {
      final dummyGenerator = DummyBatchGenerator();
      final repository = QuizRepository(
        batchGenerator: dummyGenerator,
        integrationService: integrationService,
        generationAdapter: generationAdapter,
      );

      final pdfBytes = Uint8List.fromList('Dummy PDF Bytes'.codeUnits);
      final platformFile = PlatformFile(
        name: 'Sample_Integration_Test.pdf',
        size: pdfBytes.length,
        bytes: pdfBytes,
        path: '/tmp/Sample_Integration_Test.pdf',
      );

      const sampleText =
          'Fundamental Rights are essential for individual dignity.';
      final pipelineResult = await integrationService.ingestPdf(
        pdfText: sampleText,
        pdfTitle: platformFile.name,
      );

      final promptText = generationAdapter.preparePromptText(pipelineResult);
      final quizModel = await dummyGenerator.generateInBatches(
        promptText,
        questionCount: 5,
      );

      expect(repository, isNotNull);
      expect(quizModel.questions.length, equals(5));
      expect(mockRepo.storage.isNotEmpty, isTrue);
      expect(promptText, contains('Fundamental Rights'));
    });
  });
}
