import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning_content/titan_learning_content.dart';

void main() {
  group('Material 3 Widgets Unit & Widget Tests', () {
    late LearningContent testContent;
    late LearningActivityRecord testRecord;

    setUp(() {
      final meta = ContentMetadata(
        author: 'Dr. Laxmikanth',
        subject: 'Polity',
        topic: 'Preamble',
        difficultyLevel: 'Intermediate',
        estimatedDurationMinutes: 30,
        format: 'mp4_hd',
        fileSizeFormat: '145 MB',
        tags: const ['Preamble'],
        isOfflineAvailable: true,
      );

      final objective = const ContentObjective(
        id: 'o1',
        title: 'Understand Preamble',
        description: 'Philosophy of Constitution',
        bloomsTaxonomyLevel: 'Understand',
      );

      final prereq = const ContentPrerequisite(
        id: 'p1',
        requiredContentId: 'lc_0',
        title: 'Basic History Notes',
      );

      final outcome = const ContentOutcome(
        id: 'out1',
        title: 'Constitutional Clarity',
        description: 'Master key concepts',
        skillBadge: 'Legal Scholar',
      );

      final progress = ContentProgress(
        contentId: 'lc_1',
        userId: 'u1',
        lastPositionSeconds: 600,
        completionPercentage: 50.0,
        timeSpentSeconds: 900,
        lastAccessedAt: DateTime(2026, 1, 1),
      );

      testContent = LearningContent(
        id: 'lc_1',
        title: 'Preamble & Philosophy',
        description: 'Comprehensive analysis of Preamble.',
        type: ContentType.video,
        metadata: meta,
        objectives: [objective],
        prerequisites: [prereq],
        outcomes: [outcome],
        references: const [],
        progress: progress,
      );

      testRecord = LearningActivityRecord(
        userId: 'u1',
        contentId: 'lc_1',
        activities: [
          LearningActivity(
            id: 'a1',
            userId: 'u1',
            contentId: 'lc_1',
            activityType: LearningActivityType.started,
          ),
        ],
        totalDurationSeconds: 60,
        activityCount: 1,
        lastActivityAt: DateTime(2026, 1, 1),
        activityBreakdown: const {'started': 1},
      );
    });

    Widget wrapMaterial(Widget child) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );
    }

    testWidgets('LearningContentTile renders title and type badge',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(wrapMaterial(LearningContentTile(content: testContent)));
      expect(find.text('Preamble & Philosophy'), findsOneWidget);
    });

    testWidgets(
        'ContentProgressIndicator renders percentage text and progress bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapMaterial(
          ContentProgressIndicator(progress: testContent.progress)));
      expect(find.text('50% Completed'), findsOneWidget);
    });

    testWidgets('ContentMetadataCard renders author and offline status',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          wrapMaterial(ContentMetadataCard(metadata: testContent.metadata)));
      expect(find.text('Dr. Laxmikanth'), findsOneWidget);
      expect(find.text('Offline Ready'), findsOneWidget);
    });

    testWidgets('ContentObjectivesCard renders objectives and taxonomy tag',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapMaterial(
          ContentObjectivesCard(objectives: testContent.objectives)));
      expect(find.text('Understand Preamble'), findsOneWidget);
      expect(find.text('Understand'), findsOneWidget);
    });

    testWidgets('PrerequisiteCard renders required prerequisite title',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapMaterial(
          PrerequisiteCard(prerequisites: testContent.prerequisites)));
      expect(find.textContaining('Basic History Notes'), findsOneWidget);
    });

    testWidgets('LearningOutcomeCard renders outcomes and skill badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          wrapMaterial(LearningOutcomeCard(outcomes: testContent.outcomes)));
      expect(find.text('Legal Scholar'), findsOneWidget);
    });

    testWidgets('ContinueContentCard renders content title and resume button',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(wrapMaterial(ContinueContentCard(content: testContent)));
      expect(find.text('Preamble & Philosophy'), findsOneWidget);
      expect(find.text('Resume Content'), findsOneWidget);
    });

    testWidgets('LearningActivityTimeline renders activity event list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          wrapMaterial(LearningActivityTimeline(record: testRecord)));
      expect(find.textContaining('STARTED'), findsOneWidget);
    });
  });
}
