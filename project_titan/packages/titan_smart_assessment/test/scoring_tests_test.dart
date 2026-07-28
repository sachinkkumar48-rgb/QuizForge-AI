import 'package:flutter_test/flutter_test.dart';
import 'package:titan_smart_assessment/titan_smart_assessment.dart';

void main() {
  group('Assessment Scoring & Negative Marking Tests', () {
    late AssessmentEngine engine;

    setUp(() {
      engine = const AssessmentEngine();
    });

    test('Negative marking deduction calculation for wrong answers', () {
      const blueprint = AssessmentBlueprint(
        id: 'bp1',
        title: 'UPSC GS Paper',
        subjectCategory: 'General Studies',
        rubric: AssessmentRubric(
          id: 'r1',
          name: 'UPSC Negative Marking',
          maxPoints: 2.0,
          negativePenaltyPerWrong: 0.66,
        ),
      );

      final now = DateTime.now();
      final session = AssessmentSession(
        id: 's1',
        assessmentId: 'asmt1',
        userId: 'u1',
        attempts: [
          AssessmentAttempt(
              id: 'a1',
              sessionId: 's1',
              questionId: 'q1',
              selectedOptionId: 'opt1',
              isCorrect: true,
              timestamp: now),
          AssessmentAttempt(
              id: 'a2',
              sessionId: 's1',
              questionId: 'q2',
              selectedOptionId: 'opt1',
              isCorrect: true,
              timestamp: now),
          AssessmentAttempt(
              id: 'a3',
              sessionId: 's1',
              questionId: 'q3',
              selectedOptionId: 'opt2',
              isCorrect: false,
              timestamp: now),
        ],
        startedAt: now,
        updatedAt: now,
      );

      final result = engine.scoreAssessment(
        session: session,
        blueprint: blueprint,
        questions: const [],
      );

      // 2 correct (4.0) - 1 wrong (0.66) = 3.34 score out of 6.0
      expect(result.score, closeTo(3.34, 0.01));
      expect(result.correctCount, equals(2));
      expect(result.wrongCount, equals(1));
    });

    test('Zero raw score floor when penalty exceeds correct score', () {
      const blueprint = AssessmentBlueprint(
        id: 'bp1',
        title: 'Test',
        subjectCategory: 'General Studies',
        rubric: AssessmentRubric(
          id: 'r1',
          name: 'Heavy Penalty',
          maxPoints: 1.0,
          negativePenaltyPerWrong: 2.0,
        ),
      );

      final now = DateTime.now();
      final session = AssessmentSession(
        id: 's1',
        assessmentId: 'asmt1',
        userId: 'u1',
        attempts: [
          AssessmentAttempt(
              id: 'a1',
              sessionId: 's1',
              questionId: 'q1',
              selectedOptionId: 'opt1',
              isCorrect: false,
              timestamp: now),
        ],
        startedAt: now,
        updatedAt: now,
      );

      final result = engine.scoreAssessment(
        session: session,
        blueprint: blueprint,
        questions: const [],
      );

      expect(result.score, equals(0.0));
    });
  });
}
