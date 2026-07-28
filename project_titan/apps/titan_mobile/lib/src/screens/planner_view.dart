import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_planner/titan_planner.dart';

class PlannerView extends ConsumerWidget {
  const PlannerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const task = StudyTask(
      id: 'task_p1',
      title: 'Polity: Preamble & Salient Features',
      topic: 'Indian Polity',
      category: 'Concept Learning',
      priority: 'High',
      estimatedDurationMinutes: 60,
    );

    const summary = StudySummary(
      totalTasksCount: 4,
      completedTasksCount: 1,
      totalAllocatedMinutes: 180,
      completedMinutes: 60,
      revisionMinutes: 30,
      learningMinutes: 90,
      practiceMinutes: 30,
      currentAffairsMinutes: 30,
      completionPercentage: 25.0,
      topFocusTopic: 'Indian Polity',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const DailySummaryCard(
            summary: summary,
            targetStudyTimeMinutes: 180,
          ),
          const SizedBox(height: 16),
          StudyTaskCard(
            task: task,
            onToggleCompletion: (completed) {},
          ),
        ],
      ),
    );
  }
}
