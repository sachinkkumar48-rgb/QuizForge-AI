import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/bloom_taxonomy_level.dart';
import 'package:garuda_learning/domain/entities/content_origin.dart';
import 'package:garuda_learning/domain/entities/learner_objective_status.dart';
import 'package:garuda_learning/domain/entities/learner_progress.dart';
import 'package:garuda_learning/domain/entities/learning_objective.dart';
import 'package:garuda_learning/domain/entities/learning_recommendation.dart';
import 'package:garuda_learning/domain/entities/question_selection_policy.dart';
import 'package:garuda_learning/domain/entities/question_sequencer_policy.dart';
import 'package:garuda_learning/domain/entities/recommendation_type.dart';
import 'package:garuda_learning/domain/entities/remedial_binding.dart';
import 'package:garuda_learning/domain/entities/remedial_lesson.dart';
import 'package:garuda_learning/domain/entities/session_configuration.dart';
import 'package:garuda_learning/domain/entities/source_reference.dart';
import 'package:garuda_learning/domain/entities/weak_spot_profile.dart';
import 'package:garuda_learning/repository/remedial_lesson_repository.dart';
import 'package:garuda_learning/service/deterministic_remedial_lesson_service.dart';

void main() {
  group('P25 Remedial Study End-to-End Integration Tests (TITAN-KO-025.0)', () {
    final fixedTime = DateTime.utc(2026, 8, 28, 14, 0, 0);

    test(
        'Full multi-tier integration from P18/P23 struggle -> P25 RemedialLesson -> P19 Practice Retry',
        () async {
      // 1. P17 Learning Objective
      final objective = LearningObjective(
        id: 'lo_const_art21',
        unitId: 'unit_fundamental_rights',
        title: 'Right to Life and Personal Liberty',
        description:
            'Substantive due process, procedure established by law, and expansive rights under Article 21.',
        bloomLevel: BloomTaxonomyLevel.analyze,
        provenance: 'test_p17',
      );
      expect(objective.id, equals('lo_const_art21'));

      // 2. P18 Learner Progress: Learner struggled with accuracy 33% over 6 attempts
      final progress = LearnerProgress(
        learnerId: 'learner_aspirant_42',
        objectiveId: 'lo_const_art21',
        attemptCount: 6,
        correctCount: 2,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: fixedTime,
      );

      // 3. P23 Weak-Spot Profile: Diagnosed with deficiency score 0.67
      final weakSpotProfile = WeakSpotProfile(
        learnerId: 'learner_aspirant_42',
        totalEvaluatedObjectives: 1,
        evaluatedWithSufficientEvidence: 1,
        minimumEvidenceThreshold: 5,
        evaluatedAt: fixedTime,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'lo_const_art21',
            attemptCount: 6,
            correctCount: 2,
            observedAccuracy: 0.333,
            deficiencyScore: 0.667,
            bloomLevel: BloomTaxonomyLevel.analyze,
          ),
        ],
      );

      // 4. P21 Adaptive Recommendation: Weak domain remediation
      final recommendation = LearningRecommendation(
        recommendationId: 'rec_art21_remedy',
        learnerId: 'learner_aspirant_42',
        objectiveId: 'lo_const_art21',
        type: RecommendationType.weakDomainRemediation,
        priorityScore: 0.94,
        rationale:
            'Observed struggle on Article 21 requires structured remedial review before retry',
        suggestedConfig: SessionConfiguration(
          learnerId: 'learner_aspirant_42',
          objectiveIds: const ['lo_const_art21'],
        ),
      );

      // 5. P25 Remedial Lesson with verified Primary Source Reference
      final sourceRef = SourceReference(
        sourceId: 'doc_const_art21',
        sourceType: SourceReferenceType.constitution,
        referenceIdentifier: 'Article 21, Constitution of India',
        pageNumber: 24,
        excerptText:
            'No person shall be deprived of his life or personal liberty except according to procedure established by law.',
        documentUri: 'titan://reader/doc_const_art21#page=24',
      );

      final caseLawRef = SourceReference(
        sourceId: 'case_maneka_gandhi',
        sourceType: SourceReferenceType.caseLaw,
        referenceIdentifier: 'Maneka Gandhi v. Union of India (1978) 1 SCC 248',
        pageNumber: 248,
        excerptText:
            'Procedure under Article 21 must be right, just, and fair and not arbitrary, fanciful or oppressive.',
        documentUri: 'titan://reader/case_maneka_gandhi#p=248',
      );

      final remedialLesson = RemedialLesson(
        lessonId: 'rem_lo_const_art21_v1',
        objectiveId: 'lo_const_art21',
        title: 'Article 21: Expanding the Ambit of Personal Liberty',
        summary:
            'Understanding the shift from AK Gopalan to Maneka Gandhi doctrine.',
        learningPoints: const [
          'Procedure established by law vs Due Process of Law',
          'Interconnection of Articles 14, 19, and 21 (The Golden Triangle)',
          'Substantive reasonableness requirement under Maneka Gandhi',
        ],
        explanation:
            'In AK Gopalan (1950), the Supreme Court adopted a narrow literal interpretation of procedure established by law. In Maneka Gandhi (1978), this was overturned...',
        examples: const [
          'Right to clean environment (MC Mehta cases)',
          'Right to privacy (KS Puttaswamy judgment)',
        ],
        misconceptions: const [
          'Confusing British procedure established by law with American due process without noting Indian synthesis',
          'Believing Article 21 operates in isolation without Articles 14 and 19',
        ],
        sourceReferences: [sourceRef, caseLawRef],
        contentOrigin: ContentOrigin.pedagogicalExplanation,
        estimatedMinutes: 15,
        bloomLevel: BloomTaxonomyLevel.analyze,
        authoredAt: fixedTime,
      );

      // 6. Setup P25 Repository and Service
      final repository = InMemoryRemedialLessonRepository();
      await repository.saveLesson(remedialLesson);

      final service =
          DeterministicRemedialLessonService(lessonRepository: repository);

      // 7. Bind Remedial Lesson for P23 Weak Spot
      final weakSpotBindings = await service.bindRemedialLessonsForWeakSpots(
        weakSpotProfile: weakSpotProfile,
        boundAt: fixedTime,
      );

      expect(weakSpotBindings, hasLength(1));
      final binding = weakSpotBindings.first;
      expect(binding.learnerId, equals('learner_aspirant_42'));
      expect(binding.objectiveId, equals('lo_const_art21'));
      expect(binding.lessonId, equals('rem_lo_const_art21_v1'));
      expect(binding.lessonTitle, contains('Expanding the Ambit'));
      expect(binding.deficiencyScore, closeTo(0.667, 0.001));
      expect(
          binding.trigger, equals(RemedialBindingTrigger.weakSpotDiagnostic));
      expect(binding.lesson.sourceReferences, hasLength(2));
      expect(binding.lesson.sourceReferences[0].sourceType,
          equals(SourceReferenceType.constitution));
      expect(binding.lesson.sourceReferences[1].sourceType,
          equals(SourceReferenceType.caseLaw));

      // 8. Bind Remedial Lesson for P21 Recommendation (Preserving provenance)
      final recBinding = await service.bindRemedialLessonForRecommendation(
        recommendation: recommendation,
        boundAt: fixedTime,
      );

      expect(recBinding, isNotNull);
      expect(recBinding?.sourceRecommendationId, equals('rec_art21_remedy'));
      expect(recBinding?.trigger,
          equals(RemedialBindingTrigger.adaptiveRecommendation));

      // 9. Generate Targeted Practice Retry Configuration
      final availableQuestions = [
        'pyq_upsc_2023_art21_q1',
        'pyq_upsc_2021_art21_q2',
        'pyq_upsc_2019_art21_q3',
        'pyq_upsc_2018_art21_q4',
      ];

      final retryConfig = await service.createPracticeRetryConfig(
        binding: binding,
        availableQuestionIds: availableQuestions,
        questionLimit: 3,
        createdAt: fixedTime,
      );

      expect(retryConfig.learnerId, equals('learner_aspirant_42'));
      expect(retryConfig.objectiveId, equals('lo_const_art21'));
      expect(retryConfig.remedialLessonId, equals('rem_lo_const_art21_v1'));
      expect(retryConfig.questionLimit, equals(3));
      // First 3 lexically sorted questions
      expect(
          retryConfig.targetQuestionIds,
          equals([
            'pyq_upsc_2018_art21_q4',
            'pyq_upsc_2019_art21_q3',
            'pyq_upsc_2021_art21_q2',
          ]));

      // 10. Bridge to P19 SessionConfiguration
      final sessionConfig = retryConfig.toSessionConfiguration(
        selectionPolicy: QuestionSelectionPolicy.incorrectFocus,
        sequencerPolicy: QuestionSequencerPolicy.difficultyAscending,
      );

      expect(sessionConfig.learnerId, equals('learner_aspirant_42'));
      expect(sessionConfig.objectiveIds, equals(['lo_const_art21']));
      expect(sessionConfig.questionLimit, equals(3));
      expect(sessionConfig.selectionPolicy,
          equals(QuestionSelectionPolicy.incorrectFocus));
      expect(sessionConfig.sequencerPolicy,
          equals(QuestionSequencerPolicy.difficultyAscending));

      // 11. Verify Zero Upstream Mutation
      expect(progress.attemptCount, equals(6));
      expect(progress.status, equals(LearnerObjectiveStatus.inProgress));
      expect(weakSpotProfile.identifiedWeakSpotsCount, equals(1));
      expect(weakSpotProfile.weakObjectives.first.deficiencyScore,
          closeTo(0.667, 0.001));
      expect(recommendation.priorityScore, equals(0.94));
    });
  });
}
