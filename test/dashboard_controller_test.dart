import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/controllers/dashboard_controller.dart';
import 'package:quizforge_upsc/core/di/service_locator_init.dart';
import 'package:quizforge_upsc/models/quiz_attempt.dart';
import 'package:quizforge_upsc/models/quiz_session.dart';
import 'package:quizforge_upsc/models/quiz_source.dart';
import 'package:quizforge_upsc/repositories/quiz_history_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_session_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_source_repository.dart';
import 'package:titan_core/titan_core.dart';

class MockSourceRepo implements QuizSourceRepository {
  @override
  Future<List<QuizSource>> getSources() async => [];
  @override
  Future<void> saveSource(QuizSource source) async {}
  @override
  Future<void> updateSource(QuizSource source) async {}
  @override
  Future<void> deleteSource(String id) async {}
  @override
  Future<void> toggleFavorite(String id) async {}
}

class MockHistoryRepo implements QuizHistoryRepository {
  @override
  Future<List<QuizAttempt>> getAttempts() async => [];
  @override
  Future<void> saveAttempt(QuizAttempt attempt) async {}
  @override
  Future<void> clearHistory() async {}
  @override
  Future<void> deleteAttempt(String id) async {}
}

class MockSessionRepo implements QuizSessionRepository {
  @override
  Future<bool> hasActiveSession() async => false;
  @override
  Future<QuizSession?> loadSession() async => null;
  @override
  Future<void> saveSession(QuizSession session) async {}
  @override
  Future<void> deleteSession() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DashboardController Unit Tests', () {
    setUp(() {
      QuizSourceRepository.instance = MockSourceRepo();
      QuizHistoryRepository.instance = MockHistoryRepo();
      QuizSessionRepository.instance = MockSessionRepo();
    });

    tearDown(() {
      TitanServiceLocator.instance.reset();
    });

    test(
        'Verification: DashboardController initializes and loads ready state with statistics',
        () async {
      final controller = DashboardController(
        sourceRepository: MockSourceRepo(),
        historyRepository: MockHistoryRepo(),
        sessionRepository: MockSessionRepo(),
      );

      // Wait for async loadDashboardData completion
      await Future.delayed(Duration.zero);

      expect(controller.state.isReady, isTrue);
      expect(controller.state.stats.studyStreakDays, greaterThan(0));
      expect(controller.state.recentActivities, isNotEmpty);
    });

    test('Verification: DashboardController resolves via DI service locator',
        () {
      setupServiceLocator();
      final controller = locate<DashboardController>();

      expect(controller, isNotNull);
    });

    test('Verification: refresh reloads dashboard metrics cleanly', () async {
      final controller = DashboardController(
        sourceRepository: MockSourceRepo(),
        historyRepository: MockHistoryRepo(),
        sessionRepository: MockSessionRepo(),
      );

      await controller.refresh();

      expect(controller.state.isReady, isTrue);
      expect(controller.state.userGreeting, contains("Aspirant"));
    });
  });
}
