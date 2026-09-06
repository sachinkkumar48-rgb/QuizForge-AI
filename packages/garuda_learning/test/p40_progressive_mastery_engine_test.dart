/// P40 Progressive Mastery Engine Comprehensive Unit Tests (TITAN-KO-040.0 P40).
///
/// Exercises configuration validation, evidence processing, progressive mastery calculation,
/// difficulty & recency weighting, multi-topic aggregation, tenant isolation, explainability,
/// and deterministic serialization.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final fixedBaseTime = DateTime.utc(2026, 9, 20, 10, 0, 0);

  group('Group 1: Mastery Configuration Validation', () {
    test('valid default configuration constructs cleanly', () {
      final config = MasteryEngineConfig.validated();
      expect(config.initialMastery, 0.15);
      expect(config.minMastery, 0.0);
      expect(config.maxMastery, 1.0);
      expect(config.correctIncrement, 0.10);
      expect(config.incorrectDecrement, 0.12);
      expect(config.easyDifficultyWeight, 0.8);
      expect(config.mediumDifficultyWeight, 1.0);
      expect(config.hardDifficultyWeight, 1.3);
      expect(config.emergingThreshold, 0.25);
      expect(config.developingThreshold, 0.50);
      expect(config.proficientThreshold, 0.75);
      expect(config.masteredThreshold, 0.90);
    });

    test('rejects inverted minMastery >= maxMastery', () {
      expect(
        () => MasteryEngineConfig.validated(minMastery: 1.0, maxMastery: 0.5),
        throwsA(isA<InvalidMasteryConfigurationException>()),
      );
    });

    test('rejects initialMastery outside [minMastery, maxMastery]', () {
      expect(
        () => MasteryEngineConfig.validated(initialMastery: 1.2),
        throwsA(isA<InvalidMasteryConfigurationException>()),
      );
      expect(
        () => MasteryEngineConfig.validated(initialMastery: -0.1),
        throwsA(isA<InvalidMasteryConfigurationException>()),
      );
    });

    test('rejects negative or zero correctIncrement / incorrectDecrement', () {
      expect(
        () => MasteryEngineConfig.validated(correctIncrement: 0.0),
        throwsA(isA<InvalidMasteryConfigurationException>()),
      );
      expect(
        () => MasteryEngineConfig.validated(incorrectDecrement: -0.05),
        throwsA(isA<InvalidMasteryConfigurationException>()),
      );
    });

    test('rejects invalid difficulty weights', () {
      expect(
        () => MasteryEngineConfig.validated(easyDifficultyWeight: 0.0),
        throwsA(isA<InvalidMasteryConfigurationException>()),
      );
      expect(
        () => MasteryEngineConfig.validated(
          easyDifficultyWeight: 1.5,
          hardDifficultyWeight: 1.0,
        ),
        throwsA(isA<InvalidMasteryConfigurationException>()),
      );
    });

    test('rejects non-ascending classification thresholds', () {
      expect(
        () => MasteryEngineConfig.validated(
          emergingThreshold: 0.60,
          developingThreshold: 0.40,
        ),
        throwsA(isA<InvalidMasteryConfigurationException>()),
      );
      expect(
        () => MasteryEngineConfig.validated(
          proficientThreshold: 0.95,
          masteredThreshold: 0.90,
        ),
        throwsA(isA<InvalidMasteryConfigurationException>()),
      );
    });

    test('rejects invalid confidence and evidence counts', () {
      expect(
        () => MasteryEngineConfig.validated(maxConfidence: 0.0),
        throwsA(isA<InvalidMasteryConfigurationException>()),
      );
      expect(
        () => MasteryEngineConfig.validated(maxConfidence: 1.5),
        throwsA(isA<InvalidMasteryConfigurationException>()),
      );
      expect(
        () => MasteryEngineConfig.validated(
          minEvidenceForProficiency: 5,
          minEvidenceForMastery: 3,
        ),
        throwsA(isA<InvalidMasteryConfigurationException>()),
      );
    });

    test('serializes and deserializes configuration deterministically', () {
      final config = MasteryEngineConfig.validated(
        initialMastery: 0.20,
        correctIncrement: 0.08,
        masteredThreshold: 0.92,
      );
      final json = config.toJson();
      final restored = MasteryEngineConfig.fromJson(json);

      expect(restored.initialMastery, 0.20);
      expect(restored.correctIncrement, 0.08);
      expect(restored.masteredThreshold, 0.92);
    });
  });

  group('Group 2: Progressive Mastery Calculation & Invariants', () {
    late ProgressiveMasteryEngine engine;
    late TopicMasteryProfile initialProfile;

    setUp(() {
      engine = ProgressiveMasteryEngine(
        config: MasteryEngineConfig.validated(),
      );
      initialProfile = TopicMasteryProfile.initial(
        learnerId: 'learner_40',
        examId: 'upsc',
        topicId: 'Fundamental Rights',
        initialScore: 0.15,
        evaluatedAt: fixedBaseTime,
      );
    });

    test('first exposure establishes baseline without mutation', () {
      expect(initialProfile.masteryScore, 0.15);
      expect(initialProfile.confidence, 0.0);
      expect(initialProfile.evidenceCount, 0);
      expect(initialProfile.classification, MasteryClassification.notStarted);
      expect(initialProfile.recentAccuracy, isNull);
    });

    test(
        'repeated correct answers progress mastery monotonically towards upper bound',
        () {
      var profile = initialProfile;
      final evidenceList = List.generate(
        8,
        (i) => MasteryEvidenceItem(
          evidenceId: 'ev_c_$i',
          evidenceType: MasteryEvidenceType.practiceCorrect,
          topicId: 'Fundamental Rights',
          isCorrect: true,
          difficulty: 'Medium',
          timestamp: fixedBaseTime.add(Duration(minutes: i * 5)),
        ),
      );

      final updated = engine.updateTopicMastery(
        currentProfile: profile,
        evidenceItems: evidenceList,
        evaluatedAt: fixedBaseTime.add(const Duration(hours: 1)),
        revision: 2,
      );

      expect(updated.masteryScore, greaterThan(0.15));
      expect(updated.evidenceCount, 8);
      expect(updated.correctCount, 8);
      expect(updated.incorrectCount, 0);
      expect(updated.recentAccuracy, 1.0);
      expect(updated.confidence, greaterThan(0.50));
      expect(updated.classification.isProficientOrAbove, isTrue);
      expect(updated.explanation, contains('Mastery updated'));
    });

    test('repeated incorrect answers regress mastery down to minMastery bound',
        () {
      final evidenceList = List.generate(
        10,
        (i) => MasteryEvidenceItem(
          evidenceId: 'ev_w_$i',
          evidenceType: MasteryEvidenceType.practiceIncorrect,
          topicId: 'Fundamental Rights',
          isCorrect: false,
          difficulty: 'Medium',
          timestamp: fixedBaseTime.add(Duration(minutes: i * 5)),
        ),
      );

      final updated = engine.updateTopicMastery(
        currentProfile: initialProfile,
        evidenceItems: evidenceList,
        evaluatedAt: fixedBaseTime.add(const Duration(hours: 1)),
        revision: 2,
      );

      expect(updated.masteryScore, equals(0.0));
      expect(updated.evidenceCount, 10);
      expect(updated.correctCount, 0);
      expect(updated.incorrectCount, 10);
      expect(updated.recentAccuracy, 0.0);
      expect(updated.classification, MasteryClassification.emerging);
    });

    test('mixed performance reflects balanced mastery and recent accuracy', () {
      // 3 correct followed by 2 incorrect
      final evidenceList = [
        MasteryEvidenceItem(
          evidenceId: 'ev_1',
          evidenceType: MasteryEvidenceType.practiceCorrect,
          topicId: 'Fundamental Rights',
          isCorrect: true,
          difficulty: 'Medium',
          timestamp: fixedBaseTime.add(const Duration(minutes: 5)),
        ),
        MasteryEvidenceItem(
          evidenceId: 'ev_2',
          evidenceType: MasteryEvidenceType.practiceCorrect,
          topicId: 'Fundamental Rights',
          isCorrect: true,
          difficulty: 'Medium',
          timestamp: fixedBaseTime.add(const Duration(minutes: 10)),
        ),
        MasteryEvidenceItem(
          evidenceId: 'ev_3',
          evidenceType: MasteryEvidenceType.practiceCorrect,
          topicId: 'Fundamental Rights',
          isCorrect: true,
          difficulty: 'Medium',
          timestamp: fixedBaseTime.add(const Duration(minutes: 15)),
        ),
        MasteryEvidenceItem(
          evidenceId: 'ev_4',
          evidenceType: MasteryEvidenceType.practiceIncorrect,
          topicId: 'Fundamental Rights',
          isCorrect: false,
          difficulty: 'Medium',
          timestamp: fixedBaseTime.add(const Duration(minutes: 20)),
        ),
        MasteryEvidenceItem(
          evidenceId: 'ev_5',
          evidenceType: MasteryEvidenceType.practiceIncorrect,
          topicId: 'Fundamental Rights',
          isCorrect: false,
          difficulty: 'Medium',
          timestamp: fixedBaseTime.add(const Duration(minutes: 25)),
        ),
      ];

      final updated = engine.updateTopicMastery(
        currentProfile: initialProfile,
        evidenceItems: evidenceList,
        evaluatedAt: fixedBaseTime.add(const Duration(hours: 1)),
        revision: 2,
      );

      expect(updated.evidenceCount, 5);
      expect(updated.correctCount, 3);
      expect(updated.incorrectCount, 2);
      expect(updated.recentAccuracy, closeTo(3 / 5, 0.01));
    });

    test('skipped question records evidence without score penalty', () {
      final evidenceList = [
        MasteryEvidenceItem(
          evidenceId: 'ev_skip',
          evidenceType: MasteryEvidenceType.practiceSkipped,
          topicId: 'Fundamental Rights',
          isCorrect: false,
          isSkipped: true,
          difficulty: 'Medium',
          timestamp: fixedBaseTime.add(const Duration(minutes: 5)),
        ),
      ];

      final updated = engine.updateTopicMastery(
        currentProfile: initialProfile,
        evidenceItems: evidenceList,
        evaluatedAt: fixedBaseTime.add(const Duration(hours: 1)),
        revision: 2,
      );

      expect(updated.evidenceCount, 1);
      expect(updated.correctCount, 0);
      expect(updated.incorrectCount, 0);
      expect(updated.masteryScore, initialProfile.masteryScore);
    });
  });

  group('Group 3: Difficulty & Recency Weighting', () {
    late ProgressiveMasteryEngine engine;
    late TopicMasteryProfile baseProfile;

    setUp(() {
      engine = ProgressiveMasteryEngine(
        config: MasteryEngineConfig.validated(),
      );
      baseProfile = TopicMasteryProfile.initial(
        learnerId: 'learner_40',
        examId: 'upsc',
        topicId: 'Polity',
        initialScore: 0.50,
        evaluatedAt: fixedBaseTime,
      );
    });

    test(
        'hard correct question yields higher score increment than easy correct question',
        () {
      final easyItem = [
        MasteryEvidenceItem(
          evidenceId: 'ev_easy',
          evidenceType: MasteryEvidenceType.practiceCorrect,
          topicId: 'Polity',
          isCorrect: true,
          difficulty: 'Easy',
          timestamp: fixedBaseTime,
        ),
      ];

      final hardItem = [
        MasteryEvidenceItem(
          evidenceId: 'ev_hard',
          evidenceType: MasteryEvidenceType.practiceCorrect,
          topicId: 'Polity',
          isCorrect: true,
          difficulty: 'Hard',
          timestamp: fixedBaseTime,
        ),
      ];

      final updatedFromEasy = engine.updateTopicMastery(
        currentProfile: baseProfile,
        evidenceItems: easyItem,
        evaluatedAt: fixedBaseTime,
        revision: 2,
      );

      final updatedFromHard = engine.updateTopicMastery(
        currentProfile: baseProfile,
        evidenceItems: hardItem,
        evaluatedAt: fixedBaseTime,
        revision: 2,
      );

      expect(updatedFromHard.masteryScore,
          greaterThan(updatedFromEasy.masteryScore));
    });

    test('missing an easy question penalizes more than missing a hard question',
        () {
      final easyWrong = [
        MasteryEvidenceItem(
          evidenceId: 'ev_easy_w',
          evidenceType: MasteryEvidenceType.practiceIncorrect,
          topicId: 'Polity',
          isCorrect: false,
          difficulty: 'Easy',
          timestamp: fixedBaseTime,
        ),
      ];

      final hardWrong = [
        MasteryEvidenceItem(
          evidenceId: 'ev_hard_w',
          evidenceType: MasteryEvidenceType.practiceIncorrect,
          topicId: 'Polity',
          isCorrect: false,
          difficulty: 'Hard',
          timestamp: fixedBaseTime,
        ),
      ];

      final afterEasyWrong = engine.updateTopicMastery(
        currentProfile: baseProfile,
        evidenceItems: easyWrong,
        evaluatedAt: fixedBaseTime,
        revision: 2,
      );

      final afterHardWrong = engine.updateTopicMastery(
        currentProfile: baseProfile,
        evidenceItems: hardWrong,
        evaluatedAt: fixedBaseTime,
        revision: 2,
      );

      // Score after easy wrong should be lower than score after hard wrong (stricter penalty)
      expect(
          afterEasyWrong.masteryScore, lessThan(afterHardWrong.masteryScore));
    });

    test('older evidence undergoes deterministic recency decay', () {
      final freshItem = [
        MasteryEvidenceItem(
          evidenceId: 'ev_fresh',
          evidenceType: MasteryEvidenceType.practiceCorrect,
          topicId: 'Polity',
          isCorrect: true,
          difficulty: 'Medium',
          timestamp: fixedBaseTime, // Same as evaluatedAt
        ),
      ];

      final oldItem = [
        MasteryEvidenceItem(
          evidenceId: 'ev_old',
          evidenceType: MasteryEvidenceType.practiceCorrect,
          topicId: 'Polity',
          isCorrect: true,
          difficulty: 'Medium',
          timestamp: fixedBaseTime
              .subtract(const Duration(days: 60)), // 2 half-lives old
        ),
      ];

      final afterFresh = engine.updateTopicMastery(
        currentProfile: baseProfile,
        evidenceItems: freshItem,
        evaluatedAt: fixedBaseTime,
        revision: 2,
      );

      final afterOld = engine.updateTopicMastery(
        currentProfile: baseProfile,
        evidenceItems: oldItem,
        evaluatedAt: fixedBaseTime,
        revision: 2,
      );

      expect(afterFresh.masteryScore, greaterThan(afterOld.masteryScore));
    });
  });

  group('Group 4: Multi-Topic Aggregation & Authoritative State Integration',
      () {
    late ProgressiveMasteryEngine engine;

    setUp(() {
      engine = ProgressiveMasteryEngine(
        config: MasteryEngineConfig.validated(),
      );
    });

    test('evaluates complete snapshot from AuthoritativeLearnerState', () {
      final progressMap = {
        'lo_polity_preamble': LearnerProgress(
          learnerId: 'learner_40',
          objectiveId: 'lo_polity_preamble',
          attemptCount: 4,
          correctCount: 4,
          lastAttemptAt: fixedBaseTime,
          status: LearnerObjectiveStatus.achieved,
        ),
        'lo_polity_fr': LearnerProgress(
          learnerId: 'learner_40',
          objectiveId: 'lo_polity_fr',
          attemptCount: 3,
          correctCount: 1,
          lastAttemptAt: fixedBaseTime,
          status: LearnerObjectiveStatus.inProgress,
        ),
      };

      final authState = AuthoritativeLearnerState(
        learnerId: 'learner_40',
        examId: 'upsc',
        progressMap: progressMap,
        lastUpdatedAt: fixedBaseTime,
        revision: 3,
      );

      final snapshot = engine.evaluateFromAuthoritativeState(
        authoritativeState: authState,
        objectiveToTopicsMap: {
          'lo_polity_preamble': ['Preamble', 'Polity Fundamentals'],
          'lo_polity_fr': ['Fundamental Rights', 'Polity Fundamentals'],
        },
        evaluatedAt: fixedBaseTime,
      );

      expect(snapshot.learnerId, 'learner_40');
      expect(snapshot.examId, 'upsc');
      expect(snapshot.authoritativeRevision, 3);
      expect(snapshot.topicProfiles.containsKey('Preamble'), isTrue);
      expect(snapshot.topicProfiles.containsKey('Fundamental Rights'), isTrue);
      expect(snapshot.topicProfiles.containsKey('Polity Fundamentals'), isTrue);

      // Preamble should have high mastery
      final preamble = snapshot.topicProfiles['Preamble']!;
      expect(preamble.correctCount, 4);
      expect(preamble.incorrectCount, 0);
      expect(preamble.masteryScore, greaterThan(0.40));

      // Decision output signals
      expect(snapshot.decisionOutput.strongestTopics.first,
          anyOf('Preamble', 'Polity Fundamentals'));
      expect(snapshot.decisionOutput.overallMasteryScore, greaterThan(0.0));
      expect(snapshot.verifyChecksum(), isTrue);
    });

    test(
        'evaluates from question-level evidence and deduplicates repeated question in same topic',
        () {
      final qEvidence = [
        PracticeQuestionEvidence(
          questionId: 'q_01',
          examId: 'upsc',
          subject: 'Polity',
          topic: 'Preamble',
          objectiveIds: const ['lo_preamble'],
          difficulty: 'Medium',
          questionIndex: 0,
          status: PracticeQuestionStatus.answeredCorrect,
          correctAnswer: 'A',
          isCorrect: true,
          isAnswered: true,
          isSkipped: false,
          elapsedSeconds: 40,
          answeredAt: fixedBaseTime,
          feedbackPolicy: PracticeFeedbackPolicy.immediate,
          isExplanationExposed: true,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ),
        // Duplicate instance of q_01 for Preamble
        PracticeQuestionEvidence(
          questionId: 'q_01',
          examId: 'upsc',
          subject: 'Polity',
          topic: 'Preamble',
          objectiveIds: const ['lo_preamble'],
          difficulty: 'Medium',
          questionIndex: 0,
          status: PracticeQuestionStatus.answeredCorrect,
          correctAnswer: 'A',
          isCorrect: true,
          isAnswered: true,
          isSkipped: false,
          elapsedSeconds: 40,
          answeredAt: fixedBaseTime,
          feedbackPolicy: PracticeFeedbackPolicy.immediate,
          isExplanationExposed: true,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ),
      ];

      final snapshot = engine.evaluateFromQuestionEvidence(
        learnerId: 'learner_40',
        examId: 'upsc',
        questionEvidence: qEvidence,
        authoritativeRevision: 1,
        evaluatedAt: fixedBaseTime,
      );

      final preamble = snapshot.topicProfiles['Preamble']!;
      // Should only count 1 evidence item due to deduplication guard
      expect(preamble.evidenceCount, 1);
      expect(preamble.correctCount, 1);
    });

    test('enforces strict tenant isolation across learners and exams', () {
      final prevSnapshot = LearnerMasterySnapshot(
        learnerId: 'learner_alpha',
        examId: 'upsc',
        authoritativeRevision: 1,
        topicProfiles: const {},
        decisionOutput: AdaptiveMasteryDecisionOutput(
          weakestTopics: const [],
          strongestTopics: const [],
          remediationRequiredTopics: const [],
          approachingMasteryTopics: const [],
          insufficientEvidenceTopics: const [],
          recommendedDifficultyBand: const {},
          masteryDistribution: const {},
          overallMasteryScore: 0.0,
          overallConfidence: 0.0,
        ),
        evaluatedAt: fixedBaseTime,
      );

      final authState = AuthoritativeLearnerState(
        learnerId: 'learner_beta', // Mismatched learner
        examId: 'upsc',
        progressMap: const {},
        lastUpdatedAt: fixedBaseTime,
        revision: 1,
      );

      expect(
        () => engine.evaluateFromAuthoritativeState(
          authoritativeState: authState,
          previousSnapshot: prevSnapshot,
        ),
        throwsA(isA<MasteryTenantMismatchException>()),
      );
    });
  });

  group('Group 5: Serialization & Integrity Safety', () {
    test(
        'LearnerMasterySnapshot serializes and deserializes cleanly with checksum verification',
        () {
      final profile = TopicMasteryProfile(
        learnerId: 'learner_40',
        examId: 'upsc',
        topicId: 'Judiciary',
        masteryScore: 0.78,
        confidence: 0.85,
        evidenceCount: 6,
        correctCount: 5,
        incorrectCount: 1,
        recentAccuracy: 0.80,
        lastEvaluatedRevision: 2,
        lastEvaluatedAt: fixedBaseTime,
        classification: MasteryClassification.proficient,
        explanation:
            'Proficient performance across High Court and Supreme Court PYQs',
      );

      final decision = AdaptiveMasteryDecisionOutput(
        weakestTopics: const ['Judiciary'],
        strongestTopics: const ['Judiciary'],
        remediationRequiredTopics: const [],
        approachingMasteryTopics: const ['Judiciary'],
        insufficientEvidenceTopics: const [],
        recommendedDifficultyBand: const {'Judiciary': 'Hard'},
        masteryDistribution: const {MasteryClassification.proficient: 1},
        overallMasteryScore: 0.78,
        overallConfidence: 0.85,
      );

      final snapshot = LearnerMasterySnapshot(
        learnerId: 'learner_40',
        examId: 'upsc',
        authoritativeRevision: 2,
        topicProfiles: {'Judiciary': profile},
        decisionOutput: decision,
        evaluatedAt: fixedBaseTime,
      );

      expect(snapshot.verifyChecksum(), isTrue);

      final json = snapshot.toJson();
      final restored = LearnerMasterySnapshot.fromJson(json);

      expect(restored.learnerId, 'learner_40');
      expect(restored.examId, 'upsc');
      expect(restored.authoritativeRevision, 2);
      expect(restored.topicProfiles['Judiciary']!.masteryScore, 0.78);
      expect(restored.topicProfiles['Judiciary']!.classification,
          MasteryClassification.proficient);
      expect(restored.checksum, snapshot.checksum);
      expect(restored.verifyChecksum(), isTrue);
    });

    test(
        'rejects corrupted or tampered payload with MalformedMasteryDataException',
        () {
      final snapshot = LearnerMasterySnapshot(
        learnerId: 'learner_40',
        examId: 'upsc',
        authoritativeRevision: 1,
        topicProfiles: const {},
        decisionOutput: AdaptiveMasteryDecisionOutput(
          weakestTopics: const [],
          strongestTopics: const [],
          remediationRequiredTopics: const [],
          approachingMasteryTopics: const [],
          insufficientEvidenceTopics: const [],
          recommendedDifficultyBand: const {},
          masteryDistribution: const {},
          overallMasteryScore: 0.0,
          overallConfidence: 0.0,
        ),
        evaluatedAt: fixedBaseTime,
      );

      final json = snapshot.toJson();
      json['checksum'] = 'corrupted_tampered_checksum';

      expect(
        () => LearnerMasterySnapshot.fromJson(json),
        throwsA(isA<MalformedMasteryDataException>()),
      );
    });

    test(
        'rejects unsupported schema version with UnsupportedMasterySchemaException',
        () {
      final json = <String, dynamic>{
        'schemaVersion': 999,
        'learnerId': 'learner_40',
        'examId': 'upsc',
        'authoritativeRevision': 1,
        'topicProfiles': {},
        'evaluatedAt': fixedBaseTime.toIso8601String(),
      };

      expect(
        () => LearnerMasterySnapshot.fromJson(json),
        throwsA(isA<UnsupportedMasterySchemaException>()),
      );
    });
  });
}
