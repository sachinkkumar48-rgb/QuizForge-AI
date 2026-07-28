import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_smart_assessment/titan_smart_assessment.dart';

class AssessmentsView extends ConsumerWidget {
  const AssessmentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const blueprint = AssessmentBlueprint(
      id: 'bp_polity_01',
      title: 'Polity Blueprint',
      subjectCategory: 'Polity',
      topicWeights: {'Polity': 1.0},
      totalQuestions: 100,
      timeLimitMinutes: 120,
    );

    final assessment = Assessment(
      id: 'asm_01',
      title: 'Polity Comprehensive Mock Test',
      description: '100 MCQs covering Indian Constitution & Governance',
      type: AssessmentType.mockExam,
      blueprint: blueprint,
      totalDurationMinutes: 120,
      createdAt: DateTime.now(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReadinessScoreCard(
            readinessScore: 76.5,
            examPrediction: 'High Probability of Clearing Prelims',
          ),
          const SizedBox(height: 16),
          Text(
            'Available Assessments',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          AssessmentCard(assessment: assessment),
        ],
      ),
    );
  }
}
