import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:titan_learning/titan_learning.dart';

class LearningView extends ConsumerWidget {
  const LearningView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LearningFlowScreen(
      userId: 'user_titan',
      courseId: 'course_polity_101',
      courseTitle: 'Indian Polity & Governance',
      lessonId: 'lesson_fr_21',
      lessonTitle: 'Fundamental Rights & Article 21',
      onReturnToDashboard: () {
        context.go('/dashboard');
      },
    );
  }
}
