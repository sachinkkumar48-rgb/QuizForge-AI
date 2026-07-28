import 'package:flutter_test/flutter_test.dart';
import 'package:titan_dashboard/titan_dashboard.dart';

void main() {
  group('Dashboard Models Unit Tests', () {
    test('PerformanceTrend creation and json serialization', () {
      final trend = PerformanceTrend(
        timestamps: [DateTime(2026, 1, 1)],
        accuracyPoints: const [0.85],
        studyHoursPoints: const [4.0],
        averageAccuracy: 0.85,
      );

      expect(trend.averageAccuracy, equals(0.85));
      expect(trend.accuracyPoints, contains(0.85));

      final json = trend.toJson();
      final restored = PerformanceTrend.fromJson(json);
      expect(restored.averageAccuracy, equals(0.85));
      expect(restored.trendDirection, equals('improving'));
    });

    test('GoalProgress creation and percentage calculation', () {
      final goal = GoalProgress(
        title: 'Daily Budget',
        category: 'Study',
        targetValue: 6.0,
        currentValue: 3.0,
        deadline: DateTime(2026, 12, 31),
      );

      expect(goal.completionPercentage, equals(0.5));

      final json = goal.toJson();
      final restored = GoalProgress.fromJson(json);
      expect(restored.title, equals('Daily Budget'));
      expect(restored.completionPercentage, equals(0.5));
    });

    test('StudyStatistics accuracy calculation', () {
      const stats = StudyStatistics(
        totalQuestionsAttempted: 100,
        correctAnswersCount: 80,
      );

      expect(stats.overallAccuracy, equals(0.8));

      final json = stats.toJson();
      final restored = StudyStatistics.fromJson(json);
      expect(restored.totalQuestionsAttempted, equals(100));
      expect(restored.overallAccuracy, equals(0.8));
    });

    test('LearningInsights serialization and copyWith', () {
      final insights = LearningInsights(
        keyTakeaways: const ['Great progress'],
        topRecommendation: 'Revise Polity',
      );

      expect(insights.keyTakeaways, contains('Great progress'));

      final json = insights.toJson();
      final restored = LearningInsights.fromJson(json);
      expect(restored.topRecommendation, equals('Revise Polity'));
    });

    test('DashboardSnapshot serialization', () {
      final snapshot = DashboardSnapshot.empty(userId: 'u_123');
      expect(snapshot.userId, equals('u_123'));
      expect(snapshot.userName, equals('Learner'));

      final json = snapshot.toJson();
      final restored = DashboardSnapshot.fromJson(json);
      expect(restored.userId, equals('u_123'));
    });
  });
}
