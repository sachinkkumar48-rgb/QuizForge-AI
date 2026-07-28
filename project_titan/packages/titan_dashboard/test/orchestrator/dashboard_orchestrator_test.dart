import 'package:flutter_test/flutter_test.dart';
import 'package:titan_dashboard/titan_dashboard.dart';

void main() {
  group('DashboardOrchestrator Unit Tests', () {
    late DashboardOrchestrator orchestrator;

    setUp(() {
      orchestrator = DashboardOrchestrator();
    });

    tearDown(() async {
      await orchestrator.dispose();
    });

    test('loadDashboard asynchronously aggregates all 12 section models',
        () async {
      final state = await orchestrator.loadDashboard(
        userId: 'user_test_123',
        userName: 'Sachin Kumar',
      );

      expect(state.isLoading, isFalse);
      expect(state.header.displayName, equals('Sachin Kumar'));
      expect(state.todayFocus.topic, isNotEmpty);
      expect(state.continueLearning.courseTitle, isNotEmpty);
      expect(state.revisionDue.todayRevisionCount, greaterThan(0));
      expect(state.aiTutor.questionOfTheDay, isNotEmpty);
      expect(state.recommendations.topRecommendations, isNotEmpty);
      expect(state.journey.roadmapTitle, isNotEmpty);
      expect(state.assessmentReadiness.readinessScore, greaterThan(0));
      expect(state.weeklyAnalytics.studyHours, greaterThan(0));
      expect(state.upcomingEvents.events, isNotEmpty);
      expect(state.achievements.badges, isNotEmpty);
    });

    test('refreshDashboard updates timestamp and emits fresh state', () async {
      final initial = await orchestrator.loadDashboard(
        userId: 'user_test_123',
        userName: 'Sachin Kumar',
      );

      final initialTime = initial.lastUpdated;
      await Future.delayed(const Duration(milliseconds: 10));

      final refreshed = await orchestrator.refreshDashboard(
        userId: 'user_test_123',
        userName: 'Sachin Kumar',
      );

      expect(refreshed.lastUpdated.isAfter(initialTime), isTrue);
    });

    test('stateStream broadcasts state updates to listeners', () async {
      expect(
        orchestrator.stateStream,
        emitsThrough(
          isA<UnifiedDashboardState>().having(
              (s) => s.header.displayName, 'displayName', 'Sachin Kumar'),
        ),
      );

      await orchestrator.loadDashboard(
        userId: 'user_test_123',
        userName: 'Sachin Kumar',
      );
    });
  });
}
