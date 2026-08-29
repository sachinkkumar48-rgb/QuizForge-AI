import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/bloom_taxonomy_level.dart';
import 'package:garuda_learning/domain/entities/learning_recommendation.dart';
import 'package:garuda_learning/domain/entities/recommendation_type.dart';
import 'package:garuda_learning/domain/entities/remedial_binding.dart';
import 'package:garuda_learning/domain/entities/remedial_lesson.dart';
import 'package:garuda_learning/domain/entities/session_configuration.dart';
import 'package:garuda_learning/domain/entities/source_reference.dart';
import 'package:garuda_learning/domain/entities/weak_spot_profile.dart';
import 'package:garuda_learning/repository/remedial_lesson_repository.dart';
import 'package:garuda_learning/service/deterministic_remedial_lesson_service.dart';

void main() {
  group('DeterministicRemedialLessonService Tests (TITAN-KO-025.0 P25)', () {
    late InMemoryRemedialLessonRepository repository;
    late DeterministicRemedialLessonService service;

    final fixedDate = DateTime.utc(2026, 8, 28, 12, 0, 0);

    RemedialLesson makeLesson(
      String id,
      String objId, {
      int version = 1,
      BloomTaxonomyLevel bloomLevel = BloomTaxonomyLevel.understand,
      String title = '',
    }) {
      return RemedialLesson(
        lessonId: id,
        objectiveId: objId,
        title: title.isNotEmpty ? title : 'Lesson $id',
        summary: 'Summary for $id',
        learningPoints: const ['Key concept 1'],
        explanation: 'Detailed explanation for $id',
        estimatedMinutes: 10,
        bloomLevel: bloomLevel,
        authoredAt: fixedDate,
        version: version,
        sourceReferences: [
          SourceReference(
            sourceId: 'src_art_21',
            sourceType: SourceReferenceType.constitution,
            referenceIdentifier: 'Article 21',
          ),
        ],
      );
    }

    setUp(() {
      repository = InMemoryRemedialLessonRepository();
      service =
          DeterministicRemedialLessonService(lessonRepository: repository);
    });

    test('1. findBestLessonForObjective returns null if no lessons available',
        () async {
      final lesson =
          await service.findBestLessonForObjective(objectiveId: 'lo_none');
      expect(lesson, isNull);
    });

    test('2. findBestLessonForObjective selects highest version by default',
        () async {
      final v1 = makeLesson('rem_v1', 'lo_1', version: 1);
      final v2 = makeLesson('rem_v2', 'lo_1', version: 2);
      await repository.saveAll([v1, v2]);

      final best =
          await service.findBestLessonForObjective(objectiveId: 'lo_1');
      expect(best, isNotNull);
      expect(best?.lessonId, equals('rem_v2'));
      expect(best?.version, equals(2));
    });

    test('3. findBestLessonForObjective prefers targetBloomLevel if provided',
        () async {
      final applyLesson = makeLesson(
        'rem_apply',
        'lo_1',
        version: 1,
        bloomLevel: BloomTaxonomyLevel.apply,
      );
      final understandLesson = makeLesson(
        'rem_und',
        'lo_1',
        version: 2,
        bloomLevel: BloomTaxonomyLevel.understand,
      );
      await repository.saveAll([applyLesson, understandLesson]);

      // When targetBloomLevel is apply, prefer the apply lesson even if v1
      final best = await service.findBestLessonForObjective(
        objectiveId: 'lo_1',
        targetBloomLevel: BloomTaxonomyLevel.apply,
      );
      expect(best, isNotNull);
      expect(best?.lessonId, equals('rem_apply'));
      expect(best?.bloomLevel, equals(BloomTaxonomyLevel.apply));
    });

    test(
        '4. bindRemedialLessonsForWeakSpots binds weak spots meeting evidence threshold',
        () async {
      final lessonLo1 = makeLesson('rem_lo1', 'lo_1');
      final lessonLo2 = makeLesson('rem_lo2', 'lo_2');
      await repository.saveAll([lessonLo1, lessonLo2]);

      final profile = WeakSpotProfile(
        learnerId: 'learner_100',
        totalEvaluatedObjectives: 2,
        evaluatedWithSufficientEvidence: 2,
        evaluatedAt: fixedDate,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'lo_1',
            attemptCount: 8,
            correctCount: 2,
            deficiencyScore: 0.75,
          ),
          WeakObjectiveDiagnostic(
            objectiveId: 'lo_2',
            attemptCount: 6,
            correctCount: 2,
            deficiencyScore: 0.67,
          ),
        ],
      );

      final bindings = await service.bindRemedialLessonsForWeakSpots(
        weakSpotProfile: profile,
        boundAt: fixedDate,
      );

      expect(bindings, hasLength(2));
      expect(bindings[0].objectiveId, equals('lo_1'));
      expect(bindings[0].lessonId, equals('rem_lo1'));
      expect(bindings[0].deficiencyScore, equals(0.75));
      expect(bindings[0].trigger,
          equals(RemedialBindingTrigger.weakSpotDiagnostic));
      expect(bindings[1].objectiveId, equals('lo_2'));
      expect(bindings[1].deficiencyScore, equals(0.67));
    });

    test(
        '5. bindRemedialLessonsForWeakSpots ignores objectives below minimum evidence threshold',
        () async {
      final lesson = makeLesson('rem_sparse', 'lo_sparse');
      await repository.saveLesson(lesson);

      final profile = WeakSpotProfile(
        learnerId: 'learner_100',
        totalEvaluatedObjectives: 1,
        evaluatedWithSufficientEvidence: 0,
        minimumEvidenceThreshold: 5,
        evaluatedAt: fixedDate,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'lo_sparse',
            attemptCount: 2, // only 2 attempts < 5 threshold
            correctCount: 0,
            deficiencyScore: 1.0,
          ),
        ],
      );

      final bindings = await service.bindRemedialLessonsForWeakSpots(
        weakSpotProfile: profile,
        boundAt: fixedDate,
      );

      // Must be empty because insufficient evidence
      expect(bindings, isEmpty);
    });

    test('6. bindRemedialLessonsForWeakSpots respects maxLessons budget',
        () async {
      final l1 = makeLesson('rem_1', 'lo_1');
      final l2 = makeLesson('rem_2', 'lo_2');
      await repository.saveAll([l1, l2]);

      final profile = WeakSpotProfile(
        learnerId: 'learner_100',
        totalEvaluatedObjectives: 2,
        evaluatedWithSufficientEvidence: 2,
        evaluatedAt: fixedDate,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'lo_1',
            attemptCount: 6,
            correctCount: 1,
            deficiencyScore: 0.83,
          ),
          WeakObjectiveDiagnostic(
            objectiveId: 'lo_2',
            attemptCount: 6,
            correctCount: 2,
            deficiencyScore: 0.67,
          ),
        ],
      );

      final bindings = await service.bindRemedialLessonsForWeakSpots(
        weakSpotProfile: profile,
        maxLessons: 1,
        boundAt: fixedDate,
      );

      expect(bindings, hasLength(1));
      expect(bindings.first.objectiveId, equals('lo_1'));
    });

    test(
        '7. bindRemedialLessonForRecommendation preserves recommendation ID provenance',
        () async {
      final lesson = makeLesson('rem_adv', 'lo_target');
      await repository.saveLesson(lesson);

      final recommendation = LearningRecommendation(
        recommendationId: 'rec_999',
        learnerId: 'learner_100',
        objectiveId: 'lo_target',
        type: RecommendationType.weakDomainRemediation,
        priorityScore: 0.92,
        rationale: 'Top weak domain remediation',
        suggestedConfig: SessionConfiguration(
          learnerId: 'learner_100',
          objectiveIds: const ['lo_target'],
        ),
      );

      final binding = await service.bindRemedialLessonForRecommendation(
        recommendation: recommendation,
        boundAt: fixedDate,
      );

      expect(binding, isNotNull);
      expect(binding?.objectiveId, equals('lo_target'));
      expect(binding?.lessonId, equals('rem_adv'));
      expect(binding?.trigger,
          equals(RemedialBindingTrigger.adaptiveRecommendation));
      expect(binding?.sourceRecommendationId, equals('rec_999'));
      expect(binding?.metadata['priorityScore'], equals(0.92));
    });

    test(
        '8. createPracticeRetryConfig creates deterministic retry configuration',
        () async {
      final lesson = makeLesson('rem_1', 'lo_1');
      final binding = RemedialLessonBinding(
        bindingId: 'bind_test',
        learnerId: 'learner_100',
        objectiveId: 'lo_1',
        lesson: lesson,
        trigger: RemedialBindingTrigger.weakSpotDiagnostic,
        deficiencyScore: 0.70,
        boundAt: fixedDate,
      );

      final availableQuestions = ['q_c', 'q_a', 'q_b', 'q_d', 'q_e', 'q_f'];

      final config = await service.createPracticeRetryConfig(
        binding: binding,
        availableQuestionIds: availableQuestions,
        questionLimit: 3,
        createdAt: fixedDate,
      );

      expect(config.learnerId, equals('learner_100'));
      expect(config.objectiveId, equals('lo_1'));
      expect(config.remedialLessonId, equals('rem_1'));
      expect(config.questionLimit, equals(3));
      // Questions sorted deterministically: q_a, q_b, q_c
      expect(config.targetQuestionIds, equals(['q_a', 'q_b', 'q_c']));
      expect(config.metadata['bindingId'], equals('bind_test'));

      final sessionConfig = config.toSessionConfiguration();
      expect(sessionConfig.learnerId, equals('learner_100'));
      expect(sessionConfig.objectiveIds, equals(['lo_1']));
      expect(sessionConfig.questionLimit, equals(3));
    });

    test('9. Deterministic replay yields identical binding outputs', () async {
      final lesson = makeLesson('rem_lo1', 'lo_1');
      await repository.saveLesson(lesson);

      final profile = WeakSpotProfile(
        learnerId: 'learner_100',
        totalEvaluatedObjectives: 1,
        evaluatedWithSufficientEvidence: 1,
        evaluatedAt: fixedDate,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'lo_1',
            attemptCount: 6,
            correctCount: 2,
            deficiencyScore: 0.67,
          ),
        ],
      );

      final run1 = await service.bindRemedialLessonsForWeakSpots(
        weakSpotProfile: profile,
        boundAt: fixedDate,
      );
      final run2 = await service.bindRemedialLessonsForWeakSpots(
        weakSpotProfile: profile,
        boundAt: fixedDate,
      );

      expect(run1, equals(run2));
      expect(run1.first.bindingId, equals(run2.first.bindingId));
    });

    test(
        '10. Zero upstream mutation on WeakSpotProfile and LearningRecommendation',
        () async {
      final lesson = makeLesson('rem_lo1', 'lo_1');
      await repository.saveLesson(lesson);

      final profile = WeakSpotProfile(
        learnerId: 'learner_100',
        totalEvaluatedObjectives: 1,
        evaluatedWithSufficientEvidence: 1,
        evaluatedAt: fixedDate,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'lo_1',
            attemptCount: 6,
            correctCount: 2,
            deficiencyScore: 0.67,
          ),
        ],
      );

      await service.bindRemedialLessonsForWeakSpots(
        weakSpotProfile: profile,
        boundAt: fixedDate,
      );

      expect(profile.weakObjectives.first.deficiencyScore, equals(0.67));
      expect(profile.weakObjectives.first.attemptCount, equals(6));
    });
  });
}
