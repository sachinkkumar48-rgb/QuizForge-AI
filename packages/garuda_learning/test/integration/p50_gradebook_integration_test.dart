/// P50 Gradebook & Publishing Integration Test (TITAN-KO-050.0).
///
/// Implements the mandatory Section 19 closed-loop acceptance scenario:
/// Assessment Attempt Evaluated (P49)
///   ↓
/// Faculty Reviews in Gradebook (P50)
///   ↓
/// Faculty Publishes Grade
///   ↓
/// Learner Views Official Grade
///   ↓
/// Learner Submits Grade Dispute
///   ↓
/// Faculty Reviews & Overrides Grade with Rationale
///   ↓
/// Learner Views Updated Official Grade
///   ↓
/// Audit Trail & Immutability Verification
///   ↓
/// Process Restart Persistence Verification
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart' show StructuredAnswer;
import 'package:garuda_learning/garuda_learning.dart';

class _IntegrationMockQuestion implements IQuestionEntity {
  @override
  final String id;
  @override
  final String prompt;
  @override
  final List<String> options;
  @override
  final String expectedAnswer;

  const _IntegrationMockQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.expectedAnswer,
  });

  @override
  String? get explanation => 'Integration explanation';
  @override
  String get provenance => 'TITAN Acceptance';
  @override
  List<String> get objectiveIds => const ['obj_acceptance'];
  @override
  QuestionExamMetadata? get examMetadata => null;
  @override
  String get questionId => id;
  @override
  String get questionText => prompt;
  @override
  StructuredAnswer get answer => StructuredAnswer(
        answerText: expectedAnswer,
        evidenceRefs: const ['ev:001'],
        principles: const ['rule_of_law'],
        provenance: provenance,
      );
  @override
  String get framing => 'Direct';
  @override
  List<String> get sourceRefs => const ['src:acc:001'];
}

void main() {
  group('P50 Section 19 Mandatory Closed-Loop Acceptance Scenario', () {
    late InMemoryAssessmentRepository assessmentRepo;
    late InMemoryCohortRepository cohortRepo;
    late InMemoryGradebookRepository gradebookRepo;
    late InMemoryQuestionProvider questionProvider;
    late AssessmentManagementService assessmentService;
    late GradebookService gradebookService;

    final q1 = const _IntegrationMockQuestion(
      id: 'q_acc_1',
      prompt: 'What is Article 21?',
      options: ['Life & Liberty', 'Finance', 'Tax', 'Trade'],
      expectedAnswer: 'Life & Liberty',
    );
    final q2 = const _IntegrationMockQuestion(
      id: 'q_acc_2',
      prompt: 'What is Article 14?',
      options: ['Equality', 'Emergency', 'Panchayat', 'Civil Service'],
      expectedAnswer: 'Equality',
    );

    setUp(() {
      assessmentRepo = InMemoryAssessmentRepository();
      cohortRepo = InMemoryCohortRepository();
      gradebookRepo = InMemoryGradebookRepository();
      questionProvider = InMemoryQuestionProvider([q1, q2]);

      assessmentService = AssessmentManagementService(
        repository: assessmentRepo,
        questionProvider: questionProvider,
        cohortRepository: cohortRepo,
      );

      gradebookService = GradebookService(
        repository: gradebookRepo,
      );
    });

    test('Full End-to-End Closed-Loop Workflow Execution', () async {
      const cohortId = 'cohort_titan_flagship';
      const facultyId = 'faculty_director';
      const learnerId = 'learner_siddharth';

      // 1. Provision cohort and assessment
      final cohort = Cohort(
        cohortId: cohortId,
        tenantId: 'tenant_default',
        name: 'TITAN Flagship Cohort',
        examId: 'upsc_prelims',
        primaryFacultyId: facultyId,
        learnerIds: [learnerId],
      );
      await cohortRepo.saveCohort(cohort);

      final assessment = await assessmentService.createAssessment(
        assessmentId: 'assess_final_law',
        title: 'Constitutional Law Final',
        examId: 'upsc_prelims',
        creatorFacultyId: facultyId,
        questionIds: ['q_acc_1', 'q_acc_2'],
        marksConfig: const AssessmentMarksConfig(
          marksPerQuestion: 50.0,
          negativeMarkRatio: 0.0,
          passingPercentage: 50.0,
        ),
        cohortIds: [cohortId],
      );

      await assessmentService.publishAssessment(assessment.assessmentId,
          facultyId: facultyId);

      // 2. Learner takes attempt and submits: 1 correct, 1 incorrect -> 50/100 (P49)
      final attempt = await assessmentService.startAttempt(
        assessmentId: assessment.assessmentId,
        learnerId: learnerId,
      );

      await assessmentService.recordAnswer(
        attemptId: attempt.attemptId,
        learnerId: learnerId,
        questionId: 'q_acc_1',
        answer: 'Life & Liberty', // Correct (+50)
      );
      await assessmentService.recordAnswer(
        attemptId: attempt.attemptId,
        learnerId: learnerId,
        questionId: 'q_acc_2',
        answer: 'Emergency', // Incorrect (0)
      );

      final result = await assessmentService.submitAttempt(
        attemptId: attempt.attemptId,
        learnerId: learnerId,
      );

      expect(result.score, equals(50.0));
      expect(result.maxScore, equals(100.0));
      expect(result.percentage, equals(50.0));
      expect(result.isPassed, isTrue);

      // 3. Evaluation bridges into Gradebook (P50) as evaluated and unpublished
      final gradebookEntry = await gradebookService.ingestAssessmentResult(
        entryId: 'gb_${result.resultId}',
        tenantId: 'tenant_default',
        cohortId: cohortId,
        assessmentId: assessment.assessmentId,
        learnerId: learnerId,
        resultId: result.resultId,
        originalScore: result.score,
        maxScore: result.maxScore,
        autoPublish: false,
      );

      expect(gradebookEntry.isPublished, isFalse);
      expect(gradebookEntry.gradingStatus, equals(GradingStatus.evaluated));

      // 4. Faculty reviews in Cohort Gradebook
      final cohortGb = await gradebookService.getCohortGradebook(cohortId,
          facultyId: facultyId);
      expect(cohortGb.enrolledLearners, contains(learnerId));
      expect(
          cohortGb.matrix[learnerId]?[assessment.assessmentId]?.originalScore,
          equals(50.0));

      // 5. Learner cannot see unpublished grade
      final officialGradesPrePublish =
          await gradebookService.getOfficialGradesForLearner(
        learnerId,
        cohortId: cohortId,
      );
      expect(officialGradesPrePublish, isEmpty);

      // 6. Faculty publishes the grade
      final publishedEntry = await gradebookService.publishGrade(
        gradebookEntry.entryId,
        facultyId: facultyId,
      );
      expect(publishedEntry.isPublished, isTrue);

      // 7. Learner now sees official published grade
      final officialGradesPostPublish =
          await gradebookService.getOfficialGradesForLearner(
        learnerId,
        cohortId: cohortId,
      );
      expect(officialGradesPostPublish.length, equals(1));
      final officialGrade = officialGradesPostPublish.first;
      expect(officialGrade.finalScore, equals(50.0));
      expect(
          officialGrade.letterGrade, equals('C')); // 50% = C in standard policy
      expect(officialGrade.isPassed, isTrue);

      // 8. Learner disputes grade (believes question 2 should have partial credit)
      final dispute = await gradebookService.createDispute(
        learnerId: learnerId,
        entryId: officialGrade.entryId,
        assessmentId: assessment.assessmentId,
        reason:
            'Question 2 emergency provisions link directly to fundamental rights doctrine',
      );
      expect(dispute.status, equals(GradeDisputeStatus.open));

      // 9. Faculty reviews dispute
      await gradebookService.reviewDispute(dispute.disputeId,
          facultyId: facultyId);

      // 10. Faculty resolves dispute with override (+20 marks for deep doctrinal argument)
      final resolvedDispute = await gradebookService.resolveDisputeWithOverride(
        dispute.disputeId,
        newScore: 70.0,
        rationale:
            'Awarded 20 marks discretionary moderation for doctrinal connection',
        facultyId: facultyId,
      );
      expect(resolvedDispute.status, equals(GradeDisputeStatus.resolved));

      // 11. Immutability check: original result score & percentage remain 100% intact!
      final entryAfterOverride =
          await gradebookService.getEntry(officialGrade.entryId);
      expect(entryAfterOverride.originalScore, equals(50.0));
      expect(entryAfterOverride.originalPercentage, equals(50.0));
      expect(entryAfterOverride.finalScore, equals(70.0));
      expect(entryAfterOverride.finalPercentage, equals(70.0));
      expect(entryAfterOverride.letterGrade, equals('B')); // 70% = B
      expect(entryAfterOverride.isOverridden, isTrue);

      // 12. Learner views updated official grade
      final updatedOfficialGrades =
          await gradebookService.getOfficialGradesForLearner(
        learnerId,
        cohortId: cohortId,
      );
      expect(updatedOfficialGrades.first.finalScore, equals(70.0));
      expect(updatedOfficialGrades.first.letterGrade, equals('B'));

      // 13. Audit Trail Verification
      final auditTrail =
          await gradebookService.getAuditTrail(officialGrade.entryId);
      final actions = auditTrail.map((a) => a.action).toList();
      expect(
          actions,
          containsAll([
            GradeAuditAction.created,
            GradeAuditAction.published,
            GradeAuditAction.disputed,
            GradeAuditAction.overridden,
            GradeAuditAction.disputeResolved,
          ]));

      // 14. Restart Persistence Verification
      final snapshot = await gradebookRepo.exportSnapshot();
      final freshRepo = InMemoryGradebookRepository();
      await freshRepo.importSnapshot(snapshot);
      final freshService = GradebookService(repository: freshRepo);

      final persistedEntry = await freshService.getEntry(officialGrade.entryId);
      expect(persistedEntry.originalScore, equals(50.0));
      expect(persistedEntry.finalScore, equals(70.0));
      expect(persistedEntry.letterGrade, equals('B'));
      expect(persistedEntry.isPublished, isTrue);
      expect(persistedEntry.isOverridden, isTrue);

      final persistedDisputes =
          await freshService.getDisputesForCohort(cohortId);
      expect(persistedDisputes.length, equals(1));
      expect(
          persistedDisputes.first.status, equals(GradeDisputeStatus.resolved));

      final persistedAudits =
          await freshService.getAuditTrail(officialGrade.entryId);
      expect(persistedAudits.length, equals(auditTrail.length));
    });
  });
}
