import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('AttemptResult Domain Model Tests (TITAN-KO-018.0 P18)', () {
    test('AttemptResult initializes cleanly with valid fields', () {
      final now = DateTime.now().toUtc();
      final result = AttemptResult(
        attemptId: 'att_001',
        isCorrect: true,
        score: 1.0,
        feedback: 'Correct answer.',
        evaluatedAt: now,
        evaluationMethod: EvaluationMethod.multipleChoice,
      );

      expect(result.attemptId, equals('att_001'));
      expect(result.isCorrect, isTrue);
      expect(result.score, equals(1.0));
      expect(result.feedback, equals('Correct answer.'));
      expect(result.evaluatedAt, equals(now));
      expect(result.evaluationMethod, equals(EvaluationMethod.multipleChoice));
    });

    test('AttemptResult rejects empty attemptId', () {
      expect(
        () => AttemptResult(
          attemptId: '',
          isCorrect: true,
          score: 1.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ),
        throwsArgumentError,
      );
      expect(
        () => AttemptResult(
          attemptId: '   ',
          isCorrect: true,
          score: 1.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ),
        throwsArgumentError,
      );
    });

    test('AttemptResult enforces score range [0.0, 1.0]', () {
      expect(
        () => AttemptResult(
          attemptId: 'att_1',
          isCorrect: false,
          score: -0.1,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ),
        throwsArgumentError,
      );
      expect(
        () => AttemptResult(
          attemptId: 'att_1',
          isCorrect: true,
          score: 1.05,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ),
        throwsArgumentError,
      );
    });

    test('AttemptResult serializes to and from JSON correctly', () {
      final r1 = AttemptResult(
        attemptId: 'att_500',
        isCorrect: true,
        score: 0.85,
        feedback: 'Partial credit keyword match',
        evaluatedAt: DateTime.utc(2026, 8, 15, 12, 0),
        evaluationMethod: EvaluationMethod.shortAnswerKeyword,
      );

      final json = r1.toJson();
      final r2 = AttemptResult.fromJson(json);

      expect(r2.attemptId, equals(r1.attemptId));
      expect(r2.isCorrect, equals(r1.isCorrect));
      expect(r2.score, equals(r1.score));
      expect(r2.feedback, equals(r1.feedback));
      expect(r2.evaluatedAt, equals(r1.evaluatedAt));
      expect(r2.evaluationMethod, equals(r1.evaluationMethod));
      expect(r2, equals(r1));
    });

    test('AttemptResult value equality and hash code work correctly', () {
      final t1 = DateTime.utc(2026, 1, 1);
      final r1 = AttemptResult(
        attemptId: 'a1',
        isCorrect: true,
        score: 1.0,
        feedback: 'Good',
        evaluatedAt: t1,
        evaluationMethod: EvaluationMethod.multipleChoice,
      );
      final r2 = AttemptResult(
        attemptId: 'a1',
        isCorrect: true,
        score: 1.0,
        feedback: 'Good',
        evaluatedAt: t1,
        evaluationMethod: EvaluationMethod.multipleChoice,
      );
      final r3 = AttemptResult(
        attemptId: 'a1',
        isCorrect: false,
        score: 0.0,
        evaluationMethod: EvaluationMethod.multipleChoice,
      );

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
    });

    test('AttemptResult toString displays key score information', () {
      final result = AttemptResult(
        attemptId: 'att_12',
        isCorrect: true,
        score: 1.0,
        evaluationMethod: EvaluationMethod.trueFalse,
      );

      expect(result.toString(), contains('att_12'));
      expect(result.toString(), contains('true'));
      expect(result.toString(), contains('1.0'));
    });
  });
}
