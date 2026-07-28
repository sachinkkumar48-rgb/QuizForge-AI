import 'package:flutter_test/flutter_test.dart';
import 'package:titan_dashboard/titan_dashboard.dart';

class MockDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSnapshot> getSnapshot({
    required String userId,
    required String userName,
    bool forceRefresh = false,
  }) async {
    return DashboardSnapshot(
      userId: userId,
      userName: userName,
      readinessScore: 82.0,
      statistics: const StudyStatistics(totalStudyHours: 5.0),
      trend: PerformanceTrend.empty(),
      insights: LearningInsights.empty(),
    );
  }

  @override
  Future<void> saveSnapshot(DashboardSnapshot snapshot) async {}

  @override
  Future<LearningInsights> generateInsights({
    required String userId,
    required String userName,
  }) async {
    return LearningInsights.empty();
  }
}

void main() {
  group('Engine Components Unit Tests', () {
    test('MetricsAggregator aggregates 10 TITAN engine outputs', () async {
      final aggregator = MetricsAggregator(
        identitySupplier: (_) =>
            {'userName': 'Sachin', 'targetExam': 'UPSC CSE'},
        analyticsSupplier: (_) => {
          'accuracyRate': 0.88,
          'totalQuestions': 500,
          'correctAnswers': 440
        },
        profileSupplier: (_) => {
          'weakSubjects': ['Ethics'],
          'strongSubjects': ['Economy'],
          'streakDays': 21
        },
        recommendationSupplier: (_) =>
            {'topRecommendation': 'Focus on Ethics Case Studies'},
        revisionSupplier: (_) => {'pendingCount': 12},
        plannerSupplier: (_) =>
            {'targetHours': 7.0, 'completedHours': 5.5, 'completedTasks': 6},
        searchSupplier: (_) => {
          'queries': ['Art and Culture', 'SNC-Lavalin']
        },
        knowledgeGraphSupplier: (_) =>
            {'activeConcept': 'Basic Structure Doctrine'},
        aiMentorSupplier: (_) =>
            {'mentorTip': 'Practice answer writing for GS4.'},
        librarySupplier: (_) => {'indexedPdfs': 15},
      );

      final snapshot = await aggregator.aggregate(
        userId: 'u_1',
        userName: 'Default',
      );

      expect(snapshot.userName, equals('Sachin'));
      expect(snapshot.targetExam, equals('UPSC CSE'));
      expect(snapshot.statistics.totalQuestionsAttempted, equals(500));
      expect(snapshot.statistics.currentStreakDays, equals(21));
      expect(snapshot.statistics.pendingRevisionsCount, equals(12));
      expect(snapshot.insights.topRecommendation,
          equals('Focus on Ethics Case Studies'));
      expect(snapshot.subsystemSummaries.keys.length, equals(10));
    });

    test(
        'DashboardEngine orchestrates snapshot retrieval and stream broadcasting',
        () async {
      final repo = MockDashboardRepository();
      final engine = DashboardEngine(repo);

      final snapshot =
          await engine.getSnapshot(userId: 'u_1', userName: 'Sachin');
      expect(snapshot.readinessScore, equals(82.0));

      final insights =
          await engine.generateInsights(userId: 'u_1', userName: 'Sachin');
      expect(insights, isNotNull);

      await engine.dispose();
    });
  });
}
