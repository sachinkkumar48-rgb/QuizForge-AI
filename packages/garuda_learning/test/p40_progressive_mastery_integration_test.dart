/// P40 Progressive Mastery Engine End-to-End Integration Test (TITAN-KO-040.0 P40).
///
/// Exercises the complete flow:
/// Practice Execution Outcomes
///   ↓
/// Authoritative Learner State Persistence (P39)
///   ↓
/// Progressive Mastery Engine Evaluation (P40)
///   ↓
/// Topic Mastery Profiles with Explainability
///   ↓
/// Adaptive Decision Output
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P40 Progressive Mastery Engine End-to-End Integration Flow', () {
    final fixedTime = DateTime.utc(2026, 9, 21, 14, 0, 0);

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late ProgressiveMasteryEngine masteryEngine;

    setUp(() {
      authRepo = InMemoryAuthoritativeLearningStateRepository();

      masteryEngine = ProgressiveMasteryEngine(
        config: MasteryEngineConfig.validated(
          initialMastery: 0.15,
          correctIncrement: 0.12,
          incorrectDecrement: 0.10,
          minEvidenceForProficiency: 3,
          minEvidenceForMastery: 5,
        ),
      );
    });

    PracticeQuestionEvidence makeQuestionEvidence({
      required String questionId,
      required String topic,
      required String objectiveId,
      required String difficulty,
      required bool isCorrect,
      int elapsedSeconds = 45,
    }) {
      return PracticeQuestionEvidence(
        questionId: questionId,
        examId: 'upsc',
        subject: 'General Studies',
        topic: topic,
        objectiveIds: [objectiveId],
        difficulty: difficulty,
        questionIndex: 0,
        status: isCorrect
            ? PracticeQuestionStatus.answeredCorrect
            : PracticeQuestionStatus.answeredIncorrect,
        correctAnswer: 'A',
        submittedAnswer: isCorrect ? 'A' : 'B',
        isCorrect: isCorrect,
        isAnswered: true,
        isSkipped: false,
        elapsedSeconds: elapsedSeconds,
        answeredAt: fixedTime,
        feedbackPolicy: PracticeFeedbackPolicy.immediate,
        isExplanationExposed: true,
        evaluationMethod: EvaluationMethod.multipleChoice,
      );
    }

    test(
        'executes complete path: practice outcomes -> authoritative state -> mastery profiles -> adaptive decisions',
        () async {
      const learnerId = 'learner_mastery_e2e';
      const examId = 'upsc';

      // 1. Generate multi-topic practice evidence
      // Topic 1: 'Preamble & Rights' (Strong performance: 5 Hard/Medium questions correct)
      // Topic 2: 'Modern History' (Struggling: 3 Easy questions incorrect)
      // Topic 3: 'Physical Geography' (1 Medium correct - insufficient evidence)
      final questionEvidenceList = <PracticeQuestionEvidence>[
        // Preamble & Rights: 5 correct
        makeQuestionEvidence(
          questionId: 'q_pol_1',
          topic: 'Preamble & Rights',
          objectiveId: 'lo_pol_preamble',
          difficulty: 'Medium',
          isCorrect: true,
        ),
        makeQuestionEvidence(
          questionId: 'q_pol_2',
          topic: 'Preamble & Rights',
          objectiveId: 'lo_pol_preamble',
          difficulty: 'Hard',
          isCorrect: true,
        ),
        makeQuestionEvidence(
          questionId: 'q_pol_3',
          topic: 'Preamble & Rights',
          objectiveId: 'lo_pol_fr',
          difficulty: 'Hard',
          isCorrect: true,
        ),
        makeQuestionEvidence(
          questionId: 'q_pol_4',
          topic: 'Preamble & Rights',
          objectiveId: 'lo_pol_fr',
          difficulty: 'Medium',
          isCorrect: true,
        ),
        makeQuestionEvidence(
          questionId: 'q_pol_5',
          topic: 'Preamble & Rights',
          objectiveId: 'lo_pol_dpsp',
          difficulty: 'Hard',
          isCorrect: true,
        ),

        // Modern History: 3 incorrect
        makeQuestionEvidence(
          questionId: 'q_hist_1',
          topic: 'Modern History',
          objectiveId: 'lo_hist_revolt',
          difficulty: 'Easy',
          isCorrect: false,
        ),
        makeQuestionEvidence(
          questionId: 'q_hist_2',
          topic: 'Modern History',
          objectiveId: 'lo_hist_revolt',
          difficulty: 'Easy',
          isCorrect: false,
        ),
        makeQuestionEvidence(
          questionId: 'q_hist_3',
          topic: 'Modern History',
          objectiveId: 'lo_hist_inc',
          difficulty: 'Easy',
          isCorrect: false,
        ),

        // Physical Geography: 1 correct
        makeQuestionEvidence(
          questionId: 'q_geo_1',
          topic: 'Physical Geography',
          objectiveId: 'lo_geo_monsoon',
          difficulty: 'Medium',
          isCorrect: true,
        ),
      ];

      // 2. Persist AuthoritativeLearnerState with objective progress records
      final authState = AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        progressMap: {
          'lo_pol_preamble': LearnerProgress(
            learnerId: learnerId,
            objectiveId: 'lo_pol_preamble',
            attemptCount: 2,
            correctCount: 2,
            lastAttemptAt: fixedTime,
            status: LearnerObjectiveStatus.achieved,
          ),
          'lo_pol_fr': LearnerProgress(
            learnerId: learnerId,
            objectiveId: 'lo_pol_fr',
            attemptCount: 2,
            correctCount: 2,
            lastAttemptAt: fixedTime,
            status: LearnerObjectiveStatus.achieved,
          ),
          'lo_pol_dpsp': LearnerProgress(
            learnerId: learnerId,
            objectiveId: 'lo_pol_dpsp',
            attemptCount: 1,
            correctCount: 1,
            lastAttemptAt: fixedTime,
            status: LearnerObjectiveStatus.inProgress,
          ),
          'lo_hist_revolt': LearnerProgress(
            learnerId: learnerId,
            objectiveId: 'lo_hist_revolt',
            attemptCount: 2,
            correctCount: 0,
            lastAttemptAt: fixedTime,
            status: LearnerObjectiveStatus.inProgress,
          ),
          'lo_hist_inc': LearnerProgress(
            learnerId: learnerId,
            objectiveId: 'lo_hist_inc',
            attemptCount: 1,
            correctCount: 0,
            lastAttemptAt: fixedTime,
            status: LearnerObjectiveStatus.inProgress,
          ),
          'lo_geo_monsoon': LearnerProgress(
            learnerId: learnerId,
            objectiveId: 'lo_geo_monsoon',
            attemptCount: 1,
            correctCount: 1,
            lastAttemptAt: fixedTime,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
        processedSessionIds: {'sess_mastery_01'},
        lastUpdatedAt: fixedTime,
        revision: 2,
      );

      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(
          authState,
          revision: 2,
        ),
      );

      // Verify Authoritative state was loaded and persisted cleanly
      final loadedState =
          await authRepo.load(learnerId: learnerId, examId: examId);
      expect(loadedState, isNotNull);
      expect(loadedState!.revision, 2);

      // 3. Path A: Evaluate Progressive Mastery directly from AuthoritativeLearnerState
      final snapshotFromAuth = masteryEngine.evaluateFromAuthoritativeState(
        authoritativeState: loadedState.toAuthoritativeState(),
        objectiveToTopicsMap: {
          'lo_pol_preamble': ['Preamble & Rights'],
          'lo_pol_fr': ['Preamble & Rights'],
          'lo_pol_dpsp': ['Preamble & Rights'],
          'lo_hist_revolt': ['Modern History'],
          'lo_hist_inc': ['Modern History'],
          'lo_geo_monsoon': ['Physical Geography'],
        },
        evaluatedAt: fixedTime,
      );

      expect(snapshotFromAuth.learnerId, learnerId);
      expect(snapshotFromAuth.examId, examId);
      expect(snapshotFromAuth.authoritativeRevision, 2);
      expect(snapshotFromAuth.topicProfiles.length, 3);
      expect(snapshotFromAuth.verifyChecksum(), isTrue);

      // 4. Path B: Evaluate Progressive Mastery from question-level execution evidence
      final snapshotFromEvidence = masteryEngine.evaluateFromQuestionEvidence(
        learnerId: learnerId,
        examId: examId,
        questionEvidence: questionEvidenceList,
        authoritativeRevision: loadedState.revision,
        evaluatedAt: fixedTime,
      );

      expect(snapshotFromEvidence.topicProfiles.length, 3);
      expect(snapshotFromEvidence.verifyChecksum(), isTrue);

      // 5. Verify Preamble & Rights (Strong Topic)
      final polProfile =
          snapshotFromEvidence.topicProfiles['Preamble & Rights']!;
      expect(polProfile.evidenceCount, 5);
      expect(polProfile.correctCount, 5);
      expect(polProfile.incorrectCount, 0);
      expect(polProfile.recentAccuracy, 1.0);
      expect(polProfile.masteryScore, greaterThan(0.55));
      expect(polProfile.confidence, greaterThan(0.45));
      expect(
          polProfile.classification,
          anyOf(MasteryClassification.developing,
              MasteryClassification.proficient));
      expect(polProfile.explanation, contains('Mastery updated'));

      // 6. Verify Modern History (Struggling Topic)
      final histProfile = snapshotFromEvidence.topicProfiles['Modern History']!;
      expect(histProfile.evidenceCount, 3);
      expect(histProfile.correctCount, 0);
      expect(histProfile.incorrectCount, 3);
      expect(histProfile.recentAccuracy, 0.0);
      expect(histProfile.masteryScore, equals(0.0));
      expect(histProfile.classification, MasteryClassification.emerging);

      // 7. Verify Physical Geography (Insufficient Evidence)
      final geoProfile =
          snapshotFromEvidence.topicProfiles['Physical Geography']!;
      expect(geoProfile.evidenceCount, 1);
      expect(geoProfile.correctCount, 1);

      // 8. Verify Adaptive Decision Signals
      final decisions = snapshotFromEvidence.decisionOutput;
      expect(decisions.weakestTopics.first, 'Modern History');
      expect(decisions.strongestTopics.first, 'Preamble & Rights');
      expect(decisions.remediationRequiredTopics, contains('Modern History'));
      expect(
          decisions.insufficientEvidenceTopics, contains('Physical Geography'));

      // Recommended Difficulty Bands
      expect(decisions.recommendedDifficultyBand['Modern History'], 'Easy');
      expect(decisions.recommendedDifficultyBand['Preamble & Rights'],
          anyOf('Medium', 'Hard'));
      expect(
          decisions.recommendedDifficultyBand['Physical Geography'], 'Medium');

      // Overall Metrics
      expect(decisions.overallMasteryScore, greaterThan(0.0));
      expect(decisions.overallConfidence, greaterThan(0.0));
      expect(decisions.masteryDistribution.isNotEmpty, isTrue);
    });
  });
}
