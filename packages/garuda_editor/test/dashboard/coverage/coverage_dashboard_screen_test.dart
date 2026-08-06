import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/dashboard/coverage/garuda_coverage_dashboard.dart';
import 'package:garuda_pyq/garuda_pyq.dart' hide CoverageReport;

void main() {
  group('CoverageDashboardScreen Widget & Presentation Tests', () {
    late IPYQRepository repository;

    setUp(() async {
      repository = OfflinePYQRepository();

      // Seed mock questions into repository
      await repository.saveQuestions([
        Question(
          id: 'Q_UPSC_01',
          examId: 'upsc_cse',
          year: 2024,
          stage: 'Prelims',
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Fundamental Rights',
          originalQuestion: 'Which article guarantees right to equality?',
          options: const [Option(key: 'A', text: 'Art 14', isCorrect: true)],
          officialAnswer: const Answer(correctOptionKeys: ['A']),
          source: QuestionSource(
            sourceType: SourceType.officialWebsite,
            publisher: 'UPSC 2024',
            retrievedDate: DateTime(2024),
            checksum: 'chk1',
          ),
          verificationStatus: 'Verified',
          editorialStatus: EditorialStatus.published,
          trap: const QuestionTrap(
            id: 't1',
            questionId: 'Q_UPSC_01',
            trapType: 'Scope',
            commonMistake: '',
            expectedThinking: '',
            wrongEliminationStrategy: '',
            correctEliminationStrategy: '',
          ),
          learningObjectives: const LearningObjectives(studentShouldBeAbleTo: ['Identify Art 14']),
          knowledgeObjectLinks: const ['KO1'],
          articleLinks: const ['Article 14'],
        ),
        Question(
          id: 'Q_BPSC_01',
          examId: 'bpsc',
          year: 2023,
          stage: 'Prelims',
          paper: 'GS1',
          subject: 'History',
          topic: 'Ancient India',
          originalQuestion: 'Who was Maurya founder?',
          options: const [Option(key: 'A', text: 'Chandragupta', isCorrect: true)],
          officialAnswer: const Answer(correctOptionKeys: ['A']),
          source: QuestionSource(
            sourceType: SourceType.editorialEntry,
            publisher: 'BPSC 2023',
            retrievedDate: DateTime(2023),
            checksum: 'chk2',
          ),
          verificationStatus: 'Pending',
          editorialStatus: EditorialStatus.imported,
        ),
      ]);
    });

    testWidgets('Renders CoverageDashboardScreen and all 10 dashboard sections', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: CoverageDashboardScreen(repository: repository),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('GARUDA Editorial Coverage Dashboard'), findsOneWidget);

      // Verify Section Headers
      expect(find.text('1. National Overview'), findsOneWidget);
      expect(find.text('2. Exam Coverage'), findsOneWidget);
      expect(find.text('3. Subject Coverage'), findsOneWidget);
      expect(find.text('4. Topic Coverage'), findsOneWidget);
      expect(find.text('5. Year Matrix (1995 - 2026)'), findsOneWidget);
      expect(find.text('6. Editorial Queue'), findsOneWidget);
      expect(find.text('7. Knowledge Graph Status'), findsOneWidget);
      expect(find.text('8. Quality Dashboard'), findsOneWidget);
      expect(find.text('Editorial Filters'), findsOneWidget);
    });

    testWidgets('Filter interactions update dashboard metrics correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: CoverageDashboardScreen(repository: repository),
        ),
      );

      await tester.pumpAndSettle();

      // Initial Total Questions should be 2
      expect(find.text('2'), findsWidgets);

      // Select Exam Filter: BPSC
      final examDropdown = find.byKey(const Key('filter_exam_dropdown'));
      expect(examDropdown, findsOneWidget);
      await tester.tap(examDropdown);
      await tester.pumpAndSettle();

      final bpscOption = find.text('BPSC').last;
      await tester.tap(bpscOption);
      await tester.pumpAndSettle();

      // After filtering for BPSC, Total Questions count should update to 1
      expect(find.text('1'), findsWidgets);

      // Reset filters
      final resetButton = find.byKey(const Key('reset_filters_button'));
      expect(resetButton, findsOneWidget);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets);
    });

    testWidgets('Export button opens Export Modal with CSV, JSON, and Markdown tabs', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: CoverageDashboardScreen(repository: repository),
        ),
      );

      await tester.pumpAndSettle();

      final exportBtn = find.byKey(const Key('export_button'));
      expect(exportBtn, findsOneWidget);

      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      // Check Modal Title and Tabs
      expect(find.text('Export Coverage Dashboard'), findsOneWidget);
      expect(find.text('CSV Export'), findsOneWidget);
      expect(find.text('JSON Export'), findsOneWidget);
      expect(find.text('Markdown Summary'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Export Coverage Dashboard'), findsNothing);
    });
  });
}
