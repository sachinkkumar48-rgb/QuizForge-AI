import 'package:test/test.dart';
import 'package:titan_ai/titan_ai.dart';
import 'package:titan_core/titan_core.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';

class DummyAIService implements AIService {
  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> close() async {}

  @override
  Future<AIResponse<T>> generate<T>(AIRequest request) async =>
      throw UnimplementedError();

  @override
  List<AIModel> availableModels() => const [];

  @override
  AIModel defaultModel() => throw UnimplementedError();

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
          {ChunkOptions? options}) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummyQuizRepository implements QuizRepository {
  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TitanQuizAIBootstrap Dependency Injection Tests', () {
    late TitanServiceLocator locator;
    late TitanQuizAIBootstrap bootstrap;

    setUp(() {
      locator = TitanServiceLocator.instance;
      locator.reset();
      bootstrap = TitanQuizAIBootstrap();
    });

    tearDown(() {
      locator.reset();
    });

    test(
        'validate throws TitanMissingDependencyException when prerequisite services are missing',
        () {
      expect(() => bootstrap.validate(),
          throwsA(isA<TitanMissingDependencyException>()));
    });

    test('initialize registers all AI Quiz Generation pipeline services',
        () async {
      locator.registerSingleton<AIService>(DummyAIService());
      locator.registerSingleton<PdfRepository>(DummyPdfRepository());
      locator.registerSingleton<QuizRepository>(DummyQuizRepository());

      expect(bootstrap.isInitialized, isFalse);
      await bootstrap.initialize();
      expect(bootstrap.isInitialized, isTrue);

      expect(locator.isRegistered<QuizPromptBuilder>(), isTrue);
      expect(locator.isRegistered<QuizJsonValidator>(), isTrue);
      expect(locator.isRegistered<QuizJsonParser>(), isTrue);
      expect(locator.isRegistered<AIQuizGenerationService>(), isTrue);
      expect(locator.isRegistered<QuizGenerationRepository>(), isTrue);

      final genRepo = locator.get<QuizGenerationRepository>();
      expect(genRepo, isA<QuizGenerationRepositoryImpl>());

      await bootstrap.dispose();
      expect(bootstrap.isInitialized, isFalse);
      expect(locator.isRegistered<QuizGenerationRepository>(), isFalse);
    });
  });
}
