import 'package:test/test.dart';
import 'package:titan_core/titan_core.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';

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
  group('TitanQuizSessionBootstrap DI Tests', () {
    late TitanServiceLocator locator;
    late TitanQuizSessionBootstrap bootstrap;

    setUp(() {
      locator = TitanServiceLocator.instance;
      locator.reset();
      bootstrap = TitanQuizSessionBootstrap();
    });

    tearDown(() {
      locator.reset();
    });

    test(
        'validate throws TitanMissingDependencyException when QuizRepository missing',
        () {
      expect(() => bootstrap.validate(),
          throwsA(isA<TitanMissingDependencyException>()));
    });

    test('initialize registers all Quiz Session services and repository',
        () async {
      locator.registerSingleton<QuizRepository>(DummyQuizRepository());

      expect(bootstrap.isInitialized, isFalse);
      await bootstrap.initialize();
      expect(bootstrap.isInitialized, isTrue);

      expect(locator.isRegistered<QuizTimerService>(), isTrue);
      expect(locator.isRegistered<QuizProgressService>(), isTrue);
      expect(locator.isRegistered<QuizSessionValidator>(), isTrue);
      expect(locator.isRegistered<QuizSessionService>(), isTrue);
      expect(locator.isRegistered<QuizSessionRepository>(), isTrue);

      final repo = locator.get<QuizSessionRepository>();
      expect(repo.isInitialized, isTrue);

      await bootstrap.dispose();
      expect(bootstrap.isInitialized, isFalse);
      expect(locator.isRegistered<QuizSessionRepository>(), isFalse);
    });
  });
}
