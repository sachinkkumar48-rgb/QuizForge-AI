import 'package:flutter_test/flutter_test.dart';
import 'package:titan_smart_assessment/titan_smart_assessment.dart';

void main() {
  group('AssessmentEngine Pure Dart Core Tests', () {
    late AssessmentEngine engine;

    setUp(() {
      engine = const AssessmentEngine();
    });

    test('generateBlueprint creates standard blueprint', () {
      final bp = engine.generateBlueprint(
        title: 'Polity GS Test',
        subjectCategory: 'Polity',
        totalQuestions: 15,
        negativePenaltyPerWrong: 0.66,
      );

      expect(bp.totalQuestions, equals(15));
      expect(bp.rubric.negativePenaltyPerWrong, equals(0.66));
    });

    test('scoreAssessment computes correct points and negative penalties', () {
      const blueprint = AssessmentBlueprint(
        id: 'bp1',
        title: 'Test',
        subjectCategory: 'Polity',
        rubric: AssessmentRubric(
          id: 'r1',
          name: 'Negative Scoring',
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
            timestamp: now,
          ),
          AssessmentAttempt(
            id: 'a2',
            sessionId: 's1',
            questionId: 'q2',
            selectedOptionId: 'opt2',
            isCorrect: false,
            timestamp: now,
          ),
        ],
        startedAt: now,
        updatedAt: now,
      );

      final result = engine.scoreAssessment(
        session: session,
        blueprint: blueprint,
        questions: const [],
      );

      // 1 correct (+2.0), 1 wrong (-0.66) = 1.34 raw score out of 4.0
      expect(result.score, closeTo(1.34, 0.01));
      expect(result.correctCount, equals(1));
      expect(result.wrongCount, equals(1));
    });

    test('updateAdaptiveTheta updates theta up on correct answer', () {
      const initial = AdaptiveAssessmentState(
        sessionId: 's1',
        currentTheta: 0.0,
      );

      final updated = engine.updateAdaptiveTheta(
        currentState: initial,
        isCorrect: true,
        itemDifficulty: 0.0,
      );

      expect(updated.currentTheta, greaterThan(0.0));
      expect(updated.consecutiveCorrect, equals(1));
    });

    test('calculateReadinessScore combines accuracy, volume, confidence', () {
      final readiness = engine.calculateReadinessScore(
        overallAccuracy: 80.0,
        totalAttempted: 20,
        averageConfidence: 0.8,
      );

      // (80 * 0.6) + (1.0 * 20) + (0.8 * 20) = 48 + 20 + 16 = 84.0
      expect(readiness, equals(84.0));
      final pred = engine.generateExamPrediction(readiness);
      expect(pred, contains('High Probability'));
    });
  });
}
