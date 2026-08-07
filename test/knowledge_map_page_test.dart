import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/features/learning/presentation/knowledge_map_page.dart';
import 'package:quizforge_upsc/features/learning/widgets/knowledge_node.dart';
import 'package:quizforge_upsc/features/learning/widgets/knowledge_path.dart';
import 'package:quizforge_upsc/features/learning/widgets/module_progress_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Knowledge Map Widgets & Screen Tests', () {
    testWidgets('KnowledgeNode renders completed state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KnowledgeNode(
              lessonId: 'POL.FR.001',
              title: 'Why Fundamental Rights?',
              estimatedTime: '15 Minutes',
              difficulty: 'Beginner',
              state: NodeState.completed,
            ),
          ),
        ),
      );

      expect(find.text('POL.FR.001'), findsOneWidget);
      expect(find.text('Why Fundamental Rights?'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('Beginner'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('KnowledgeNode renders locked state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KnowledgeNode(
              lessonId: 'POL.FR.003',
              title: 'Article 14: Equality Before Law',
              estimatedTime: '15 Minutes',
              difficulty: 'Intermediate',
              state: NodeState.locked,
            ),
          ),
        ),
      );

      expect(find.text('POL.FR.003'), findsOneWidget);
      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('ModuleProgressCard displays statistics correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModuleProgressCard(
              subject: 'Indian Polity',
              moduleTitle: 'Module 7: Fundamental Rights',
              completedLessons: 1,
              totalLessons: 12,
            ),
          ),
        ),
      );

      expect(find.text('INDIAN POLITY'), findsOneWidget);
      expect(find.text('Module 7: Fundamental Rights'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // Completed
      expect(find.text('11'), findsOneWidget); // Remaining
      expect(find.text('12'), findsOneWidget); // Total
      expect(find.text('8% COMPLETED'), findsOneWidget);
    });

    testWidgets('KnowledgePath renders directional connector icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KnowledgePath(isCompleted: true),
          ),
        ),
      );

      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    });

    testWidgets('KnowledgeMapPage renders progression tree dynamically', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KnowledgeMapPage(
            completedLessonIds: ['POL.FR.001'],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Knowledge Map'), findsOneWidget);
      expect(find.text('Module 7: Fundamental Rights'), findsOneWidget);
      expect(find.text('Why Fundamental Rights?'), findsOneWidget);
      expect(find.text('Articles 12 & 13: Definition of State & Judicial Review'), findsOneWidget);
    });
  });
}
