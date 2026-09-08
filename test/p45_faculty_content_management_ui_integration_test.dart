import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:quizforge_upsc/pages/faculty_content_management_page.dart';
import 'package:quizforge_upsc/pages/settings_page.dart';
import 'package:quizforge_upsc/repositories/api_key_repository.dart';

class MockApiKeyRepository implements ApiKeyRepository {
  @override
  Future<void> saveKey(String key) async {}
  @override
  Future<String?> loadKey() async => null;
  @override
  Future<void> deleteKey() async {}
  @override
  Future<bool> hasKey() async => false;
  @override
  Future<bool> validateKey(String key) async => true;
}

void main() {
  group('P45 Faculty Content Management UI Integration Tests', () {
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late InMemoryFacultyContentRepository contentRepo;
    late InMemoryRemedialLessonRepository remedialRepo;
    late FacultyContentService service;

    setUp(() {
      ApiKeyRepository.instance = MockApiKeyRepository();
      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);
      contentRepo = InMemoryFacultyContentRepository();
      remedialRepo = InMemoryRemedialLessonRepository();
      service = FacultyContentService(
        contentRepository: contentRepo,
        curriculumService: curriculumService,
        remedialRepository: remedialRepo,
      );
    });

    testWidgets('1. Renders Faculty Content Management portal with filters and empty state',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FacultyContentManagementPage(
            contentService: service,
            curriculumService: curriculumService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Faculty Content Management'), findsOneWidget);
      expect(find.text('Curriculum Taxonomy Filter'), findsOneWidget);
      expect(find.text('No Content Found'), findsOneWidget);
      expect(find.byKey(const Key('create_content_fab')), findsOneWidget);
    });

    testWidgets('2. Faculty authors, validates, saves draft, and publishes question via UI',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FacultyContentManagementPage(
            contentService: service,
            curriculumService: curriculumService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open creation dialog
      await tester.tap(find.byKey(const Key('create_content_fab')));
      await tester.pumpAndSettle();

      expect(find.text('Create New Content'), findsOneWidget);

      // Fill in content form
      await tester.enterText(
        find.byKey(const Key('editor_title_input')),
        'Judicial Review Concept Question',
      );
      await tester.enterText(
        find.byKey(const Key('editor_prompt_input')),
        'Which article provides the constitutional foundation for judicial review?',
      );
      await tester.enterText(
        find.byKey(const Key('editor_opt_a_input')),
        'Article 13',
      );
      await tester.enterText(
        find.byKey(const Key('editor_opt_b_input')),
        'Article 14',
      );
      await tester.enterText(
        find.byKey(const Key('editor_correct_ans_input')),
        'A',
      );

      // Validate
      await tester.tap(find.byKey(const Key('editor_validate_button')));
      await tester.pumpAndSettle();

      expect(find.text('Validation passed! Ready to publish.'), findsOneWidget);

      // Save Draft
      await tester.tap(find.byKey(const Key('editor_save_draft_button')));
      await tester.pumpAndSettle();

      // Card appears with DRAFT chip and version v1
      expect(find.text('Judicial Review Concept Question'), findsOneWidget);
      expect(find.text('DRAFT'), findsOneWidget);
      expect(find.text('v1'), findsOneWidget);
      expect(find.text('QUESTION'), findsOneWidget);

      // Tap Publish button
      final publishButtons = find.widgetWithText(FilledButton, 'Publish');
      expect(publishButtons, findsWidgets);
      await tester.tap(publishButtons.first);
      await tester.pumpAndSettle();

      // Transitions to PUBLISHED
      expect(find.text('PUBLISHED'), findsOneWidget);
      expect(find.text('Unpublish'), findsOneWidget);
    });

    testWidgets('3. Preview modal displays formatted question and options correctly',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final item = await service.createDraft(
        id: 'q_test_ui_prev',
        title: 'Equality Before Law',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_ui',
        provenance: 'Dicey Rule of Law',
        prompt: 'From which constitution was the concept of equal protection of laws borrowed?',
        options: const ['British Constitution', 'US Constitution'],
        correctAnswer: 'US Constitution',
      );
      await service.publishContent(item.id);

      await tester.pumpWidget(
        MaterialApp(
          home: FacultyContentManagementPage(
            contentService: service,
            curriculumService: curriculumService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Preview button
      await tester.tap(find.byKey(Key('preview_button_${item.id}')));
      await tester.pumpAndSettle();

      expect(find.text('Preview: Equality Before Law'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('From which constitution was the concept of equal protection of laws borrowed?'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('US Constitution'),
        ),
        findsWidgets,
      );

      // Close preview
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Preview: Equality Before Law'), findsNothing);
    });

    testWidgets('4. SettingsPage contains Faculty Content Management tile leading to portal',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Administration & Faculty'), findsOneWidget);
      final facultyTile = find.text('Faculty Content Management');
      expect(facultyTile, findsOneWidget);

      // Scroll into view if needed and tap
      await tester.ensureVisible(facultyTile);
      await tester.tap(facultyTile);
      await tester.pumpAndSettle();

      // Navigated to Faculty Content Management page
      expect(find.byType(FacultyContentManagementPage), findsOneWidget);
    });
  });
}
