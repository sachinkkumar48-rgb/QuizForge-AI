import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_learning_journey/titan_learning_journey.dart';

class JourneyView extends ConsumerWidget {
  const JourneyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const engine = LearningJourneyEngine();
    final config = JourneyConfiguration(
      journeyId: 'j_app_1',
      targetExam: 'UPSC CSE 2026',
      targetExamDate: DateTime.now().add(const Duration(days: 150)),
      dailyTimeBudgetMinutes: 120,
      targetConfidenceScore: 0.85,
    );

    final journey = engine.generateRoadmap(
      learnerId: 'user_titan',
      config: config,
    );

    return JourneyDashboard(
      journey: journey,
      recommendations: const [],
      insights: const [],
      timeline: const JourneyTimeline(journeyId: 'j_app_1'),
    );
  }
}
