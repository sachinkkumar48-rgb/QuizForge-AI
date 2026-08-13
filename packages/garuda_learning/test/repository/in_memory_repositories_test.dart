import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('In-Memory Repositories Tests (TITAN-KO-018.0 P18)', () {
    group('InMemoryLearnerRepository', () {
      late InMemoryLearnerRepository repo;

      setUp(() {
        repo = InMemoryLearnerRepository();
      });

      test('Stores and retrieves learner by ID', () {
        final learner = Learner(id: 'l1', name: 'Alice');
        repo.save(learner);

        final fetched = repo.getById('l1');
        expect(fetched, equals(learner));
        expect(repo.exists('l1'), isTrue);
      });

      test('Returns null for non-existent learner ID', () {
        expect(repo.getById('l_missing'), isNull);
        expect(repo.exists('l_missing'), isFalse);
      });

      test('getAll returns list in deterministic ID order', () {
        repo.save(Learner(id: 'l_charlie', name: 'Charlie'));
        repo.save(Learner(id: 'l_alice', name: 'Alice'));
        repo.save(Learner(id: 'l_bob', name: 'Bob'));

        final all = repo.getAll();
        expect(all.length, equals(3));
        expect(all[0].id, equals('l_alice'));
        expect(all[1].id, equals('l_bob'));
        expect(all[2].id, equals('l_charlie'));
      });

      test('clear removes all stored learners', () {
        repo.save(Learner(id: 'l1', name: 'Alice'));
        expect(repo.getAll(), isNotEmpty);
        repo.clear();
        expect(repo.getAll(), isEmpty);
      });
    });

    group('InMemoryAttemptRepository', () {
      late InMemoryAttemptRepository repo;

      setUp(() {
        repo = InMemoryAttemptRepository();
      });

      test('Stores and retrieves attempt and result by ID', () {
        final attempt = QuestionAttempt(
          attemptId: 'att_1',
          learnerId: 'l1',
          questionId: 'q1',
          objectiveId: 'o1',
          submittedAnswer: 'A',
        );

        final result = AttemptResult(
          attemptId: 'att_1',
          isCorrect: true,
          score: 1.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        );

        repo.saveAttempt(attempt);
        repo.saveResult(result);

        expect(repo.getAttemptById('att_1'), equals(attempt));
        expect(repo.getResultForAttempt('att_1'), equals(result));
      });

      test('Returns null for non-existent attempt/result ID', () {
        expect(repo.getAttemptById('att_none'), isNull);
        expect(repo.getResultForAttempt('att_none'), isNull);
      });

      test('Filtering by learner and objective works deterministically', () {
        final now = DateTime.now().toUtc();
        final a1 = QuestionAttempt(
          attemptId: 'a1',
          learnerId: 'l1',
          questionId: 'q1',
          objectiveId: 'o1',
          submittedAnswer: 'A',
          attemptedAt: now.subtract(const Duration(minutes: 10)),
        );
        final a2 = QuestionAttempt(
          attemptId: 'a2',
          learnerId: 'l1',
          questionId: 'q2',
          objectiveId: 'o1',
          submittedAnswer: 'B',
          attemptedAt: now,
        );
        final a3 = QuestionAttempt(
          attemptId: 'a3',
          learnerId: 'l2',
          questionId: 'q1',
          objectiveId: 'o1',
          submittedAnswer: 'A',
        );

        repo.saveAttempt(a1);
        repo.saveAttempt(a2);
        repo.saveAttempt(a3);

        final l1Attempts = repo.getAttemptsForLearner('l1');
        expect(l1Attempts.length, equals(2));
        expect(l1Attempts.first.attemptId, equals('a1'));
        expect(l1Attempts.last.attemptId, equals('a2'));

        final o1Attempts = repo.getAttemptsForLearnerAndObjective('l1', 'o1');
        expect(o1Attempts.length, equals(2));
      });

      test('Filtering by session returns session attempts in order', () {
        final a1 = QuestionAttempt(
          attemptId: 'a1',
          learnerId: 'l1',
          questionId: 'q1',
          objectiveId: 'o1',
          submittedAnswer: 'A',
          sessionId: 's1',
        );
        final a2 = QuestionAttempt(
          attemptId: 'a2',
          learnerId: 'l1',
          questionId: 'q2',
          objectiveId: 'o1',
          submittedAnswer: 'B',
          sessionId: 's1',
        );

        repo.saveAttempt(a1);
        repo.saveAttempt(a2);

        final sessionAttempts = repo.getAttemptsForSession('s1');
        expect(sessionAttempts.length, equals(2));
        expect(sessionAttempts.map((a) => a.attemptId), equals(['a1', 'a2']));
      });

      test('clear removes all stored attempts and results', () {
        repo.saveAttempt(QuestionAttempt(
          attemptId: 'a1',
          learnerId: 'l1',
          questionId: 'q1',
          objectiveId: 'o1',
          submittedAnswer: 'A',
        ));
        expect(repo.getAttemptsForLearner('l1'), isNotEmpty);
        repo.clear();
        expect(repo.getAttemptsForLearner('l1'), isEmpty);
      });
    });

    group('InMemoryProgressRepository', () {
      late InMemoryProgressRepository repo;

      setUp(() {
        repo = InMemoryProgressRepository();
      });

      test('Stores and retrieves progress by learnerId and objectiveId', () {
        final progress = LearnerProgress(
          learnerId: 'l1',
          objectiveId: 'o1',
          attemptCount: 5,
          correctCount: 4,
          status: LearnerObjectiveStatus.achieved,
        );

        repo.saveProgress(progress);

        final fetched = repo.getProgress('l1', 'o1');
        expect(fetched, equals(progress));
      });

      test('Returns null for non-existent progress record', () {
        expect(repo.getProgress('l_none', 'o_none'), isNull);
      });

      test('Learner isolation: getProgressForLearner isolates learner progress',
          () {
        repo.saveProgress(LearnerProgress(learnerId: 'l1', objectiveId: 'o1'));
        repo.saveProgress(LearnerProgress(learnerId: 'l1', objectiveId: 'o2'));
        repo.saveProgress(LearnerProgress(learnerId: 'l2', objectiveId: 'o1'));

        final l1List = repo.getProgressForLearner('l1');
        expect(l1List.length, equals(2));
        expect(l1List.map((p) => p.objectiveId), equals(['o1', 'o2']));

        final l2List = repo.getProgressForLearner('l2');
        expect(l2List.length, equals(1));
        expect(l2List.first.learnerId, equals('l2'));
      });

      test('getAll returns all progress records in deterministic order', () {
        repo.saveProgress(LearnerProgress(learnerId: 'l2', objectiveId: 'o1'));
        repo.saveProgress(LearnerProgress(learnerId: 'l1', objectiveId: 'o2'));
        repo.saveProgress(LearnerProgress(learnerId: 'l1', objectiveId: 'o1'));

        final all = repo.getAll();
        expect(all.length, equals(3));
        expect(all[0].learnerId, equals('l1'));
        expect(all[0].objectiveId, equals('o1'));
        expect(all[1].learnerId, equals('l1'));
        expect(all[1].objectiveId, equals('o2'));
        expect(all[2].learnerId, equals('l2'));
      });

      test('clear removes all progress records', () {
        repo.saveProgress(LearnerProgress(learnerId: 'l1', objectiveId: 'o1'));
        expect(repo.getAll(), isNotEmpty);
        repo.clear();
        expect(repo.getAll(), isEmpty);
      });
    });
  });
}
