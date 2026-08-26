import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/attempt_result.dart';
import 'package:garuda_learning/domain/entities/evaluation_method.dart';
import 'package:garuda_learning/domain/entities/learner_objective_status.dart';
import 'package:garuda_learning/domain/entities/learner_progress.dart';
import 'package:garuda_learning/domain/entities/learning_session.dart';
import 'package:garuda_learning/domain/entities/learning_session_state.dart';
import 'package:garuda_learning/domain/entities/question_attempt.dart';
import 'package:garuda_learning/domain/entities/session_configuration.dart';
import 'package:garuda_learning/service/learning_velocity_evaluator.dart';

void main() {
  group('LearningVelocityEvaluator Service Tests (P23 Stage 4)', () {
    const evaluator = LearningVelocityEvaluator();
    final fixedTime = DateTime.utc(2026, 8, 25, 14, 0, 0);
    final windowStart = DateTime.utc(2026, 8, 20, 0, 0, 0);
    final windowEnd = DateTime.utc(2026, 8, 25, 0, 0, 0);

    LearningSession makeSession({
      required String sessionId,
      required String learnerId,
      required DateTime startedAt,
      DateTime? completedAt,
      LearningSessionState state = LearningSessionState.completed,
    }) {
      return LearningSession(
        sessionId: sessionId,
        learnerId: learnerId,
        configuration: SessionConfiguration(
          learnerId: learnerId,
          objectiveIds: const ['lo_1'],
        ),
        orderedQuestionIds: const ['q_1'],
        state: state,
        startedAt: startedAt,
        completedAt: completedAt,
      );
    }

    QuestionAttempt makeAttempt({
      required String attemptId,
      required String learnerId,
      required DateTime attemptedAt,
      String objectiveId = 'lo_1',
    }) {
      return QuestionAttempt(
        attemptId: attemptId,
        learnerId: learnerId,
        questionId: 'q_1',
        objectiveId: objectiveId,
        submittedAnswer: 'A',
        attemptedAt: attemptedAt,
      );
    }

    AttemptResult makeResult(String attemptId, {required bool isCorrect}) {
      return AttemptResult(
        attemptId: attemptId,
        isCorrect: isCorrect,
        score: isCorrect ? 1.0 : 0.0,
        evaluationMethod: EvaluationMethod.multipleChoice,
      );
    }

    test('1. Zero attempts and zero sessions yields null metrics', () {
      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessions: const [],
        attempts: const [],
        attemptResults: const [],
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      expect(profile.attemptsCount, equals(0));
      expect(profile.sessionsCount, equals(0));
      expect(profile.correctAttemptsCount, equals(0));
      expect(profile.observedAccuracy, isNull);
      expect(profile.attemptsPerHour, isNull);
      expect(profile.hasSufficientEvidence, isFalse);
    });

    test('2. Zero sessions with some attempts yields null attemptsPerHour', () {
      final attempts = [
        makeAttempt(
            attemptId: 'a_1',
            learnerId: 'learner_001',
            attemptedAt: DateTime.utc(2026, 8, 22, 10, 0, 0)),
      ];
      final results = [makeResult('a_1', isCorrect: true)];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessions: const [],
        attempts: attempts,
        attemptResults: results,
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      expect(profile.attemptsCount, equals(1));
      expect(profile.sessionsCount, equals(0));
      expect(profile.activeStudyDuration, equals(Duration.zero));
      expect(profile.attemptsPerHour, isNull);
    });

    test('3. Zero active duration yields null attemptsPerHour', () {
      // Session with zero duration (startedAt == completedAt)
      final sessions = [
        makeSession(
          sessionId: 's_1',
          learnerId: 'learner_001',
          startedAt: DateTime.utc(2026, 8, 22, 10, 0, 0),
          completedAt: DateTime.utc(2026, 8, 22, 10, 0, 0),
        ),
      ];

      final attempts = [
        makeAttempt(
            attemptId: 'a_1',
            learnerId: 'learner_001',
            attemptedAt: DateTime.utc(2026, 8, 22, 10, 0, 0)),
      ];
      final results = [makeResult('a_1', isCorrect: true)];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessions: sessions,
        attempts: attempts,
        attemptResults: results,
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      expect(profile.attemptsPerHour, isNull);
      expect(profile.activeStudyDuration, equals(Duration.zero));
    });

    test('4. Zero-length window yields null objectivesAchievedPerDay', () {
      final sameTime = DateTime.utc(2026, 8, 22, 10, 0, 0);

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        windowStart: sameTime,
        windowEnd: sameTime,
        sessions: const [],
        attempts: const [],
        attemptResults: const [],
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      expect(profile.objectivesAchievedPerDay, isNull);
    });

    test('5. Normal multi-session throughput calculation', () {
      final sessions = [
        makeSession(
          sessionId: 's_1',
          learnerId: 'learner_001',
          startedAt: DateTime.utc(2026, 8, 21, 9, 0, 0),
          completedAt: DateTime.utc(2026, 8, 21, 10, 0, 0), // 1 hour
        ),
        makeSession(
          sessionId: 's_2',
          learnerId: 'learner_001',
          startedAt: DateTime.utc(2026, 8, 23, 14, 0, 0),
          completedAt: DateTime.utc(2026, 8, 23, 15, 30, 0), // 1.5 hours
        ),
      ];

      final attempts = [
        makeAttempt(
            attemptId: 'a_1',
            learnerId: 'learner_001',
            attemptedAt: DateTime.utc(2026, 8, 21, 9, 15, 0)),
        makeAttempt(
            attemptId: 'a_2',
            learnerId: 'learner_001',
            attemptedAt: DateTime.utc(2026, 8, 21, 9, 30, 0)),
        makeAttempt(
            attemptId: 'a_3',
            learnerId: 'learner_001',
            attemptedAt: DateTime.utc(2026, 8, 23, 14, 10, 0)),
        makeAttempt(
            attemptId: 'a_4',
            learnerId: 'learner_001',
            attemptedAt: DateTime.utc(2026, 8, 23, 14, 20, 0)),
        makeAttempt(
            attemptId: 'a_5',
            learnerId: 'learner_001',
            attemptedAt: DateTime.utc(2026, 8, 23, 14, 30, 0)),
      ];

      final results = [
        makeResult('a_1', isCorrect: true),
        makeResult('a_2', isCorrect: false),
        makeResult('a_3', isCorrect: true),
        makeResult('a_4', isCorrect: true),
        makeResult('a_5', isCorrect: false),
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessions: sessions,
        attempts: attempts,
        attemptResults: results,
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      expect(profile.sessionsCount, equals(2));
      expect(profile.attemptsCount, equals(5));
      expect(profile.correctAttemptsCount, equals(3));
      // activeStudyDuration = 3600 + 5400 = 9000 seconds = 2.5 hours
      expect(
          profile.activeStudyDuration, equals(const Duration(seconds: 9000)));
      expect(profile.hasSufficientEvidence, isTrue);
    });

    test('6. Observed accuracy calculation', () {
      final attempts = [
        makeAttempt(
            attemptId: 'a_1',
            learnerId: 'learner_001',
            attemptedAt: DateTime.utc(2026, 8, 22, 10, 0, 0)),
        makeAttempt(
            attemptId: 'a_2',
            learnerId: 'learner_001',
            attemptedAt: DateTime.utc(2026, 8, 22, 10, 5, 0)),
        makeAttempt(
            attemptId: 'a_3',
            learnerId: 'learner_001',
            attemptedAt: DateTime.utc(2026, 8, 22, 10, 10, 0)),
        makeAttempt(
            attemptId: 'a_4',
            learnerId: 'learner_001',
            attemptedAt: DateTime.utc(2026, 8, 22, 10, 15, 0)),
      ];

      final results = [
        makeResult('a_1', isCorrect: true),
        makeResult('a_2', isCorrect: true),
        makeResult('a_3', isCorrect: false),
        makeResult('a_4', isCorrect: true),
      ];

      final sessions = [
        makeSession(
          sessionId: 's_1',
          learnerId: 'learner_001',
          startedAt: DateTime.utc(2026, 8, 22, 9, 0, 0),
          completedAt: DateTime.utc(2026, 8, 22, 11, 0, 0),
        ),
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessions: sessions,
        attempts: attempts,
        attemptResults: results,
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      // 3 correct out of 4 = 0.75
      expect(profile.observedAccuracy, closeTo(0.75, 0.001));
    });

    test('7. Newly achieved objectives counted correctly', () {
      final progressList = [
        LearnerProgress(
          learnerId: 'learner_001',
          objectiveId: 'lo_1',
          attemptCount: 10,
          correctCount: 8,
          status: LearnerObjectiveStatus.achieved,
          achievedAt: DateTime.utc(2026, 8, 22, 12, 0, 0), // in window
        ),
        LearnerProgress(
          learnerId: 'learner_001',
          objectiveId: 'lo_2',
          attemptCount: 5,
          correctCount: 4,
          status: LearnerObjectiveStatus.achieved,
          achievedAt: DateTime.utc(2026, 8, 15, 12, 0, 0), // before window
        ),
        LearnerProgress(
          learnerId: 'learner_001',
          objectiveId: 'lo_3',
          attemptCount: 7,
          correctCount: 6,
          status: LearnerObjectiveStatus.achieved,
          achievedAt: DateTime.utc(2026, 8, 24, 18, 0, 0), // in window
        ),
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessions: const [],
        attempts: const [],
        attemptResults: const [],
        progressList: progressList,
        evaluatedAt: fixedTime,
      );

      // lo_1 and lo_3 achieved within window
      expect(profile.newlyAchievedObjectivesCount, equals(2));

      // 5-day window = 432000 seconds
      // objectivesAchievedPerDay = 2 / 5.0 = 0.4
      expect(profile.objectivesAchievedPerDay, closeTo(0.4, 0.001));
    });

    test('8. Multiple learners isolated', () {
      final attempts = [
        makeAttempt(
            attemptId: 'a_1',
            learnerId: 'learner_001',
            attemptedAt: DateTime.utc(2026, 8, 22, 10, 0, 0)),
        makeAttempt(
            attemptId: 'a_2',
            learnerId: 'learner_999',
            attemptedAt: DateTime.utc(2026, 8, 22, 10, 5, 0)),
        makeAttempt(
            attemptId: 'a_3',
            learnerId: 'learner_999',
            attemptedAt: DateTime.utc(2026, 8, 22, 10, 10, 0)),
      ];

      final results = [
        makeResult('a_1', isCorrect: true),
        makeResult('a_2', isCorrect: true),
        makeResult('a_3', isCorrect: true),
      ];

      final sessions = [
        makeSession(
          sessionId: 's_1',
          learnerId: 'learner_001',
          startedAt: DateTime.utc(2026, 8, 22, 9, 0, 0),
          completedAt: DateTime.utc(2026, 8, 22, 10, 0, 0),
        ),
        makeSession(
          sessionId: 's_2',
          learnerId: 'learner_999',
          startedAt: DateTime.utc(2026, 8, 22, 9, 0, 0),
          completedAt: DateTime.utc(2026, 8, 22, 12, 0, 0),
        ),
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessions: sessions,
        attempts: attempts,
        attemptResults: results,
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      // Only learner_001's data
      expect(profile.attemptsCount, equals(1));
      expect(profile.sessionsCount, equals(1));
      expect(profile.correctAttemptsCount, equals(1));
    });

    test('9. Invalid learnerId throws ArgumentError', () {
      expect(
        () => evaluator.evaluate(
          learnerId: '',
          windowStart: windowStart,
          windowEnd: windowEnd,
          sessions: const [],
          attempts: const [],
          attemptResults: const [],
          progressList: const [],
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('10. Reversed window throws ArgumentError', () {
      expect(
        () => evaluator.evaluate(
          learnerId: 'learner_001',
          windowStart: windowEnd, // reversed!
          windowEnd: windowStart,
          sessions: const [],
          attempts: const [],
          attemptResults: const [],
          progressList: const [],
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('11. Invalid threshold throws ArgumentError', () {
      expect(
        () => evaluator.evaluate(
          learnerId: 'learner_001',
          windowStart: windowStart,
          windowEnd: windowEnd,
          sessions: const [],
          attempts: const [],
          attemptResults: const [],
          progressList: const [],
          minimumEvidenceThreshold: 0,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test(
        '12. Deterministic replay: identical inputs produce identical profiles',
        () {
      final sessions = [
        makeSession(
          sessionId: 's_1',
          learnerId: 'learner_001',
          startedAt: DateTime.utc(2026, 8, 22, 9, 0, 0),
          completedAt: DateTime.utc(2026, 8, 22, 10, 0, 0),
        ),
      ];

      final attempts = [
        makeAttempt(
            attemptId: 'a_1',
            learnerId: 'learner_001',
            attemptedAt: DateTime.utc(2026, 8, 22, 9, 15, 0)),
        makeAttempt(
            attemptId: 'a_2',
            learnerId: 'learner_001',
            attemptedAt: DateTime.utc(2026, 8, 22, 9, 30, 0)),
      ];

      final results = [
        makeResult('a_1', isCorrect: true),
        makeResult('a_2', isCorrect: false),
      ];

      final profile1 = evaluator.evaluate(
        learnerId: 'learner_001',
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessions: sessions,
        attempts: attempts,
        attemptResults: results,
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      final profile2 = evaluator.evaluate(
        learnerId: 'learner_001',
        windowStart: windowStart,
        windowEnd: windowEnd,
        sessions: sessions,
        attempts: attempts,
        attemptResults: results,
        progressList: const [],
        evaluatedAt: fixedTime,
      );

      expect(profile1, equals(profile2));
      expect(profile1.hashCode, equals(profile2.hashCode));
      expect(profile1.toJson(), equals(profile2.toJson()));
    });
  });
}
