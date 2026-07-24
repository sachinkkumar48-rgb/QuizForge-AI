import 'package:test/test.dart';
import 'package:titan_core/titan_core.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_storage/titan_storage.dart';

class DummyStorageService implements StorageService {
  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> contains(StorageKey key) async => false;

  @override
  Future<T?> read<T>(StorageKey key) async => null;

  @override
  Future<StorageEntry<T>?> readEntry<T>(StorageKey key) async => null;

  @override
  Future<void> write<T>(StorageKey key, T value) async {}

  @override
  Future<void> delete(StorageKey key) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<List<StorageKey>> keys({String? namespace}) async => [];

  @override
  Future<void> close() async {}
}

void main() {
  group('TitanQuizBootstrap Dependency Injection and Lifecycle Tests', () {
    late TitanServiceLocator locator;
    late TitanQuizBootstrap bootstrap;

    setUp(() {
      locator = TitanServiceLocator.instance;
      locator.reset();
      bootstrap = TitanQuizBootstrap();
    });

    tearDown(() {
      locator.reset();
    });

    test(
        'validate throws TitanMissingDependencyException if StorageService is missing',
        () {
      expect(() => bootstrap.validate(),
          throwsA(isA<TitanMissingDependencyException>()));
    });

    test(
        'initialize registers QuizValidationService, QuizScoringService, QuizStatisticsService, and QuizRepository',
        () async {
      locator.registerSingleton<StorageService>(DummyStorageService());

      expect(bootstrap.isInitialized, isFalse);
      await bootstrap.initialize();
      expect(bootstrap.isInitialized, isTrue);

      expect(locator.isRegistered<QuizValidationService>(), isTrue);
      expect(locator.isRegistered<QuizScoringService>(), isTrue);
      expect(locator.isRegistered<QuizStatisticsService>(), isTrue);
      expect(locator.isRegistered<QuizRepository>(), isTrue);

      final repo = locator.get<QuizRepository>();
      expect(repo, isA<QuizRepositoryImpl>());
    });

    test('dispose unregisters registered Quiz domain services', () async {
      locator.registerSingleton<StorageService>(DummyStorageService());
      await bootstrap.initialize();

      await bootstrap.dispose();
      expect(bootstrap.isInitialized, isFalse);
      expect(locator.isRegistered<QuizRepository>(), isFalse);
      expect(locator.isRegistered<QuizValidationService>(), isFalse);
      expect(locator.isRegistered<QuizScoringService>(), isFalse);
      expect(locator.isRegistered<QuizStatisticsService>(), isFalse);
    });
  });
}
