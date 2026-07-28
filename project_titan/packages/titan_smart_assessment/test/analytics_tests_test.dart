import 'package:flutter_test/flutter_test.dart';
import 'package:titan_smart_assessment/titan_smart_assessment.dart';

void main() {
  group('Assessment Performance Analytics Tests', () {
    late AssessmentEngine engine;

    setUp(() {
      engine = const AssessmentEngine();
    });

    test('analyzeSkillGaps flags topic below 60% accuracy', () {
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
          AssessmentAttempt(
              id: 'a2',
              sessionId: 's1',
              questionId: 'q2',
              selectedOptionId: 'opt1',
              isCorrect: false,
              timestamp: now),
        ],
        startedAt: now,
        updatedAt: now,
      );

      final analysis = engine.analyzeSkillGaps(
        session: session,
        questions: const [],
        assessmentId: 'asmt1',
      );

      expect(analysis.overallAccuracyPercentage, equals(0.0));
      expect(analysis.readinessScore, lessThan(50.0));
    });

    test('generateRecommendations creates targeted actions for skill gaps', () {
      final gap = SkillGap(
        id: 'g1',
        conceptId: 'c_polity',
        conceptTitle: 'Polity Emergency Provisions',
        gapSeverity: 'High',
        recommendedAction: 'Practice 10 emergency provisions MCQs',
        identifiedAt: DateTime.now(),
      );

      final analysis = AssessmentAnalysis(
        id: 'an1',
        assessmentId: 'asmt1',
        readinessScore: 55.0,
        examPrediction: 'Moderate Readiness',
        overallAccuracyPercentage: 50.0,
        skillGaps: [gap],
      );

      final recs = engine.generateRecommendations(
        analysis: analysis,
        assessmentId: 'asmt1',
      );

      expect(recs, hasLength(1));
      expect(recs.first.title, contains('Polity Emergency Provisions'));
    });
  });
}
