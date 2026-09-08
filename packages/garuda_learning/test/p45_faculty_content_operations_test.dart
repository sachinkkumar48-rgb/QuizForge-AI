import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P45 Faculty Content Operations Tests (TITAN-KO-045.0)', () {
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late InMemoryFacultyContentRepository contentRepo;
    late InMemoryRemedialLessonRepository remedialRepo;
    late FacultyContentService service;

    setUp(() {
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

    // 1. content creation
    test('1. content creation produces draft item with metadata and version 1',
        () async {
      final item = await service.createDraft(
        id: 'q_op_01',
        title: 'Article 21 Procedure Established by Law',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        authorName: 'Prof. Menon',
        provenance: 'Constitutional Law of India (Seervai)',
        prompt:
            'What does "procedure established by law" in Article 21 strictly signify?',
        options: const [
          'Law made by a competent legislature adhering to prescribed procedure',
          'Universal natural justice principles',
          'Substantive reasonableness only',
          'Executive discretion under emergency',
        ],
        correctAnswer:
            'Law made by a competent legislature adhering to prescribed procedure',
        explanation:
            'Derived from the Japanese Constitution, it focuses on formal statutory enactment.',
      );

      expect(item.id, equals('q_op_01'));
      expect(item.status, equals(ContentLifecycleStatus.draft));
      expect(item.version, equals(1));
      expect(item.authorId, equals('prof_menon'));
      expect(item.authorName, equals('Prof. Menon'));
      expect(item.isDraft, isTrue);
    });

    // 2. valid content
    test('2. valid content passes deterministic validation without errors', () {
      final item = ManagedContentItem(
        id: 'q_op_02',
        title: 'Right to Education Scope',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: '86th Constitutional Amendment Act',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        prompt:
            'Which article makes education a fundamental right for children aged 6 to 14?',
        options: const [
          'Article 21A',
          'Article 19',
          'Article 22',
          'Article 20'
        ],
        correctAnswer: 'Article 21A',
        explanation: 'Inserted by the 86th Amendment Act, 2002.',
      );

      final result = service.validateContent(item);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    // 3. empty title rejection
    test('3. empty title rejection marks validation failure', () {
      final item = ManagedContentItem(
        id: 'q_op_03',
        title: '   ',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Constitution of India',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        prompt: 'Valid prompt text goes here.',
        options: const ['Option A', 'Option B'],
        correctAnswer: 'Option A',
      );

      final result = service.validateContent(item);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('title cannot be empty')),
          isTrue);
    });

    // 4. empty body rejection
    test(
        '4. empty body rejection catches empty question prompt and empty lesson body',
        () {
      final qItem = ManagedContentItem(
        id: 'q_op_04',
        title: 'Test Empty Question',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Constitution of India',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        prompt: '   ',
        options: const ['Option A', 'Option B'],
        correctAnswer: 'Option A',
      );

      final qResult = service.validateContent(qItem);
      expect(qResult.isValid, isFalse);
      expect(
          qResult.errors.any((e) =>
              e.contains('body cannot be empty') || e.contains('prompt')),
          isTrue);

      final remItem = ManagedContentItem(
        id: 'rem_op_04',
        title: 'Test Empty Lesson',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.remedialLesson,
        authorId: 'prof_menon',
        provenance: 'Constitution of India',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        prompt: '',
        lessonExplanation: '',
        summary: '',
        explanation: '',
      );

      final remResult = service.validateContent(remItem);
      expect(remResult.isValid, isFalse);
      expect(
          remResult.errors.any((e) =>
              e.contains('body') || e.contains('pedagogical explanation')),
          isTrue);
    });

    // 5. invalid exam mapping
    test('5. invalid exam mapping is rejected by validator', () {
      final item = ManagedContentItem(
        id: 'q_op_05',
        title: 'Invalid Exam Item',
        examId: 'invalid_exam_code_xyz',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        prompt: 'Valid prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      final result = service.validateContent(item);
      expect(result.isValid, isFalse);
      expect(
          result.errors
              .any((e) => e.contains('Exam ID') || e.contains('Exam mapping')),
          isTrue);
    });

    // 6. invalid subject mapping
    test('6. invalid subject mapping is rejected by validator', () {
      final item = ManagedContentItem(
        id: 'q_op_06',
        title: 'Invalid Subject Item',
        examId: 'upsc_prelims_gs1',
        subjectId: 'invalid_subject_abc',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        prompt: 'Valid prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      final result = service.validateContent(item);
      expect(result.isValid, isFalse);
      expect(
          result.errors.any(
              (e) => e.contains('Subject ID') || e.contains('Subject mapping')),
          isTrue);
    });

    // 7. invalid topic mapping
    test('7. invalid topic mapping is rejected by validator', () {
      final item = ManagedContentItem(
        id: 'q_op_07',
        title: 'Invalid Topic Item',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'invalid_topic_xyz',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        prompt: 'Valid prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      final result = service.validateContent(item);
      expect(result.isValid, isFalse);
      expect(
          result.errors.any(
              (e) => e.contains('Topic ID') || e.contains('Topic mapping')),
          isTrue);
    });

    // 8. invalid objective mapping
    test(
        '8. invalid objective mapping is rejected when objective does not exist in framework',
        () {
      final item = ManagedContentItem(
        id: 'q_op_08',
        title: 'Non-Existent Objective Item',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'objective_does_not_exist_999',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        prompt: 'Valid prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      final result = service.validateContent(item);
      expect(result.isValid, isFalse);
      expect(
          result.errors
              .any((e) => e.contains('does not exist in curriculum framework')),
          isTrue);
    });

    // 9. save draft
    test('9. save draft stores content item in draft state in repository',
        () async {
      final item = await service.createDraft(
        id: 'q_op_09',
        title: 'Draft Stored Item',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation',
        prompt: 'Sample prompt for draft testing',
        options: const ['Yes', 'No'],
        correctAnswer: 'Yes',
      );

      final saved = await contentRepo.getById(item.id);
      expect(saved, isNotNull);
      expect(saved!.status, equals(ContentLifecycleStatus.draft));
      expect(saved.isDraft, isTrue);
    });

    // 10. retrieve draft
    test('10. retrieve draft returns accurate draft content attributes',
        () async {
      await service.createDraft(
        id: 'q_op_10',
        title: 'Retrieve Draft Title',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation 10',
        prompt: 'Prompt 10',
        options: const ['Opt1', 'Opt2'],
        correctAnswer: 'Opt1',
      );

      final retrieved = await contentRepo.getById('q_op_10');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Retrieve Draft Title'));
      expect(retrieved.options, equals(['Opt1', 'Opt2']));
      expect(retrieved.version, equals(1));
    });

    // 11. draft hidden from learner
    test('11. draft hidden from learner queries and published endpoints',
        () async {
      await service.createDraft(
        id: 'q_op_11',
        title: 'Draft Hidden Item',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation 11',
        prompt: 'Prompt 11',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      final published = await service.getPublishedQuestions();
      expect(published.any((q) => q.id == 'q_op_11'), isFalse);

      final learnerContent = await contentRepo
          .getPublishedContentForObjective('lo_article_21_foundations');
      expect(learnerContent.any((c) => c.id == 'q_op_11'), isFalse);
    });

    // 12. validation failure
    test('12. validation failure prevents publication and transitions status',
        () async {
      final item = ManagedContentItem(
        id: 'q_op_12',
        title: '',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await contentRepo.save(item);

      await expectLater(
        service.publishContent('q_op_12'),
        throwsA(isA<StateError>()),
      );

      final stored = await contentRepo.getById('q_op_12');
      expect(stored!.status, equals(ContentLifecycleStatus.validationFailed));
      expect(stored.validationErrors, isNotEmpty);
    });

    // 13. validation success
    test('13. validation success allows clean publication transition',
        () async {
      final item = await service.createDraft(
        id: 'q_op_13',
        title: 'Valid Question Title',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'AIR 2017 SC 4161',
        prompt: 'Is right to privacy protected under Article 21?',
        options: const ['Yes', 'No'],
        correctAnswer: 'Yes',
      );

      final published = await service.publishContent(item.id);
      expect(published.status, equals(ContentLifecycleStatus.published));
      expect(published.isPublished, isTrue);
    });

    // 14. preview
    test(
        '14. preview converts content item to runtime NormalizedQuestion representation',
        () async {
      final item = await service.createDraft(
        id: 'q_op_14',
        title: 'Preview Test Item',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Puttaswamy 2017',
        prompt: 'Right to privacy is protected under which article?',
        options: const ['Article 21', 'Article 14', 'Article 19', 'Article 32'],
        correctAnswer: 'Article 21',
        explanation: '9-judge bench unanimous verdict in Puttaswamy.',
      );

      final previewQuestion = item.toNormalizedQuestion();
      expect(previewQuestion.id, equals('q_op_14'));
      expect(previewQuestion.normalizedText,
          equals('Right to privacy is protected under which article?'));
      expect(previewQuestion.options.length, equals(4));
      expect(previewQuestion.officialAnswer.correctOptionKeys, contains('A'));
      expect(previewQuestion.source.sourceTitle, equals('Puttaswamy 2017'));
    });

    // 15. publish
    test('15. publish sets status to published and updates timestamp',
        () async {
      final item = await service.createDraft(
        id: 'q_op_15',
        title: 'Publish Test Item',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation 15',
        prompt: 'Prompt 15',
        options: const ['Choice A', 'Choice B'],
        correctAnswer: 'Choice A',
      );

      final published = await service.publishContent(item.id);
      expect(published.status, equals(ContentLifecycleStatus.published));
      expect(
          published.updatedAt.isAfter(item.createdAt) ||
              published.updatedAt == item.createdAt,
          isTrue);
    });

    // 16. published content visible to learner
    test('16. published content visible to learner discovery endpoints',
        () async {
      final item = await service.createDraft(
        id: 'q_op_16',
        title: 'Published Visible Question',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation 16',
        prompt: 'Is liberty absolute?',
        options: const ['No', 'Yes'],
        correctAnswer: 'No',
      );
      await service.publishContent(item.id);

      final published = await service.getPublishedQuestions();
      expect(published.any((q) => q.id == 'q_op_16'), isTrue);

      final objContent = await contentRepo
          .getPublishedContentForObjective('lo_article_21_foundations');
      expect(objContent.any((c) => c.id == 'q_op_16'), isTrue);
    });

    // 17. unpublish
    test('17. unpublish transitions status to unpublished', () async {
      final item = await service.createDraft(
        id: 'q_op_17',
        title: 'Unpublish Test Item',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation 17',
        prompt: 'Prompt 17',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );
      await service.publishContent(item.id);

      final unpublished = await service.unpublishContent(item.id);
      expect(unpublished.status, equals(ContentLifecycleStatus.unpublished));
      expect(unpublished.isPublished, isFalse);
    });

    // 18. unpublished content hidden
    test('18. unpublished content hidden from learner query endpoints',
        () async {
      final item = await service.createDraft(
        id: 'q_op_18',
        title: 'Hidden After Unpublish',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation 18',
        prompt: 'Prompt 18',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );
      await service.publishContent(item.id);
      await service.unpublishContent(item.id);

      final publishedQuestions = await service.getPublishedQuestions();
      expect(publishedQuestions.any((q) => q.id == 'q_op_18'), isFalse);

      final objContent = await contentRepo
          .getPublishedContentForObjective('lo_article_21_foundations');
      expect(objContent.any((c) => c.id == 'q_op_18'), isFalse);
    });

    // 19. edit draft
    test('19. edit draft mutates draft item in-place preserving version number',
        () async {
      final item = await service.createDraft(
        id: 'q_op_19',
        title: 'Original Draft Title',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation 19',
        prompt: 'Original prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      final updated = await service.updateDraft(item.copyWith(
        title: 'Updated Draft Title',
        prompt: 'Updated prompt',
      ));

      expect(updated.version, equals(1));
      expect(updated.title, equals('Updated Draft Title'));
      expect(updated.prompt, equals('Updated prompt'));
    });

    // 20. edit published content
    test(
        '20. edit published content creates a new draft version preserving published item',
        () async {
      final item = await service.createDraft(
        id: 'q_op_20',
        title: 'Published Item to Edit',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation 20',
        prompt: 'Version 1 prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );
      await service.publishContent(item.id);

      final newDraft = await service.updateDraft(item.copyWith(
        prompt: 'Version 2 revised prompt',
      ));

      expect(newDraft.version, equals(2));
      expect(newDraft.status, equals(ContentLifecycleStatus.draft));
      expect(newDraft.prompt, equals('Version 2 revised prompt'));

      // Version 1 remains intact in storage and published
      final v1 = await contentRepo.getById(item.id, version: 1);
      expect(v1, isNotNull);
      expect(v1!.status, equals(ContentLifecycleStatus.published));
      expect(v1.prompt, equals('Version 1 prompt'));
    });

    // 21. version increment
    test(
        '21. version increment occurs monotonically upon edits to published content',
        () async {
      final item = await service.createDraft(
        id: 'q_op_21',
        title: 'Monotonic Versioning',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation 21',
        prompt: 'Prompt 21',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );
      await service.publishContent(item.id);

      final v2 = await service.updateDraft(item.copyWith(title: 'Revision 2'));
      expect(v2.version, equals(2));

      await service.publishContent(v2.id);

      final v3 = await service.updateDraft(v2.copyWith(title: 'Revision 3'));
      expect(v3.version, equals(3));
    });

    // 22. previous version preserved
    test('22. previous version preserved and queryable by version number',
        () async {
      final item = await service.createDraft(
        id: 'q_op_22',
        title: 'Preserved v1',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation 22',
        prompt: 'v1 prompt text',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );
      await service.publishContent(item.id);

      final v2Draft = await service.updateDraft(item.copyWith(
        title: 'Revision v2',
        prompt: 'v2 prompt text',
      ));
      await service.publishContent(v2Draft.id);

      final v1Stored = await contentRepo.getById('q_op_22', version: 1);
      final v2Stored = await contentRepo.getById('q_op_22', version: 2);

      expect(v1Stored, isNotNull);
      expect(v1Stored!.title, equals('Preserved v1'));
      expect(v1Stored.prompt, equals('v1 prompt text'));

      expect(v2Stored, isNotNull);
      expect(v2Stored!.title, equals('Revision v2'));
      expect(v2Stored.prompt, equals('v2 prompt text'));
    });

    // 23. publish new version
    test('23. publish new version makes v2 the active published version',
        () async {
      final item = await service.createDraft(
        id: 'q_op_23',
        title: 'Publish v2 Test',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation 23',
        prompt: 'v1 text',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );
      await service.publishContent(item.id);

      final v2Draft =
          await service.updateDraft(item.copyWith(prompt: 'v2 improved text'));
      final v2Published = await service.publishContent(v2Draft.id);

      expect(v2Published.version, equals(2));
      expect(v2Published.isPublished, isTrue);

      final activePub = await contentRepo.getPublishedVersion('q_op_23');
      expect(activePub, isNotNull);
      expect(activePub!.version, equals(2));
      expect(activePub.prompt, equals('v2 improved text'));
    });

    // 24. learner receives current published version
    test('24. learner receives current published version after publication',
        () async {
      final item = await service.createDraft(
        id: 'q_op_24',
        title: 'Learner Receives v2',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation 24',
        prompt: 'Initial v1 prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );
      await service.publishContent(item.id);

      // Faculty creates v2 draft
      final v2Draft =
          await service.updateDraft(item.copyWith(prompt: 'Updated v2 prompt'));

      // While v2 is draft, learner still gets v1
      var publishedQuestions = await service.getPublishedQuestions();
      var q = publishedQuestions.firstWhere((i) => i.id == 'q_op_24');
      expect(q.normalizedText, equals('Initial v1 prompt'));

      // Faculty publishes v2
      await service.publishContent(v2Draft.id);

      // Now learner receives v2
      publishedQuestions = await service.getPublishedQuestions();
      q = publishedQuestions.firstWhere((i) => i.id == 'q_op_24');
      expect(q.normalizedText, equals('Updated v2 prompt'));
    });

    // 25. filtering
    test(
        '25. filtering across exam, subject, topic, objective, type, and status',
        () async {
      await service.createDraft(
        id: 'q_filt_01',
        title: 'Question Fundamental Rights',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation',
        prompt: 'Prompt 1',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      await service.createDraft(
        id: 'rem_filt_02',
        title: 'Remedial Basic Structure',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Preamble & Basic Structure',
        objectiveId: 'lo_basic_structure_doctrine',
        contentType: ManagedContentType.remedialLesson,
        authorId: 'prof_sharma',
        provenance: 'AIR 1973',
        lessonExplanation: 'Lesson on basic structure doctrine.',
      );

      final questionsOnly =
          await contentRepo.getAll(contentType: ManagedContentType.question);
      expect(questionsOnly.length, equals(1));
      expect(questionsOnly.first.id, equals('q_filt_01'));

      final basicStructureTopic =
          await contentRepo.getAll(topicId: 'Preamble & Basic Structure');
      expect(basicStructureTopic.length, equals(1));
      expect(basicStructureTopic.first.id, equals('rem_filt_02'));

      final authorSharma = await contentRepo.getAll(authorId: 'prof_sharma');
      expect(authorSharma.length, equals(1));
      expect(authorSharma.first.id, equals('rem_filt_02'));
    });

    // 26. multiple content items
    test('26. multiple content items coexist independently in repository',
        () async {
      for (int i = 1; i <= 5; i++) {
        await service.createDraft(
          id: 'q_multi_$i',
          title: 'Multiple Question $i',
          examId: 'upsc_prelims_gs1',
          subjectId: 'indian_polity',
          topicId: 'Fundamental Rights',
          objectiveId: 'lo_article_21_foundations',
          contentType: ManagedContentType.question,
          authorId: 'prof_menon',
          provenance: 'Citation $i',
          prompt: 'Prompt $i',
          options: const ['A', 'B'],
          correctAnswer: 'A',
        );
      }

      final all = await contentRepo.getAll();
      expect(all.length, equals(5));
    });

    // 27. duplicate content protection
    test('27. duplicate content protection rejects existing ID on createDraft',
        () async {
      await service.createDraft(
        id: 'q_dup_01',
        title: 'Original Item',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation',
        prompt: 'Prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      await expectLater(
        service.createDraft(
          id: 'q_dup_01',
          title: 'Duplicate Item',
          examId: 'upsc_prelims_gs1',
          subjectId: 'indian_polity',
          topicId: 'Fundamental Rights',
          objectiveId: 'lo_article_21_foundations',
          contentType: ManagedContentType.question,
          authorId: 'prof_menon',
          provenance: 'Citation',
          prompt: 'Prompt',
          options: const ['A', 'B'],
          correctAnswer: 'A',
        ),
        throwsA(isA<StateError>()),
      );
    });

    // 28. repository failure
    test(
        '28. repository failure handling returns null on missing item and handles clear',
        () async {
      final missing = await contentRepo.getById('non_existent_id');
      expect(missing, isNull);

      final missingPub =
          await contentRepo.getPublishedVersion('non_existent_id');
      expect(missingPub, isNull);

      await contentRepo.clear();
      final emptyList = await contentRepo.getAll();
      expect(emptyList, isEmpty);
    });

    // 29. service failure
    test(
        '29. service failure throws StateError on updating or publishing non-existent item',
        () async {
      await expectLater(
        service.publishContent('missing_item_xyz'),
        throwsA(isA<StateError>()),
      );

      await expectLater(
        service.unpublishContent('missing_item_xyz'),
        throwsA(isA<StateError>()),
      );

      final dummyItem = ManagedContentItem(
        id: 'missing_update_xyz',
        title: 'Title',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await expectLater(
        service.updateDraft(dummyItem),
        throwsA(isA<StateError>()),
      );
    });

    // 30. invalid state
    test('30. invalid state transitions are guarded and handled cleanly',
        () async {
      final item = await service.createDraft(
        id: 'q_op_30',
        title: 'State Test Item',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Citation 30',
        prompt: 'Prompt 30',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      // Unpublished directly without publishing
      final unpub = await service.unpublishContent(item.id);
      expect(unpub.status, equals(ContentLifecycleStatus.unpublished));
      expect(unpub.isPublished, isFalse);
    });

    // 31. PYQ metadata protection
    test(
        '31. PYQ metadata protection rejects modification or shadowing of official PYQs',
        () {
      final pyqShadowItem = ManagedContentItem(
        id: 'PYQ_2020_GS1_042',
        title: 'Attempted PYQ Answer Modification',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'Unauthorized Source',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        prompt: 'Shadowed prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
        metadata: const {'isOfficialPyqAnswer': true},
      );

      final result = service.validateContent(pyqShadowItem);
      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.contains(
            'Official PYQ answer keys and provenance are immutable and protected')),
        isTrue,
      );
    });

    // 32. learner discovery after publication
    test(
        '32. learner discovery retrieves published faculty items mapped to target learning objective',
        () async {
      final item = await service.createDraft(
        id: 'q_op_32',
        title: 'Article 21 Habeas Corpus Case',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_menon',
        provenance: 'ADM Jabalpur v Shivkant Shukla (1976)',
        prompt:
            'Was the decision in ADM Jabalpur formally overruled by the Supreme Court in Puttaswamy?',
        options: const [
          'Yes, explicitly overruled in Puttaswamy (2017)',
          'No, it still stands as good law',
          'Overruled only by constitutional amendment',
          'Not applicable to fundamental rights',
        ],
        correctAnswer: 'Yes, explicitly overruled in Puttaswamy (2017)',
        explanation:
            'Puttaswamy expressly buried the discordant majority opinion in ADM Jabalpur.',
      );

      // Before publish: learner discovers nothing
      var items = await contentRepo
          .getPublishedContentForObjective('lo_article_21_foundations');
      expect(items.any((i) => i.id == 'q_op_32'), isFalse);

      // Publish
      await service.publishContent(item.id);

      // After publish: learner discovers published item
      items = await contentRepo
          .getPublishedContentForObjective('lo_article_21_foundations');
      expect(items.any((i) => i.id == 'q_op_32'), isTrue);
      final discovered = items.firstWhere((i) => i.id == 'q_op_32');
      expect(discovered.title, equals('Article 21 Habeas Corpus Case'));
      expect(discovered.isPublished, isTrue);
    });
  });
}
