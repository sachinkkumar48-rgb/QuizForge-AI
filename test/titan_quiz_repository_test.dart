import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:quizforge_upsc/models/quiz_model.dart';
import 'package:quizforge_upsc/models/quiz_source.dart';
import 'package:quizforge_upsc/repositories/quiz_source_repository.dart';
import 'package:quizforge_upsc/repositories/titan_quiz_repository.dart';
import 'package:quizforge_upsc/services/knowledge_integration_service.dart';
import 'package:quizforge_upsc/services/quiz_batch_generator.dart';
import 'package:quizforge_upsc/services/quiz_generation_adapter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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

class FakeQuizSourceRepository implements QuizSourceRepository {
  final Map<String, QuizSource> storage = {};

  @override
  Future<void> saveSource(QuizSource source) async {
    storage[source.id] = source;
  }

  @override
  Future<List<QuizSource>> getSources() async => storage.values.toList();

  @override
  Future<void> updateSource(QuizSource source) async {
    storage[source.id] = source;
  }

  @override
  Future<void> deleteSource(String id) async {
    storage.remove(id);
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final s = storage[id];
    if (s != null) {
      storage[id] = s.copyWith(favorite: !s.favorite);
    }
  }
}

class TestQuizBatchGenerator extends QuizBatchGenerator {
  String? lastReceivedInputText;

  @override
  Future<QuizModel> generateInBatches(
    String text, {
    required int questionCount,
    void Function(String message)? onProgress,
  }) async {
    lastReceivedInputText = text;
    onProgress?.call("Generating batch 1 of 1");
    final questions = List.generate(
      questionCount,
      (i) => QuizQuestion(
        question: 'Titan Question ${i + 1}',
        options: const ['A', 'B', 'C', 'D'],
        answer: 'A',
        explanation: 'Explanation ${i + 1}',
        subject: 'General Studies',
        difficulty: 'Medium',
      ),
    );

    return QuizModel(
      id: 'titan_test_quiz_id',
      sourceName: 'test_doc.pdf',
      questions: questions,
    );
  }
}

Uint8List createSamplePdfBytes(String text) {
  final document = PdfDocument();
  final page = document.pages.add();
  page.graphics.drawString(
    text,
    PdfStandardFont(PdfFontFamily.helvetica, 12),
  );
  final List<int> bytes = document.saveSync();
  document.dispose();
  return Uint8List.fromList(bytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  group('TitanQuizRepository Unit Tests', () {
    late MockKnowledgeRepository mockKnowledgeRepo;
    late KnowledgeIntegrationService integrationService;
    late QuizGenerationAdapter generationAdapter;
    late TestQuizBatchGenerator fakeBatchGenerator;
    late FakeQuizSourceRepository fakeQuizSourceRepository;
    late TitanQuizRepositoryImpl titanQuizRepo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp();
      Hive.init(tempDir.path);

      mockKnowledgeRepo = MockKnowledgeRepository();
      integrationService =
          KnowledgeIntegrationService(repository: mockKnowledgeRepo);
      generationAdapter = const QuizGenerationAdapter();
      fakeBatchGenerator = TestQuizBatchGenerator();
      fakeQuizSourceRepository = FakeQuizSourceRepository();
      titanQuizRepo = TitanQuizRepositoryImpl(
        batchGenerator: fakeBatchGenerator,
        integrationService: integrationService,
        generationAdapter: generationAdapter,
        quizSourceRepository: fakeQuizSourceRepository,
      );
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    });

    test(
        'Verification: TitanQuizRepositoryImpl implements TitanQuizRepository contract',
        () {
      expect(titanQuizRepo, isA<TitanQuizRepository>());
    });

    test(
        'Verification: generateQuiz triggers onProgress callbacks and returns QuizModel',
        () async {
      final pdfBytes =
          createSamplePdfBytes("Constitution of India Preamble testing text.");
      final mockPdf = PlatformFile(
        name: 'test_doc.pdf',
        size: pdfBytes.length,
        path: '/dummy/test_doc.pdf',
        bytes: pdfBytes,
      );

      final progressLog = <String>[];
      final quizModel = await titanQuizRepo.generateQuiz(
        mockPdf,
        questionCount: 5,
        onProgress: (msg) {
          progressLog.add(msg);
        },
      );

      expect(quizModel, isNotNull);
      expect(quizModel.questions.length, equals(5));
      expect(progressLog, isNotEmpty);
      expect(
          progressLog.any((msg) =>
              msg.contains("Generating batch") || msg.contains("Ingesting")),
          isTrue);
    });

    test('Verification: Empty PDF text throws Exception', () async {
      final emptyPdf = PlatformFile(
        name: 'empty.pdf',
        size: 0,
        path: '/dummy/empty.pdf',
        bytes: Uint8List(0),
      );

      expect(
        () => titanQuizRepo.generateQuiz(emptyPdf),
        throwsA(isA<Exception>()),
      );
    });
  });
}
