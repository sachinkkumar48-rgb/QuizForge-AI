import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/learner_objective_status.dart';
import 'package:garuda_learning/domain/entities/recommendation_effectiveness.dart';
import 'package:garuda_learning/domain/entities/recommendation_evidence_snapshot.dart';
import 'package:garuda_learning/domain/entities/recommendation_instance.dart';
import 'package:garuda_learning/domain/entities/recommendation_outcome.dart';
import 'package:garuda_learning/domain/entities/recommendation_type.dart';
import 'package:garuda_learning/domain/entities/session_configuration.dart';
import 'package:garuda_learning/service/recommendation_effectiveness_evaluator.dart';

void main() {
  group('RecommendationEffectivenessEvaluator Tests (P22 Stage 4)', () {
    const evaluator = RecommendationEffectivenessEvaluator();
    final testAsOf = DateTime.utc(2026, 8, 20, 12, 0, 0);

    final testInstance = RecommendationInstance(
      instanceId: 'inst-eval-001',
      learnerId: 'learner-eval-001',
      objectiveId: 'lo-eval-001',
      recommendationId: 'rec-eval-001',
      recommendationType: RecommendationType.prerequisiteGap,
      priorityScore: 0.85,
      rationale: 'Prerequisite remediation for fundamental rights',
      suggestedConfig: SessionConfiguration(
        learnerId: 'learner-eval-001',
        objectiveIds: ['lo-eval-001'],
        questionLimit: 5,
      ),
      issuedAt: DateTime.utc(2026, 8, 15, 10, 0, 0),
    );

    test('Scenario A: No outcome -> insufficient evidence', () {
      final snapshot = RecommendationEvidenceSnapshot(
        reviewUrgencyFactor: 0.8,
        prerequisiteBlockerFactor: 0.5,
        weakDomainFactor: 0.4,
        curriculumAdvancementFactor: 0.3,
        practiceDensityFactor: 0.2,
        baselineAccuracy: 0.50,
        baselineAttemptsCount: 10,
        baselineStatus: LearnerObjectiveStatus.inProgress,
      );

      final result = evaluator.evaluate(
        instance: testInstance,
        outcome: null,
        evidenceSnapshot: snapshot,
        asOf: testAsOf,
      );

      expect(result.insufficientEvidence, isTrue);
      expect(result.followUpAccuracy, isNull);
      expect(result.followUpAttemptsCount, equals(0));
      expect(result.observedPerformanceDelta, isNull);
      expect(
        result.category,
        equals(EffectivenessCategory.insufficientEvidence),
      );
    });

    test('Scenario B: Baseline unavailable -> insufficient evidence', () {
      final outcome = RecommendationOutcome(
        outcomeId: 'out-001',
        instanceId: testInstance.instanceId,
        sessionId: 'session-001',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.80,
        isCompleted: true,
        evaluatedAt: testAsOf,
      );

      final result = evaluator.evaluate(
        instance: testInstance,
        outcome: outcome,
        evidenceSnapshot: null,
        asOf: testAsOf,
      );

      expect(result.insufficientEvidence, isTrue);
      expect(result.baselineAccuracy, isNull);
      expect(result.baselineAttemptsCount, equals(0));
      expect(result.observedPerformanceDelta, isNull);
      expect(
        result.category,
        equals(EffectivenessCategory.insufficientEvidence),
      );
    });

    test('Scenario C: Baseline + Follow-up available -> observed improvement',
        () {
      final snapshot = RecommendationEvidenceSnapshot(
        reviewUrgencyFactor: 0.7,
        prerequisiteBlockerFactor: 0.6,
        weakDomainFactor: 0.5,
        curriculumAdvancementFactor: 0.4,
        practiceDensityFactor: 0.3,
        baselineAccuracy: 0.40,
        baselineAttemptsCount: 10,
        baselineStatus: LearnerObjectiveStatus.inProgress,
      );

      final outcome = RecommendationOutcome(
        outcomeId: 'out-002',
        instanceId: testInstance.instanceId,
        sessionId: 'session-002',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.80,
        isCompleted: true,
        evaluatedAt: testAsOf,
      );

      final result = evaluator.evaluate(
        instance: testInstance,
        outcome: outcome,
        evidenceSnapshot: snapshot,
        asOf: testAsOf,
      );

      expect(result.insufficientEvidence, isFalse);
      expect(result.baselineAccuracy, equals(0.40));
      expect(result.followUpAccuracy, equals(0.80));
      expect(result.observedPerformanceDelta, closeTo(0.40, 0.0001));
      expect(
        result.category,
        equals(EffectivenessCategory.observedImprovement),
      );
    });

    test('Scenario D: Observed decline', () {
      final snapshot = RecommendationEvidenceSnapshot(
        reviewUrgencyFactor: 0.5,
        prerequisiteBlockerFactor: 0.5,
        weakDomainFactor: 0.5,
        curriculumAdvancementFactor: 0.5,
        practiceDensityFactor: 0.5,
        baselineAccuracy: 0.75,
        baselineAttemptsCount: 8,
        baselineStatus: LearnerObjectiveStatus.achieved,
      );

      final outcome = RecommendationOutcome(
        outcomeId: 'out-003',
        instanceId: testInstance.instanceId,
        sessionId: 'session-003',
        totalQuestionsScheduled: 10,
        totalQuestionsAttempted: 10,
        sessionAccuracy: 0.50,
        isCompleted: true,
        evaluatedAt: testAsOf,
      );

      final result = evaluator.evaluate(
        instance: testInstance,
        outcome: outcome,
        evidenceSnapshot: snapshot,
        asOf: testAsOf,
      );

      expect(result.insufficientEvidence, isFalse);
      expect(result.observedPerformanceDelta, closeTo(-0.25, 0.0001));
      expect(
        result.category,
        equals(EffectivenessCategory.observedDecline),
      );
    });

    test('Scenario E: No measurable change', () {
      final snapshot = RecommendationEvidenceSnapshot(
        reviewUrgencyFactor: 0.5,
        prerequisiteBlockerFactor: 0.5,
        weakDomainFactor: 0.5,
        curriculumAdvancementFactor: 0.5,
        practiceDensityFactor: 0.5,
        baselineAccuracy: 0.60,
        baselineAttemptsCount: 10,
        baselineStatus: LearnerObjectiveStatus.inProgress,
      );

      final outcome = RecommendationOutcome(
        outcomeId: 'out-004',
        instanceId: testInstance.instanceId,
        sessionId: 'session-004',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.60,
        isCompleted: true,
        evaluatedAt: testAsOf,
      );

      final result = evaluator.evaluate(
        instance: testInstance,
        outcome: outcome,
        evidenceSnapshot: snapshot,
        asOf: testAsOf,
      );

      expect(result.insufficientEvidence, isFalse);
      expect(result.observedPerformanceDelta, closeTo(0.0, 0.0001));
      expect(
        result.category,
        equals(EffectivenessCategory.noMeasurableChange),
      );
    });

    test('Scenario F: Zero follow-up attempts -> insufficient evidence', () {
      final snapshot = RecommendationEvidenceSnapshot(
        reviewUrgencyFactor: 0.5,
        prerequisiteBlockerFactor: 0.5,
        weakDomainFactor: 0.5,
        curriculumAdvancementFactor: 0.5,
        practiceDensityFactor: 0.5,
        baselineAccuracy: 0.60,
        baselineAttemptsCount: 10,
        baselineStatus: LearnerObjectiveStatus.inProgress,
      );

      final outcome = RecommendationOutcome(
        outcomeId: 'out-005',
        instanceId: testInstance.instanceId,
        sessionId: 'session-005',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 0,
        sessionAccuracy: null,
        isCompleted: false,
        evaluatedAt: testAsOf,
      );

      final result = evaluator.evaluate(
        instance: testInstance,
        outcome: outcome,
        evidenceSnapshot: snapshot,
        asOf: testAsOf,
      );

      expect(result.insufficientEvidence, isTrue);
      expect(result.followUpAccuracy, isNull);
      expect(result.observedPerformanceDelta, isNull);
      expect(
        result.category,
        equals(EffectivenessCategory.insufficientEvidence),
      );
    });
  });
}
