import 'package:flutter_test/flutter_test.dart';
import 'package:titan_smart_assessment/titan_smart_assessment.dart';

void main() {
  group('Smart Assessment Models Tests', () {
    test('AssessmentBlueprint serialization and copyWith', () {
      const blueprint = AssessmentBlueprint(
        id: 'bp1',
        title: 'Polity Special Blueprint',
        subjectCategory: 'Polity',
        totalQuestions: 20,
        timeLimitMinutes: 40,
      );

      final json = blueprint.toJson();
      final restored = AssessmentBlueprint.fromJson(json);

      expect(restored.id, equals('bp1'));
      expect(restored.totalQuestions, equals(20));
      expect(restored, equals(blueprint));

      final updated = blueprint.copyWith(totalQuestions: 25);
      expect(updated.totalQuestions, equals(25));
    });

    test('AssessmentAttempt serialization and copyWith', () {
      final now = DateTime.now();
      final attempt = AssessmentAttempt(
        id: 'att1',
        sessionId: 's1',
        questionId: 'q1',
        selectedOptionId: 'optA',
        isCorrect: true,
        pointsEarned: 2.0,
        timeSpentSeconds: 45,
        confidenceLevel: 0.9,
        timestamp: now,
      );

      final json = attempt.toJson();
      final restored = AssessmentAttempt.fromJson(json);

      expect(restored.id, equals('att1'));
      expect(restored.isCorrect, isTrue);
      expect(restored.pointsEarned, equals(2.0));

      final updated = attempt.copyWith(isCorrect: false);
      expect(updated.isCorrect, isFalse);
    });

    test('AssessmentResult and AssessmentAnalysis serialization', () {
      final now = DateTime.now();
      const analysis = AssessmentAnalysis(
        id: 'an1',
        assessmentId: 'asmt1',
        readinessScore: 85.0,
        examPrediction: 'High Probability',
        overallAccuracyPercentage: 80.0,
      );

      final result = AssessmentResult(
        id: 'res1',
        assessmentId: 'asmt1',
        userId: 'u1',
        score: 160.0,
        totalPossibleScore: 200.0,
        percentage: 80.0,
        gradeLevel: GradeLevel.advanced,
        completedAt: now,
        analysis: analysis,
      );

      final json = result.toJson();
      final restored = AssessmentResult.fromJson(json);

      expect(restored.id, equals('res1'));
      expect(restored.percentage, equals(80.0));
      expect(restored.gradeLevel, equals(GradeLevel.advanced));
      expect(restored.analysis?.readinessScore, equals(85.0));
    });

    test('SkillGap, QuestionStatistics, TopicStatistics models', () {
      final gap = SkillGap(
        id: 'g1',
        conceptId: 'c1',
        conceptTitle: 'Preamble',
        gapSeverity: 'High',
        recommendedAction: 'Revise notes',
        identifiedAt: DateTime.now(),
      );
      expect(gap.gapSeverity, equals('High'));

      const qStats = QuestionStatistics(
        questionId: 'q1',
        timesAttempted: 10,
        timesCorrect: 8,
      );
      expect(qStats.accuracyRate, equals(80.0));

      const topicStats = TopicStatistics(
        topicId: 't1',
        topicName: 'Polity',
        accuracyPercentage: 75.0,
      );
      expect(topicStats.accuracyPercentage, equals(75.0));
    });
  });
}
