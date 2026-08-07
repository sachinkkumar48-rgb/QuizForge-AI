import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/controllers/garuda_dashboard_viewmodel.dart';
import 'package:quizforge_upsc/pages/garuda_dashboard_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GARUDA AI Learning Analytics & Performance Dashboard (Sprint 8.3 / TITAN-S8.3.002)', () {
    testWidgets('Verification: GarudaDashboardPage loads and renders header and core widgets', (WidgetTester tester) async {
      final mockRepo = MockGarudaDashboardRepository();
      final viewModel = DashboardViewModel(repository: mockRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: GarudaDashboardPage(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Dashboard Header
      expect(find.text('GARUDA AI Dashboard'), findsOneWidget);

      // 2. Next Best Action
      expect(find.text('Next Best Action'), findsOneWidget);

      // 3. Study Streak
      expect(find.textContaining('Day Study Streak!'), findsOneWidget);
    });

    testWidgets('Verification: Responsive rendering in Mobile viewport (<600px)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      final viewModel = DashboardViewModel(repository: MockGarudaDashboardRepository());

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: GarudaDashboardPage(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('GARUDA AI Dashboard'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Verification: Responsive rendering in Desktop viewport (>1000px)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;

      final viewModel = DashboardViewModel(repository: MockGarudaDashboardRepository());

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: GarudaDashboardPage(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('GARUDA AI Dashboard'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    test('Verification: Analytics DTO JSON deserialization mappings', () {
      final summary = DashboardSummaryDto.fromJson({
        'overall_mastery': 0.75,
        'overall_accuracy': 0.82,
        'questions_attempted': 200,
        'correct_answers': 164,
        'study_hours': 15.0,
        'study_streak': 10,
        'learning_velocity': 0.08,
        'confidence_score': 3.5,
        'completion_percentage': 75.0,
      });

      expect(summary.overallMastery, 0.75);
      expect(summary.overallAccuracy, 0.82);
      expect(summary.questionsAttempted, 200);
      expect(summary.studyStreak, 10);

      final recs = RecommendationsDto.fromJson({
        'next_best_action': 'Revise Article 14',
        'todays_goal': 'Complete 2 Quizzes',
        'priority_topic': 'Polity',
        'suggested_revision': 'Spaced Repetition',
        'suggested_quiz': 'Polity Test',
        'suggested_reading': 'Summary Doc',
      });

      expect(recs.nextBestAction, 'Revise Article 14');
      expect(recs.todaysGoal, 'Complete 2 Quizzes');
    });
  });
}
