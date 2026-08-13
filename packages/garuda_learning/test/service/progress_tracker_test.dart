import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('ProgressTracker Service Tests (TITAN-KO-018.0 P18)', () {
    late InMemoryAttemptRepository attemptRepo;
    late InMemoryProgressRepository progressRepo;
    late ProgressTracker tracker;

    setUp(() {
      attemptRepo = InMemoryAttemptRepository();
      progressRepo = InMemoryProgressRepository();
      tracker = ProgressTracker(
        attemptRepository: attemptRepo,
        progressRepository: progressRepo,
      );
    });

    test('Default threshold config is minAttempts=5, minSuccessRate=0.80', () {
      expect(tracker.thresholdConfig.minimumAttempts, equals(5));
      expect(tracker.thresholdConfig.minimumSuccessRate, equals(0.80));
    });

    test('0 attempts results in NotStarted status', () {
      final progress = tracker.updateProgress(
        learnerId: 'l1',
        objectiveId: 'o1',
      );

      expect(progress.attemptCount, equals(0));
      expect(progress.correctCount, equals(0));
      expect(progress.successRate, equals(0.0));
      expect(progress.status, equals(LearnerObjectiveStatus.notStarted));
      expect(progress.isAchieved, isFalse);
    });

    test(
        '1 to 4 attempts below minAttempts results in InProgress status even if 100% success',
        () {
      for (var i = 1; i <= 4; i++) {
        final attempt = QuestionAttempt(
          attemptId: 'att_$i',
          learnerId: 'l1',
          questionId: 'q1',
          objectiveId: 'o1',
          submittedAnswer: 'Ans',
        );
        final result = AttemptResult(
          attemptId: 'att_$i',
          isCorrect: true,
          score: 1.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        );

        attemptRepo.saveAttempt(attempt);
        attemptRepo.saveResult(result);

        final progress = tracker.updateProgress(
          learnerId: 'l1',
          objectiveId: 'o1',
        );

        expect(progress.attemptCount, equals(i));
        expect(progress.correctCount, equals(i));
        expect(progress.successRate, equals(1.0));
        expect(progress.status, equals(LearnerObjectiveStatus.inProgress));
        expect(progress.isAchieved, isFalse);
      }
    });

    test(
        '5 attempts with 4 correct (80%) satisfies threshold -> Achieved status',
        () {
      for (var i = 1; i <= 5; i++) {
        final isCorrect = i <= 4; // 4 out of 5 correct = 80%
        final attempt = QuestionAttempt(
          attemptId: 'att_$i',
          learnerId: 'l1',
          questionId: 'q1',
          objectiveId: 'o1',
          submittedAnswer: 'Ans',
        );
        final result = AttemptResult(
          attemptId: 'att_$i',
          isCorrect: isCorrect,
          score: isCorrect ? 1.0 : 0.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        );

        attemptRepo.saveAttempt(attempt);
        attemptRepo.saveResult(result);
      }

      final progress = tracker.updateProgress(
        learnerId: 'l1',
        objectiveId: 'o1',
      );

      expect(progress.attemptCount, equals(5));
      expect(progress.correctCount, equals(4));
      expect(progress.successRate, equals(0.80));
      expect(progress.status, equals(LearnerObjectiveStatus.achieved));
      expect(progress.isAchieved, isTrue);
      expect(progress.achievedAt, isNotNull);
    });

    test('5 attempts with 3 correct (60%) remains InProgress (< 80%)', () {
      for (var i = 1; i <= 5; i++) {
        final isCorrect = i <= 3; // 3 out of 5 correct = 60%
        final attempt = QuestionAttempt(
          attemptId: 'att_$i',
          learnerId: 'l1',
          questionId: 'q1',
          objectiveId: 'o1',
          submittedAnswer: 'Ans',
        );
        final result = AttemptResult(
          attemptId: 'att_$i',
          isCorrect: isCorrect,
          score: isCorrect ? 1.0 : 0.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        );

        attemptRepo.saveAttempt(attempt);
        attemptRepo.saveResult(result);
      }

      final progress = tracker.updateProgress(
        learnerId: 'l1',
        objectiveId: 'o1',
      );

      expect(progress.attemptCount, equals(5));
      expect(progress.correctCount, equals(3));
      expect(progress.successRate, equals(0.60));
      expect(progress.status, equals(LearnerObjectiveStatus.inProgress));
      expect(progress.isAchieved, isFalse);
    });

    test(
        'Custom AssessmentThresholdConfig (minAttempts=2, minSuccessRate=0.50) is respected',
        () {
      final customTracker = ProgressTracker(
        attemptRepository: attemptRepo,
        progressRepository: progressRepo,
        thresholdConfig: const AssessmentThresholdConfig(
          minimumAttempts: 2,
          minimumSuccessRate: 0.50,
        ),
      );

      for (var i = 1; i <= 2; i++) {
        final isCorrect = i == 1; // 1 out of 2 correct = 50%
        attemptRepo.saveAttempt(QuestionAttempt(
          attemptId: 'att_c_$i',
          learnerId: 'l2',
          questionId: 'q1',
          objectiveId: 'o2',
          submittedAnswer: 'Ans',
        ));
        attemptRepo.saveResult(AttemptResult(
          attemptId: 'att_c_$i',
          isCorrect: isCorrect,
          score: isCorrect ? 1.0 : 0.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }

      final progress = customTracker.updateProgress(
        learnerId: 'l2',
        objectiveId: 'o2',
      );

      expect(progress.attemptCount, equals(2));
      expect(progress.correctCount, equals(1));
      expect(progress.successRate, equals(0.50));
      expect(progress.status, equals(LearnerObjectiveStatus.achieved));
      expect(progress.isAchieved, isTrue);
    });

    test(
        'getProgress and getLearnerProgressSummary retrieve stored progress records',
        () {
      tracker.updateProgress(learnerId: 'l1', objectiveId: 'o1');
      tracker.updateProgress(learnerId: 'l1', objectiveId: 'o2');

      final p1 = tracker.getProgress('l1', 'o1');
      expect(p1, isNotNull);
      expect(p1!.objectiveId, equals('o1'));

      final summary = tracker.getLearnerProgressSummary('l1');
      expect(summary.length, equals(2));
      expect(summary.map((p) => p.objectiveId), equals(['o1', 'o2']));
    });

    test('updateProgress rejects empty learnerId or objectiveId', () {
      expect(
        () => tracker.updateProgress(learnerId: '', objectiveId: 'o1'),
        throwsArgumentError,
      );
      expect(
        () => tracker.updateProgress(learnerId: 'l1', objectiveId: '  '),
        throwsArgumentError,
      );
    });
  });
}
