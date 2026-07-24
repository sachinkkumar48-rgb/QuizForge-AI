import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/controllers/dashboard_controller.dart';
import 'package:quizforge_upsc/models/quiz_attempt.dart';
import 'package:quizforge_upsc/models/quiz_session.dart';
import 'package:quizforge_upsc/models/quiz_source.dart';
import 'package:quizforge_upsc/pages/quizforge_dashboard_page.dart';
import 'package:quizforge_upsc/repositories/quiz_history_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_session_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_source_repository.dart';
import 'package:titan_core/titan_core.dart';

class TestSourceRepo implements QuizSourceRepository {
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

class TestHistoryRepo implements QuizHistoryRepository {
  @override
  Future<List<QuizAttempt>> getAttempts() async => [];
  @override
  Future<void> saveAttempt(QuizAttempt attempt) async {}
  @override
  Future<void> clearHistory() async {}
  @override
  Future<void> deleteAttempt(String id) async {}
}

class TestSessionRepo implements QuizSessionRepository {
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

  group('QuizForgeDashboardPage Widget Tests', () {
    tearDown(() {
      TitanServiceLocator.instance.reset();
    });

    testWidgets(
        'Verification: QuizForgeDashboardPage renders Material 3 header and action cards',
        (WidgetTester tester) async {
      final controller = DashboardController(
        sourceRepository: TestSourceRepo(),
        historyRepository: TestHistoryRepo(),
        sessionRepository: TestSessionRepo(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: QuizForgeDashboardPage(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("QuizForge AI"), findsOneWidget);
      expect(find.text("Quick Actions"), findsOneWidget);
      expect(find.text("Generate AI Quiz"), findsOneWidget);
      expect(find.text("UPSC PYQ Vault"), findsOneWidget);
      expect(find.text("AI Learning Coach"), findsOneWidget);
      expect(find.text("PDF Library"), findsOneWidget);
    });

    testWidgets(
        'Verification: QuizForgeDashboardPage renders responsiveness in tablet/desktop constraints',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;

      final controller = DashboardController(
        sourceRepository: TestSourceRepo(),
        historyRepository: TestHistoryRepo(),
        sessionRepository: TestSessionRepo(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: QuizForgeDashboardPage(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Recent Activity"), findsOneWidget);
      expect(find.text("Active Exam Modules"), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
