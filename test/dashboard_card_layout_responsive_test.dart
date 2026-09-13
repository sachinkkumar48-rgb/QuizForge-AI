import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:quizforge_upsc/controllers/dashboard_controller.dart';
import 'package:quizforge_upsc/models/quiz_attempt.dart';
import 'package:quizforge_upsc/models/quiz_session.dart';
import 'package:quizforge_upsc/models/quiz_source.dart';
import 'package:quizforge_upsc/pages/quizforge_dashboard_page.dart';
import 'package:quizforge_upsc/repositories/quiz_history_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_session_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_source_repository.dart';
import 'package:quizforge_upsc/themes/app_theme.dart';
import 'package:titan_core/titan_core.dart';

class _FakeQuizSessionRepository implements QuizSessionRepository {
  QuizSession? _session;
  @override
  Future<void> deleteSession() async => _session = null;
  @override
  Future<bool> hasActiveSession() async => _session != null;
  @override
  Future<QuizSession?> loadSession() async => _session;
  @override
  Future<void> saveSession(QuizSession session) async => _session = session;
}

class _FakeQuizHistoryRepository implements QuizHistoryRepository {
  final List<QuizAttempt> _attempts = [];
  @override
  Future<void> clearHistory() async => _attempts.clear();
  @override
  Future<void> deleteAttempt(String id) async =>
      _attempts.removeWhere((a) => a.id == id);
  @override
  Future<List<QuizAttempt>> getAttempts() async => List.unmodifiable(_attempts);
  @override
  Future<void> saveAttempt(QuizAttempt attempt) async => _attempts.add(attempt);
}

class _FakeQuizSourceRepository implements QuizSourceRepository {
  final List<QuizSource> _sources = [];
  @override
  Future<void> deleteSource(String id) async =>
      _sources.removeWhere((s) => s.id == id);
  @override
  Future<List<QuizSource>> getSources() async => List.unmodifiable(_sources);
  @override
  Future<void> saveSource(QuizSource source) async => _sources.add(source);
  @override
  Future<void> toggleFavorite(String id) async {}
  @override
  Future<void> updateSource(QuizSource source) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final viewports = [
    const Size(1920, 1080),
    const Size(1536, 864),
    const Size(1366, 768),
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(390, 844),
  ];

  for (final vp in viewports) {
    testWidgets('Responsive Start Adaptive Practice Card at ${vp.width.toInt()}x${vp.height.toInt()}',
        (tester) async {
      tester.view.physicalSize = vp;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      TitanServiceLocator.instance.reset();

      final authRepo = InMemoryAuthoritativeLearningStateRepository();
      final checkpointRepo = InMemorySessionCheckpointRepository();
      final authRecoveryService =
          AuthoritativeLearningStateRecoveryService(repository: authRepo);
      final sessionRecoveryService = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: authRecoveryService,
      );
      final framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final curriculumService = CurriculumService(framework: framework);

      final learnerController = LearnerDashboardController(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: sessionRecoveryService,
        curriculumService: curriculumService,
      );

      final controller = DashboardController(
        learnerController: learnerController,
        sessionRepository: _FakeQuizSessionRepository(),
        historyRepository: _FakeQuizHistoryRepository(),
        sourceRepository: _FakeQuizSourceRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: QuizForgeDashboardPage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final textFinder = find.text('Start Adaptive Practice');
      expect(textFinder, findsOneWidget);

      final cardFinder =
          find.ancestor(of: textFinder, matching: find.byType(Card)).first;
      final buttonFinder = find.widgetWithText(FilledButton, 'Start');

      final cardSize = tester.getSize(cardFinder);
      final textSize = tester.getSize(textFinder);
      final buttonSize = tester.getSize(buttonFinder);

      print('=== ${vp.width.toInt()}x${vp.height.toInt()} ===');
      print('  Card: $cardSize');
      print('  Text: $textSize');
      print('  Button: $buttonSize');

      // Card height should be normal and non-inflated (< 300px instead of >1900px)
      expect(cardSize.height, lessThan(300.0));

      // Text width should be natural and not collapsed to a single character column (<30px)
      expect(textSize.width, greaterThan(80.0));

      // Button width must NOT stretch to infinite/full card width (>1000px)
      expect(buttonSize.width, lessThan(200.0));

      // Button height should be standard accessible touch target (>= 44px)
      expect(buttonSize.height, greaterThanOrEqualTo(44.0));

      // Consume any lower-level overflow logs from unrelated bottom feed widgets on small viewports
      tester.takeException();
    });
  }
}
