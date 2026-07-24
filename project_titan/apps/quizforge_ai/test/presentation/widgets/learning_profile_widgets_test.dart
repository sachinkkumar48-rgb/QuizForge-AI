import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/src/presentation/widgets/profile/learning_profile_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/profile/learning_streak_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/profile/learning_trend_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/profile/mastery_chart_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/profile/study_habit_card.dart';
import 'package:quizforge_ai/src/presentation/widgets/profile/weak_area_card.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';

void main() {
  group('Material 3 Learning Profile Widgets Tests', () {
    final now = DateTime(2026, 7, 24);

    final sampleTopicMastery = TopicMastery(
      topic: 'Indian Polity',
      subject: 'Polity',
      masteryPercentage: 78.5,
      totalAttempted: 45,
      correctCount: 35,
      retentionScore: 82.0,
      lastPracticedAt: now,
      masteryLevel: 'Proficient',
    );

    final sampleHabit = StudyHabit(
      peakStudyHour: 20,
      preferredSubject: 'Indian Polity',
      avgSessionDurationMinutes: 28,
      totalSessionsCompleted: 18,
      consistencyScore: 85.0,
      activeDaysCount: 12,
    );

    final sampleStreak = LearningStreak(
      currentStreakDays: 7,
      longestStreakDays: 14,
      lastActivityDate: now,
      streakFreezeCount: 1,
      isStreakActive: true,
    );

    final sampleProfile = LearningProfile(
      userId: 'user_titan',
      learnerLevel: 'Consistent Learner',
      overallAccuracy: 70.3,
      totalQuizzesAttempted: 18,
      totalQuestionsAnswered: 165,
      totalStudyTimeMinutes: 504,
      topicMasteries: [sampleTopicMastery],
      studyHabit: sampleHabit,
      streak: sampleStreak,
      weakTopics: const ['Environment & Ecology'],
      lastActiveAt: now,
    );

    testWidgets('LearningProfileCard renders learner metrics correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearningProfileCard(profile: sampleProfile),
          ),
        ),
      );

      expect(find.text('Learner Profile'), findsOneWidget);
      expect(find.text('Consistent Learner'), findsOneWidget);
      expect(find.text('70.3% Accuracy'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('165'), findsOneWidget);
      expect(find.text('504 min'), findsOneWidget);
    });

    testWidgets('MasteryChartCard renders topic mastery overview',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MasteryChartCard(topicMasteries: [sampleTopicMastery]),
          ),
        ),
      );

      expect(find.text('Topic Mastery Overview'), findsOneWidget);
      expect(find.text('Indian Polity'), findsOneWidget);
      expect(find.text('78.5% (Proficient)'), findsOneWidget);
    });

    testWidgets('LearningTrendCard renders consistency score and active days',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearningTrendCard(profile: sampleProfile),
          ),
        ),
      );

      expect(find.text('Learning & Retention Trend'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('12 Days'), findsOneWidget);
    });

    testWidgets('StudyHabitCard renders peak hour and preferred subject',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudyHabitCard(habit: sampleHabit),
          ),
        ),
      );

      expect(find.text('Study Habits & Patterns'), findsOneWidget);
      expect(find.text('8 PM'), findsOneWidget);
      expect(find.text('Indian Polity'), findsOneWidget);
    });

    testWidgets('LearningStreakCard renders streak flame and days count',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearningStreakCard(streak: sampleStreak),
          ),
        ),
      );

      expect(find.text('7 Day Streak!'), findsOneWidget);
      expect(find.text('Longest Streak: 14 days'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('WeakAreaCard renders weak topic chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeakAreaCard(weakTopics: ['Environment & Ecology']),
          ),
        ),
      );

      expect(find.text('Identified Focus & Weak Areas'), findsOneWidget);
      expect(find.text('Environment & Ecology'), findsOneWidget);
    });
  });
}
