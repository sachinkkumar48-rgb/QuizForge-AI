import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P45 Faculty & Content Management Domain Tests (TITAN-KO-045.0)', () {
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

    // 1. faculty opens content management
    test('1. faculty opens content management service with clean catalogue', () async {
      final items = await service.contentRepository.getAll();
      expect(items, isEmpty);
      expect(service.curriculumService.framework.allObjectives, isNotEmpty);
    });

    // 2. exam selection
    test('2. exam selection maps to valid curriculum framework', () {
      expect(framework.id, equals('titan_upsc_constitutional_law_framework'));
      expect(framework.title, contains('Constitutional Law'));
    });

    // 3. subject selection
    test('3. subject selection resolves curriculum domains', () {
      final domains = framework.domains;
      expect(domains, isNotEmpty);
      expect(domains.first.title, contains('Constitutional'));
    });

    // 4. topic selection
    test('4. topic selection resolves curriculum units', () {
      final units = framework.allUnits;
      expect(units, isNotEmpty);
      expect(units.any((u) => u.title.contains('Fundamental Rights') || u.title.contains('Preamble')), isTrue);
    });

    // 5. objective selection
    test('5. objective selection resolves canonical learning objective', () {
      final obj = curriculumService.getObjectiveById('lo_article_21_foundations');
      expect(obj, isNotNull);
      expect(obj!.id, equals('lo_article_21_foundations'));
    });

    // 6. create content
    test('6. create content produces draft item with version 1', () async {
      final item = await service.createDraft(
        id: 'q_fac_01',
        title: 'Maneka Gandhi Case Principle',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Supreme Court Reports 1978',
        prompt: 'Which doctrine was established in Maneka Gandhi vs Union of India?',
        options: const [
          'Procedure established by law',
          'Due process of law',
          'Doctrine of severability',
          'Pith and substance',
        ],
        correctAnswer: 'Due process of law',
      );

      expect(item.id, equals('q_fac_01'));
      expect(item.status, equals(ContentLifecycleStatus.draft));
      expect(item.version, equals(1));
      expect(item.authorId, equals('prof_sharma'));
    });

    // 7. empty content rejected
    test('7. empty content rejected during validation', () {
      final item = ManagedContentItem(
        id: 'q_empty_01',
        title: '',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Citation',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        prompt: '',
      );

      final result = service.validateContent(item);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('title cannot be empty')), isTrue);
      expect(result.errors.any((e) => e.contains('prompt cannot be empty')), isTrue);
    });

    // 8. invalid mapping rejected
    test('8. invalid mapping rejected when objective does not exist', () {
      final item = ManagedContentItem(
        id: 'q_inv_obj',
        title: 'Invalid Objective Test',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'non_existent_objective_xyz',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Citation',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        prompt: 'Prompt text',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      final result = service.validateContent(item);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('does not exist in curriculum framework')), isTrue);
    });

    // 9. valid content accepted
    test('9. valid content accepted by deterministic validator', () {
      final item = ManagedContentItem(
        id: 'q_valid_01',
        title: 'Valid Article 21 Question',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Indian Constitutional Law 2026',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        prompt: 'Is right to privacy protected under Article 21?',
        options: const ['Yes, affirmed in Puttaswamy', 'No', 'Only partially', 'Depends on statutory law'],
        correctAnswer: 'Yes, affirmed in Puttaswamy',
      );

      final result = service.validateContent(item);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    // 10. save draft
    test('10. save draft stores content in draft state', () async {
      await service.createDraft(
        id: 'rem_draft_01',
        title: 'Basic Structure Concept Summary',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Preamble & Basic Structure',
        objectiveId: 'lo_basic_structure_doctrine',
        contentType: ManagedContentType.remedialLesson,
        authorId: 'prof_sharma',
        provenance: 'AIR 1973 SC 1461',
        summary: 'Kesavananda Bharati judgment essentials.',
        lessonExplanation: 'The Parliament cannot alter the basic structure of the Constitution.',
      );

      final retrieved = await contentRepo.getById('rem_draft_01');
      expect(retrieved, isNotNull);
      expect(retrieved!.isDraft, isTrue);
      expect(retrieved.status, equals(ContentLifecycleStatus.draft));
    });

    // 11. draft visible to faculty
    test('11. draft visible to faculty via repository queries', () async {
      await service.createDraft(
        id: 'q_draft_vis',
        title: 'Draft Question',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'AIR 1978',
        prompt: 'Prompt text',
        options: const ['Opt 1', 'Opt 2'],
        correctAnswer: 'Opt 1',
      );

      final all = await contentRepo.getAll(status: ContentLifecycleStatus.draft);
      expect(all.any((i) => i.id == 'q_draft_vis'), isTrue);
    });

    // 12. draft hidden from learner
    test('12. draft hidden from learner queries', () async {
      await service.createDraft(
        id: 'q_draft_hidden',
        title: 'Draft Hidden',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'AIR 1978',
        prompt: 'Prompt text',
        options: const ['Opt 1', 'Opt 2'],
        correctAnswer: 'Opt 1',
      );

      final publishedVer = await contentRepo.getPublishedVersion('q_draft_hidden');
      expect(publishedVer, isNull);

      final learnerPublished = await contentRepo.getPublishedContentForObjective('lo_article_21_foundations');
      expect(learnerPublished.any((i) => i.id == 'q_draft_hidden'), isFalse);
    });

    // 13. validation failure
    test('13. validation failure marks item status and throws on publish', () async {
      await service.createDraft(
        id: 'q_fail_01',
        title: 'Incomplete Question',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Source',
        prompt: 'Missing options prompt',
        options: const ['Single Option'],
        correctAnswer: 'Single Option',
      );

      await expectLater(
        service.publishContent('q_fail_01'),
        throwsA(isA<StateError>()),
      );

      final item = await contentRepo.getById('q_fail_01');
      expect(item!.status, equals(ContentLifecycleStatus.validationFailed));
      expect(item.validationErrors, isNotEmpty);
    });

    // 14. validation success
    test('14. validation success allows clean publishing', () async {
      await service.createDraft(
        id: 'q_pass_01',
        title: 'Article 21 Core Question',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Constitution of India 2026',
        prompt: 'Which article protects personal liberty?',
        options: const ['Article 19', 'Article 21', 'Article 14', 'Article 32'],
        correctAnswer: 'Article 21',
      );

      final published = await service.publishContent('q_pass_01');
      expect(published.status, equals(ContentLifecycleStatus.published));
      expect(published.validationErrors, isEmpty);
    });

    // 15. preview
    test('15. preview generates valid runtime question representation', () async {
      final draft = await service.createDraft(
        id: 'q_preview_01',
        title: 'Preview Test',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Standard Case Law',
        prompt: 'Sample preview prompt?',
        options: const ['Opt A', 'Opt B'],
        correctAnswer: 'A',
      );

      final normalized = draft.toNormalizedQuestion();
      expect(normalized.id, equals('q_preview_01'));
      expect(normalized.options.length, equals(2));
      expect(normalized.officialAnswer.correctOptionKeys, contains('A'));
    });

    // 16. publish
    test('16. publish transitions status to published', () async {
      await service.createDraft(
        id: 'rem_pub_01',
        title: 'Preamble Identity Micro-Lesson',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Preamble & Basic Structure',
        objectiveId: 'lo_preamble_identity',
        contentType: ManagedContentType.remedialLesson,
        authorId: 'prof_sharma',
        provenance: 'Berubari & Kesavananda cases',
        summary: 'Preamble role in constitutional interpretation.',
        lessonExplanation: 'The Preamble is an integral part of the Constitution.',
      );

      final published = await service.publishContent('rem_pub_01');
      expect(published.isPublished, isTrue);

      final syncedLesson = await remedialRepo.getLesson('rem_pub_01');
      expect(syncedLesson, isNotNull);
      expect(syncedLesson!.title, equals('Preamble Identity Micro-Lesson'));
    });

    // 17. published content visible to learner
    test('17. published content visible to learner query', () async {
      await service.createDraft(
        id: 'q_pub_vis',
        title: 'Published Visible Question',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Constitution of India',
        prompt: 'Prompt for learner',
        options: const ['Option A', 'Option B'],
        correctAnswer: 'Option A',
      );

      await service.publishContent('q_pub_vis');

      final learnerPublished = await contentRepo.getPublishedContentForObjective('lo_article_21_foundations');
      expect(learnerPublished.any((i) => i.id == 'q_pub_vis'), isTrue);
    });

    // 18. unpublish
    test('18. unpublish transitions status and removes from learner sync', () async {
      await service.createDraft(
        id: 'rem_unpub_01',
        title: 'Temporary Lesson',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.remedialLesson,
        authorId: 'prof_sharma',
        provenance: 'Source',
        summary: 'Temporary summary',
        lessonExplanation: 'Temporary explanation',
      );

      await service.publishContent('rem_unpub_01');
      expect(await remedialRepo.getLesson('rem_unpub_01'), isNotNull);

      final unpub = await service.unpublishContent('rem_unpub_01');
      expect(unpub.status, equals(ContentLifecycleStatus.unpublished));
      expect(await remedialRepo.getLesson('rem_unpub_01'), isNull);
    });

    // 19. unpublished content hidden from learner
    test('19. unpublished content hidden from learner query', () async {
      await service.createDraft(
        id: 'q_unpub_02',
        title: 'Question to Unpublish',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Source',
        prompt: 'Prompt',
        options: const ['Opt A', 'Opt B'],
        correctAnswer: 'Opt A',
      );

      await service.publishContent('q_unpub_02');
      await service.unpublishContent('q_unpub_02');

      final learnerList = await contentRepo.getPublishedContentForObjective('lo_article_21_foundations');
      expect(learnerList.any((i) => i.id == 'q_unpub_02'), isFalse);
    });

    // 20. edit published content
    test('20. edit published content creates draft revision without mutating published version', () async {
      await service.createDraft(
        id: 'q_edit_ver',
        title: 'Original Title v1',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Source v1',
        prompt: 'Original prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      final publishedV1 = await service.publishContent('q_edit_ver');
      expect(publishedV1.version, equals(1));
      expect(publishedV1.title, equals('Original Title v1'));

      final draftV2 = await service.updateDraft(
        publishedV1.copyWith(title: 'Edited Title v2'),
      );

      expect(draftV2.version, equals(2));
      expect(draftV2.status, equals(ContentLifecycleStatus.draft));
      expect(draftV2.title, equals('Edited Title v2'));

      // Verify v1 is still published!
      final currentPublished = await contentRepo.getPublishedVersion('q_edit_ver');
      expect(currentPublished!.version, equals(1));
      expect(currentPublished.title, equals('Original Title v1'));
    });

    // 21. version increments
    test('21. version increments monotonically on edits', () async {
      final item = await service.createDraft(
        id: 'item_ver_inc',
        title: 'Version Test',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Source',
        prompt: 'Prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );
      expect(item.version, equals(1));

      await service.publishContent(item.id);
      final v2 = await service.updateDraft(item.copyWith(title: 'Updated Title'));
      expect(v2.version, equals(2));
    });

    // 22. previous version preserved
    test('22. previous version preserved in repository storage', () async {
      await service.createDraft(
        id: 'preserve_test',
        title: 'Preserve v1',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Source',
        prompt: 'Prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );
      await service.publishContent('preserve_test');
      await service.updateDraft(
        (await contentRepo.getById('preserve_test'))!.copyWith(title: 'Preserve v2'),
      );

      final v1 = await contentRepo.getById('preserve_test', version: 1);
      final v2 = await contentRepo.getById('preserve_test', version: 2);

      expect(v1, isNotNull);
      expect(v1!.title, equals('Preserve v1'));
      expect(v2, isNotNull);
      expect(v2!.title, equals('Preserve v2'));
    });

    // 23. publish new version
    test('23. publish new version makes v2 the active published version', () async {
      await service.createDraft(
        id: 'pub_v2_test',
        title: 'Old Title v1',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Source',
        prompt: 'Prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );
      await service.publishContent('pub_v2_test');

      final v2Draft = await service.updateDraft(
        (await contentRepo.getById('pub_v2_test'))!.copyWith(title: 'New Title v2'),
      );
      expect(v2Draft.version, equals(2));

      await service.publishContent('pub_v2_test');

      final currentPublished = await contentRepo.getPublishedVersion('pub_v2_test');
      expect(currentPublished!.version, equals(2));
      expect(currentPublished.title, equals('New Title v2'));
    });

    // 24. learner sees current published version
    test('24. learner sees current published version after publication', () async {
      await service.createDraft(
        id: 'learner_ver_test',
        title: 'Title v1',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.remedialLesson,
        authorId: 'prof_sharma',
        provenance: 'Source',
        summary: 'Summary v1',
        lessonExplanation: 'Explanation v1',
      );
      await service.publishContent('learner_ver_test');

      final v1Lesson = await remedialRepo.getLesson('learner_ver_test');
      expect(v1Lesson!.version, equals(1));

      final v2 = await service.updateDraft(
        (await contentRepo.getById('learner_ver_test'))!.copyWith(summary: 'Summary v2'),
      );
      await service.publishContent(v2.id);

      final v2Lesson = await remedialRepo.getLesson('learner_ver_test');
      expect(v2Lesson!.version, equals(2));
      expect(v2Lesson.summary, equals('Summary v2'));
    });

    // 25. filtering
    test('25. filtering across exam/subject/topic/objective/type/status', () async {
      await service.createDraft(
        id: 'item_f1',
        title: 'Item 1',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'author_a',
        provenance: 'Source',
        prompt: 'P1',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      await service.createDraft(
        id: 'item_f2',
        title: 'Item 2',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Preamble & Basic Structure',
        objectiveId: 'lo_preamble_identity',
        contentType: ManagedContentType.remedialLesson,
        authorId: 'author_b',
        provenance: 'Source',
        summary: 'Summary',
        lessonExplanation: 'Explanation',
      );

      final filteredByTopic = await contentRepo.getAll(topicId: 'Fundamental Rights');
      expect(filteredByTopic.length, equals(1));
      expect(filteredByTopic.first.id, equals('item_f1'));

      final filteredByType = await contentRepo.getAll(contentType: ManagedContentType.remedialLesson);
      expect(filteredByType.length, equals(1));
      expect(filteredByType.first.id, equals('item_f2'));
    });

    // 26. multiple content items
    test('26. multiple content items coexist in repository', () async {
      for (int i = 1; i <= 5; i++) {
        await service.createDraft(
          id: 'multi_q_$i',
          title: 'Question $i',
          examId: 'upsc_prelims_gs1',
          subjectId: 'indian_polity',
          topicId: 'Fundamental Rights',
          objectiveId: 'lo_article_21_foundations',
          contentType: ManagedContentType.question,
          authorId: 'prof_sharma',
          provenance: 'Source $i',
          prompt: 'Prompt $i',
          options: const ['A', 'B'],
          correctAnswer: 'A',
        );
      }

      final all = await contentRepo.getAll();
      expect(all.length, equals(5));
    });

    // 27. duplicate ID protection
    test('27. duplicate ID protection throws StateError on create', () async {
      await service.createDraft(
        id: 'dup_id_01',
        title: 'First Item',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Source',
        prompt: 'Prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      expect(
        () async => await service.createDraft(
          id: 'dup_id_01',
          title: 'Second Item with Same ID',
          examId: 'upsc_prelims_gs1',
          subjectId: 'indian_polity',
          topicId: 'Fundamental Rights',
          objectiveId: 'lo_article_21_foundations',
          contentType: ManagedContentType.question,
          authorId: 'prof_sharma',
          provenance: 'Source',
          prompt: 'Prompt',
          options: const ['A', 'B'],
          correctAnswer: 'A',
        ),
        throwsA(isA<StateError>()),
      );
    });

    // 28. invalid question protection
    test('28. invalid question protection rejects mismatched correct answer', () {
      final item = ManagedContentItem(
        id: 'q_mismatch',
        title: 'Mismatch Test',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Source',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        prompt: 'Prompt',
        options: const ['Apple', 'Banana'],
        correctAnswer: 'Cherry', // Not in options!
      );

      final result = service.validateContent(item);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('does not match any available option')), isTrue);
    });

    // 29. provenance preservation
    test('29. provenance preservation ensures source citation is stored and carried', () async {
      final item = await service.createDraft(
        id: 'q_prov_01',
        title: 'Provenance Item',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'National Law School Case Reporter 2026',
        prompt: 'Prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      final norm = item.toNormalizedQuestion();
      expect(norm.source.sourceTitle, equals('National Law School Case Reporter 2026'));
    });

    // 30. PYQ answer-key protection
    test('30. PYQ answer-key protection prevents faculty from modifying official PYQs', () {
      final item = ManagedContentItem(
        id: 'PYQ_UPSC_2023_GS1_Q01',
        title: 'Overwriting Official PYQ',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'prof_sharma',
        provenance: 'Source',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        prompt: 'Modified PYQ Prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      final result = service.validateContent(item);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('Official PYQ answer keys and provenance are immutable')), isTrue);
    });

    // 31. content retrieval after application restart where supported
    test('31. content retrieval handles serialization roundtrip', () async {
      final original = await service.createDraft(
        id: 'rem_persist_01',
        title: 'Persisted Lesson',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.remedialLesson,
        authorId: 'prof_sharma',
        provenance: 'Source Citation',
        summary: 'Summary text',
        lessonExplanation: 'Explanation text',
        examples: const ['Example 1'],
        misconceptions: const ['Trap 1'],
      );

      final lesson = original.toRemedialLesson();
      final json = lesson.toJson();
      final reconstructed = RemedialLesson.fromJson(json);

      expect(reconstructed.lessonId, equals(original.id));
      expect(reconstructed.title, equals(original.title));
      expect(reconstructed.summary, equals(original.summary));
      expect(reconstructed.examples, equals(original.examples));
    });

    // 32. multi-user/ownership isolation where supported
    test('32. multi-user/ownership isolation tracks distinct author IDs', () async {
      await service.createDraft(
        id: 'author_item_1',
        title: 'Item Author 1',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'faculty_user_1',
        provenance: 'Source',
        prompt: 'Prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      await service.createDraft(
        id: 'author_item_2',
        title: 'Item Author 2',
        examId: 'upsc_prelims_gs1',
        subjectId: 'indian_polity',
        topicId: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
        contentType: ManagedContentType.question,
        authorId: 'faculty_user_2',
        provenance: 'Source',
        prompt: 'Prompt',
        options: const ['A', 'B'],
        correctAnswer: 'A',
      );

      final user1Items = await contentRepo.getAll(authorId: 'faculty_user_1');
      expect(user1Items.length, equals(1));
      expect(user1Items.first.id, equals('author_item_1'));

      final user2Items = await contentRepo.getAll(authorId: 'faculty_user_2');
      expect(user2Items.length, equals(1));
      expect(user2Items.first.id, equals('author_item_2'));
    });

    // 33. service failure
    test('33. service failure handled gracefully when item is non-existent', () async {
      expect(
        () async => await service.publishContent('non_existent_item_id'),
        throwsA(isA<StateError>()),
      );
      expect(
        () async => await service.unpublishContent('non_existent_item_id'),
        throwsA(isA<StateError>()),
      );
    });

    // 34. repository failure
    test('34. repository failure resilience handles clear and empty lookups', () async {
      await contentRepo.clear();
      expect(await contentRepo.getById('any_id'), isNull);
      expect(await contentRepo.getPublishedVersion('any_id'), isNull);
      expect(await contentRepo.getAll(), isEmpty);
    });

    // 35. empty catalogue
    test('35. empty catalogue handles queries without errors', () async {
      final items = await service.getPublishedQuestions(topicName: 'Fundamental Rights');
      expect(items, isEmpty);
      final lessons = await remedialRepo.getLessonsForObjective('lo_article_21_foundations');
      expect(lessons, isEmpty);
    });
  });
}
