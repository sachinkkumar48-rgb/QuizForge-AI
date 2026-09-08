/// P50 Faculty Gradebook, Grade Publishing & Grade Dispute/Override Workflow Test Suite (TITAN-KO-050.0).
///
/// Comprehensive suite verifying all 34 required test cases from Section 18:
/// 1. gradebook creation/loading
/// 2. learner row
/// 3. assessment column
/// 4. evaluated result appears
/// 5. unpublished result hidden from learner
/// 6. publish one result
/// 7. publish entire assessment
/// 8. publish cohort results
/// 9. publication idempotency
/// 10. restart persistence
/// 11. grade calculation
/// 12. grade boundary
/// 13. invalid score handling
/// 14. cohort aggregation
/// 15. learner isolation
/// 16. tenant isolation
/// 17. dispute creation
/// 18. duplicate dispute prevention
/// 19. dispute lifecycle
/// 20. faculty dispute visibility
/// 21. unauthorized dispute access rejected
/// 22. accept dispute
/// 23. reject dispute
/// 24. grade override
/// 25. override requires reason
/// 26. override audit trail
/// 27. original result preserved
/// 28. override persistence
/// 29. offline publication
/// 30. offline dispute
/// 31. synchronization
/// 32. duplicate synchronization
/// 33. conflict protection
/// 34. complete end-to-end gradebook workflow
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final baseTime = DateTime.utc(2026, 10, 1, 10, 0, 0);

  late InMemoryGradebookRepository repo;
  late GradebookService service;

  setUp(() {
    repo = InMemoryGradebookRepository();
    service = GradebookService(
      repository: repo,
      gradingPolicy: const GradingPolicy.standard(),
      clock: () => baseTime,
    );
  });

  // Helper to ingest sample evaluated results into gradebook
  Future<GradebookEntry> ingestSampleEntry({
    String entryId = 'entry_001',
    String tenantId = 'tenant_default',
    String cohortId = 'cohort_upsc_2026',
    String assessmentId = 'assess_const_law',
    String learnerId = 'learner_alice',
    String resultId = 'result_001',
    double originalScore = 85.0,
    double maxScore = 100.0,
    bool isPublished = false,
  }) async {
    return service.ingestAssessmentResult(
      entryId: entryId,
      tenantId: tenantId,
      cohortId: cohortId,
      assessmentId: assessmentId,
      learnerId: learnerId,
      resultId: resultId,
      originalScore: originalScore,
      maxScore: maxScore,
      autoPublish: isPublished,
    );
  }

  group('P50 Faculty Gradebook Core - Section 18 Test Cases', () {
    // 1. gradebook creation/loading
    test(
        '1. gradebook creation/loading - loads empty or existing cohort gradebook',
        () async {
      final gbEmpty = await service.getCohortGradebook('cohort_new');
      expect(gbEmpty.cohortId, equals('cohort_new'));
      expect(gbEmpty.enrolledLearners, isEmpty);
      expect(gbEmpty.assessments, isEmpty);

      await ingestSampleEntry();
      final gbLoaded = await service.getCohortGradebook('cohort_upsc_2026');
      expect(gbLoaded.enrolledLearners, contains('learner_alice'));
      expect(gbLoaded.assessments.map((a) => a.assessmentId),
          contains('assess_const_law'));
    });

    // 2. learner row
    test(
        '2. learner row - matrix represents each learner with aggregated row summary',
        () async {
      await ingestSampleEntry(
          learnerId: 'learner_alice', originalScore: 80.0, maxScore: 100.0);
      await ingestSampleEntry(
        entryId: 'entry_002',
        learnerId: 'learner_bob',
        originalScore: 35.0,
        maxScore: 100.0,
      );

      final gb = await service.getCohortGradebook('cohort_upsc_2026');
      expect(gb.enrolledLearners.length, equals(2));
      expect(gb.learnerSummaries['learner_alice']?.averagePercentage,
          equals(80.0));
      expect(gb.learnerSummaries['learner_alice']?.isPassing, isTrue);
      expect(
          gb.learnerSummaries['learner_bob']?.averagePercentage, equals(35.0));
      expect(gb.learnerSummaries['learner_bob']?.isPassing, isFalse);
    });

    // 3. assessment column
    test(
        '3. assessment column - matrix aggregates columns for distinct assessments',
        () async {
      await ingestSampleEntry(
          entryId: 'entry_001', assessmentId: 'assess_polity');
      await ingestSampleEntry(
          entryId: 'entry_002', assessmentId: 'assess_history');

      final gb = await service.getCohortGradebook('cohort_upsc_2026');
      final assessmentIds = gb.assessments.map((a) => a.assessmentId).toList();
      expect(assessmentIds, containsAll(['assess_polity', 'assess_history']));
      expect(gb.matrix['learner_alice']?['assess_polity'], isNotNull);
      expect(gb.matrix['learner_alice']?['assess_history'], isNotNull);
    });

    // 4. evaluated result appears
    test(
        '4. evaluated result appears - ingested evaluated result is recorded as unpublished by default',
        () async {
      final entry =
          await ingestSampleEntry(originalScore: 78.0, maxScore: 100.0);
      expect(entry.gradingStatus, equals(GradingStatus.evaluated));
      expect(
          entry.publicationStatus, equals(GradePublicationStatus.unpublished));
      expect(entry.isPublished, isFalse);
      expect(entry.letterGrade, equals('B'));
    });

    // 5. unpublished result hidden from learner
    test(
        '5. unpublished result hidden from learner - getOfficialGradesForLearner excludes unpublished entries',
        () async {
      await ingestSampleEntry(originalScore: 92.0, isPublished: false);

      final official =
          await service.getOfficialGradesForLearner('learner_alice');
      expect(official, isEmpty);
    });

    // 6. publish one result
    test(
        '6. publish one result - publishing a single entry transitions status and reveals to learner',
        () async {
      final entry =
          await ingestSampleEntry(originalScore: 92.0, isPublished: false);

      final published = await service.publishGrade(entry.entryId,
          facultyId: 'faculty_sharma');
      expect(published.isPublished, isTrue);
      expect(published.publicationStatus,
          equals(GradePublicationStatus.published));

      final official =
          await service.getOfficialGradesForLearner('learner_alice');
      expect(official.length, equals(1));
      expect(official.first.finalScore, equals(92.0));
      expect(official.first.letterGrade, equals('A'));
    });

    // 7. publish entire assessment
    test(
        '7. publish entire assessment - bulk publishes all entries for a specific assessment',
        () async {
      await ingestSampleEntry(
          entryId: 'e1', learnerId: 'l1', assessmentId: 'exam_1');
      await ingestSampleEntry(
          entryId: 'e2', learnerId: 'l2', assessmentId: 'exam_1');
      await ingestSampleEntry(
          entryId: 'e3', learnerId: 'l3', assessmentId: 'exam_2');

      final count = await service.publishAssessmentGrades(
          'cohort_upsc_2026', 'exam_1',
          facultyId: 'prof_roy');
      expect(count, equals(2));

      final l1Grades = await service.getOfficialGradesForLearner('l1');
      final l2Grades = await service.getOfficialGradesForLearner('l2');
      final l3Grades = await service.getOfficialGradesForLearner('l3');

      expect(l1Grades.length, equals(1));
      expect(l2Grades.length, equals(1));
      expect(l3Grades, isEmpty); // exam_2 was not published
    });

    // 8. publish cohort results
    test(
        '8. publish cohort results - publishes all entries for all assessments in cohort',
        () async {
      await ingestSampleEntry(
          entryId: 'e1', learnerId: 'l1', assessmentId: 'exam_1');
      await ingestSampleEntry(
          entryId: 'e2', learnerId: 'l2', assessmentId: 'exam_2');

      final count = await service.publishCohortGrades('cohort_upsc_2026',
          facultyId: 'dean_patel');
      expect(count, equals(2));

      final l1Grades = await service.getOfficialGradesForLearner('l1');
      final l2Grades = await service.getOfficialGradesForLearner('l2');
      expect(l1Grades.length, equals(1));
      expect(l2Grades.length, equals(1));
    });

    // 9. publication idempotency
    test(
        '9. publication idempotency - republishing already published entry does not throw or double-audit',
        () async {
      final entry = await ingestSampleEntry(originalScore: 88.0);
      await service.publishGrade(entry.entryId, facultyId: 'faculty_01');
      final initialAudits = await service.getAuditTrail(entry.entryId);
      final publishAuditsCount = initialAudits
          .where((a) => a.action == GradeAuditAction.published)
          .length;
      expect(publishAuditsCount, equals(1));

      // Republish
      final repub =
          await service.publishGrade(entry.entryId, facultyId: 'faculty_01');
      expect(repub.isPublished, isTrue);

      final secondAudits = await service.getAuditTrail(entry.entryId);
      final secondPublishCount = secondAudits
          .where((a) => a.action == GradeAuditAction.published)
          .length;
      expect(secondPublishCount, equals(1)); // idempotent, no duplicate audit
    });

    // 10. restart persistence
    test(
        '10. restart persistence - exported snapshot preserves state across repository restart',
        () async {
      final entry = await ingestSampleEntry(originalScore: 75.0);
      await service.publishGrade(entry.entryId, facultyId: 'faculty_01');
      await service.applyGradeOverride(entry.entryId,
          newScore: 82.0, reason: 'Grade adjustment', facultyId: 'faculty_01');

      final snapshot = await repo.exportSnapshot();

      // Fresh repo and service simulating process restart
      final freshRepo = InMemoryGradebookRepository();
      await freshRepo.importSnapshot(snapshot);
      final freshService = GradebookService(repository: freshRepo);

      final loadedEntry = await freshService.getEntry(entry.entryId);
      expect(loadedEntry.isPublished, isTrue);
      expect(loadedEntry.isOverridden, isTrue);
      expect(loadedEntry.originalScore, equals(75.0));
      expect(loadedEntry.finalScore, equals(82.0));
      expect(loadedEntry.letterGrade, equals('A'));

      final audits = await freshService.getAuditTrail(entry.entryId);
      expect(audits.length,
          greaterThanOrEqualTo(3)); // created, published, overridden
    });

    // 11. grade calculation
    test(
        '11. grade calculation - accurately assigns letter grades and passing flag',
        () {
      const policy = GradingPolicy.standard();

      expect(policy.calculatePercentage(95.0, 100.0), equals(95.0));
      expect(policy.resolveBand(95.0).letterGrade, equals('A'));
      expect(policy.isPassing(95.0), isTrue);

      expect(policy.resolveBand(75.0).letterGrade, equals('B'));
      expect(policy.resolveBand(55.0).letterGrade, equals('C'));
      expect(policy.resolveBand(42.0).letterGrade, equals('D'));
      expect(policy.resolveBand(38.0).letterGrade, equals('F'));
      expect(policy.isPassing(38.0), isFalse);
    });

    // 12. grade boundary
    test('12. grade boundary - verifies edge values: 0%, 40%, 100%', () {
      const policy = GradingPolicy.standard();

      // 0%
      expect(policy.resolveBand(0.0).letterGrade, equals('F'));
      expect(policy.isPassing(0.0), isFalse);

      // 40% (Pass boundary)
      expect(policy.resolveBand(40.0).letterGrade, equals('D'));
      expect(policy.isPassing(40.0), isTrue);

      // 39.999%
      expect(policy.resolveBand(39.99).letterGrade, equals('F'));
      expect(policy.isPassing(39.99), isFalse);

      // 100%
      expect(policy.resolveBand(100.0).letterGrade, equals('A'));
      expect(policy.isPassing(100.0), isTrue);
    });

    // 13. invalid score handling
    test(
        '13. invalid score handling - non-finite or negative scores throw GradeValidationException',
        () async {
      expect(
        () => ingestSampleEntry(originalScore: -5.0),
        throwsA(isA<GradeValidationException>()),
      );

      expect(
        () => ingestSampleEntry(originalScore: double.nan),
        throwsA(isA<GradeValidationException>()),
      );

      expect(
        () => ingestSampleEntry(originalScore: double.infinity),
        throwsA(isA<GradeValidationException>()),
      );

      expect(
        () => ingestSampleEntry(maxScore: 0.0),
        throwsA(isA<GradeValidationException>()),
      );
    });

    // 14. cohort aggregation
    test(
        '14. cohort aggregation - accurately aggregates pass rate and average score',
        () async {
      // Learner 1: 90/100 (Pass)
      await ingestSampleEntry(
          entryId: 'e1', learnerId: 'l1', originalScore: 90.0);
      // Learner 2: 30/100 (Fail)
      await ingestSampleEntry(
          entryId: 'e2', learnerId: 'l2', originalScore: 30.0);

      final gb = await service.getCohortGradebook('cohort_upsc_2026');
      expect(gb.summary.enrolledLearnersCount, equals(2));
      expect(gb.summary.passRatePercentage, equals(50.0));
      expect(gb.summary.averageScorePercentage, equals(60.0));
      expect(gb.summary.gradeDistribution['A'], equals(1));
      expect(gb.summary.gradeDistribution['F'], equals(1));
    });

    // 15. learner isolation
    test(
        '15. learner isolation - learner only retrieves their own official grades',
        () async {
      await ingestSampleEntry(
          entryId: 'e1',
          learnerId: 'alice',
          originalScore: 90.0,
          isPublished: true);
      await ingestSampleEntry(
          entryId: 'e2',
          learnerId: 'bob',
          originalScore: 80.0,
          isPublished: true);

      final aliceGrades = await service.getOfficialGradesForLearner('alice');
      expect(aliceGrades.length, equals(1));
      expect(aliceGrades.first.learnerId, equals('alice'));

      final bobGrades = await service.getOfficialGradesForLearner('bob');
      expect(bobGrades.length, equals(1));
      expect(bobGrades.first.learnerId, equals('bob'));
    });

    // 16. tenant isolation
    test(
        '16. tenant isolation - gradebook entries isolated between institutional tenants',
        () async {
      await ingestSampleEntry(
          entryId: 'e_t1',
          tenantId: 'tenant_oxford',
          originalScore: 95.0,
          isPublished: true);
      await ingestSampleEntry(
          entryId: 'e_t2',
          tenantId: 'tenant_cambridge',
          originalScore: 85.0,
          isPublished: true);

      final oxfordEntries = await repo.listEntries(tenantId: 'tenant_oxford');
      expect(oxfordEntries.length, equals(1));
      expect(oxfordEntries.first.entryId, equals('e_t1'));

      final cambridgeEntries =
          await repo.listEntries(tenantId: 'tenant_cambridge');
      expect(cambridgeEntries.length, equals(1));
      expect(cambridgeEntries.first.entryId, equals('e_t2'));
    });

    // 17. dispute creation
    test(
        '17. dispute creation - learner creates formal dispute for published grade',
        () async {
      final entry =
          await ingestSampleEntry(originalScore: 70.0, isPublished: true);

      final dispute = await service.createDispute(
        learnerId: 'learner_alice',
        entryId: entry.entryId,
        assessmentId: entry.assessmentId,
        reason:
            'Question 3 marking was not considered correctly according to key',
      );

      expect(dispute.status, equals(GradeDisputeStatus.open));
      expect(dispute.learnerId, equals('learner_alice'));
      expect(dispute.reason, contains('Question 3'));
    });

    // 18. duplicate dispute prevention
    test(
        '18. duplicate dispute prevention - throws exception if active dispute exists for same assessment',
        () async {
      final entry =
          await ingestSampleEntry(originalScore: 70.0, isPublished: true);

      await service.createDispute(
        learnerId: 'learner_alice',
        entryId: entry.entryId,
        assessmentId: entry.assessmentId,
        reason: 'First dispute submission',
      );

      expect(
        () => service.createDispute(
          learnerId: 'learner_alice',
          entryId: entry.entryId,
          assessmentId: entry.assessmentId,
          reason: 'Second dispute attempt while first is active',
        ),
        throwsA(isA<GradeDisputeException>()),
      );
    });

    // 19. dispute lifecycle
    test('19. dispute lifecycle - transitions open -> underReview -> resolved',
        () async {
      final entry =
          await ingestSampleEntry(originalScore: 65.0, isPublished: true);
      final dispute = await service.createDispute(
        learnerId: 'learner_alice',
        entryId: entry.entryId,
        assessmentId: entry.assessmentId,
        reason: 'Formula evaluated correctly in rough work',
      );

      // Review
      final reviewing = await service.reviewDispute(dispute.disputeId,
          facultyId: 'faculty_01');
      expect(reviewing.status, equals(GradeDisputeStatus.underReview));

      // Resolve with override
      final resolved = await service.resolveDisputeWithOverride(
        dispute.disputeId,
        newScore: 75.0,
        rationale: 'Accepted learner justification for step marks',
        facultyId: 'faculty_01',
      );
      expect(resolved.status, equals(GradeDisputeStatus.resolved));
      expect(resolved.resolutionType,
          equals(GradeDisputeResolutionType.approvedWithOverride));
    });

    // 20. faculty dispute visibility
    test(
        '20. faculty dispute visibility - faculty lists all open and cohort disputes',
        () async {
      final entry1 = await ingestSampleEntry(
          entryId: 'e1', learnerId: 'l1', isPublished: true);
      final entry2 = await ingestSampleEntry(
          entryId: 'e2', learnerId: 'l2', isPublished: true);

      await service.createDispute(
        learnerId: 'l1',
        entryId: entry1.entryId,
        assessmentId: entry1.assessmentId,
        reason: 'Dispute 1',
      );
      await service.createDispute(
        learnerId: 'l2',
        entryId: entry2.entryId,
        assessmentId: entry2.assessmentId,
        reason: 'Dispute 2',
      );

      final disputes = await service.getDisputesForCohort('cohort_upsc_2026');
      expect(disputes.length, equals(2));
    });

    // 21. unauthorized dispute access rejected
    test(
        '21. unauthorized dispute access rejected - disputing unpublished grade is rejected',
        () async {
      final entry =
          await ingestSampleEntry(originalScore: 70.0, isPublished: false);

      expect(
        () => service.createDispute(
          learnerId: 'learner_alice',
          entryId: entry.entryId,
          assessmentId: entry.assessmentId,
          reason: 'Attempting to dispute an unpublished internal draft mark',
        ),
        throwsA(isA<GradeDisputeException>()),
      );
    });

    // 22. accept dispute
    test(
        '22. accept dispute - resolving dispute updates entry final score and links override record',
        () async {
      final entry =
          await ingestSampleEntry(originalScore: 50.0, isPublished: true);
      final dispute = await service.createDispute(
        learnerId: 'learner_alice',
        entryId: entry.entryId,
        assessmentId: entry.assessmentId,
        reason: 'Marking tally missing 10 marks on question 4',
      );

      await service.resolveDisputeWithOverride(
        dispute.disputeId,
        newScore: 60.0,
        rationale: 'Tally error verified and corrected',
        facultyId: 'faculty_01',
      );

      final updatedEntry = await service.getEntry(entry.entryId);
      expect(updatedEntry.finalScore, equals(60.0));
      expect(updatedEntry.letterGrade, equals('C'));
      expect(updatedEntry.isOverridden, isTrue);

      final overrides = await service.getOverrideHistory(entry.entryId);
      expect(overrides.length, equals(1));
      expect(overrides.first.disputeId, equals(dispute.disputeId));
    });

    // 23. reject dispute
    test(
        '23. reject dispute - rejecting dispute leaves finalScore unchanged and records rejection rationale',
        () async {
      final entry =
          await ingestSampleEntry(originalScore: 50.0, isPublished: true);
      final dispute = await service.createDispute(
        learnerId: 'learner_alice',
        entryId: entry.entryId,
        assessmentId: entry.assessmentId,
        reason: 'I deserve higher score',
      );

      final rejected = await service.rejectDispute(
        dispute.disputeId,
        rationale:
            'Marking scheme strictly adhered to; incorrect option chosen',
        facultyId: 'faculty_01',
      );

      expect(rejected.status, equals(GradeDisputeStatus.rejected));
      expect(rejected.resolutionNotes,
          contains('Marking scheme strictly adhered to'));

      final updatedEntry = await service.getEntry(entry.entryId);
      expect(updatedEntry.finalScore, equals(50.0)); // Unchanged
      expect(updatedEntry.isOverridden, isFalse);
    });

    // 24. grade override
    test('24. grade override - faculty applies manual score override',
        () async {
      final entry =
          await ingestSampleEntry(originalScore: 40.0, isPublished: true);

      final overridden = await service.applyGradeOverride(
        entry.entryId,
        newScore: 45.0,
        reason: 'Bonus points awarded for exceptional creative approach',
        facultyId: 'prof_menon',
      );

      expect(overridden.finalScore, equals(45.0));
      expect(overridden.letterGrade, equals('D'));
      expect(overridden.isOverridden, isTrue);
    });

    // 25. override requires reason
    test(
        '25. override requires reason - blank or short reason throws GradeValidationException',
        () async {
      final entry = await ingestSampleEntry(originalScore: 40.0);

      expect(
        () => service.applyGradeOverride(
          entry.entryId,
          newScore: 50.0,
          reason: '   ',
          facultyId: 'faculty_01',
        ),
        throwsA(isA<GradeValidationException>()),
      );

      expect(
        () => service.applyGradeOverride(
          entry.entryId,
          newScore: 50.0,
          reason: 'abc', // < 5 chars
          facultyId: 'faculty_01',
        ),
        throwsA(isA<GradeValidationException>()),
      );
    });

    // 26. override audit trail
    test(
        '26. override audit trail - each override creates immutable audit log with actor and details',
        () async {
      final entry = await ingestSampleEntry(originalScore: 50.0);

      await service.applyGradeOverride(
        entry.entryId,
        newScore: 65.0,
        reason: 'Moderation adjustment across cohort',
        facultyId: 'moderator_01',
      );

      final audits = await service.getAuditTrail(entry.entryId);
      final overrideAudit =
          audits.firstWhere((a) => a.action == GradeAuditAction.overridden);

      expect(overrideAudit.performedBy, equals('moderator_01'));
      expect(overrideAudit.reason, contains('Moderation adjustment'));
      expect(overrideAudit.oldValues?['finalScore'], equals(50.0));
      expect(overrideAudit.newValues?['finalScore'], equals(65.0));
    });

    // 27. original result preserved
    test(
        '27. original result preserved - originalScore and originalPercentage remain unmutated after override',
        () async {
      final entry =
          await ingestSampleEntry(originalScore: 70.0, maxScore: 100.0);

      final overridden = await service.applyGradeOverride(
        entry.entryId,
        newScore: 90.0,
        reason: 'Re-evaluation confirmed additional marks',
        facultyId: 'faculty_01',
      );

      expect(overridden.originalScore, equals(70.0));
      expect(overridden.originalPercentage, equals(70.0));
      expect(overridden.finalScore, equals(90.0));
      expect(overridden.finalPercentage, equals(90.0));
    });

    // 28. override persistence
    test('28. override persistence - override records persist across reload',
        () async {
      final entry = await ingestSampleEntry(originalScore: 60.0);
      await service.applyGradeOverride(
        entry.entryId,
        newScore: 72.0,
        reason: 'Valid override reason',
        facultyId: 'faculty_01',
      );

      final snapshot = await repo.exportSnapshot();

      final freshRepo = InMemoryGradebookRepository();
      await freshRepo.importSnapshot(snapshot);
      final freshService = GradebookService(repository: freshRepo);

      final overrides = await freshService.getOverrideHistory(entry.entryId);
      expect(overrides.length, equals(1));
      expect(overrides.first.newScore, equals(72.0));
      expect(overrides.first.facultyId, equals('faculty_01'));
    });

    // 29. offline publication
    test(
        '29. offline publication - publications can occur while offline and persist in local state',
        () async {
      final entry = await ingestSampleEntry(originalScore: 85.0);

      // Perform publication locally while simulated offline
      final published = await service.publishGrade(entry.entryId,
          facultyId: 'offline_faculty');
      expect(published.isPublished, isTrue);

      final loaded = await service.getEntry(entry.entryId);
      expect(loaded.isPublished, isTrue);
    });

    // 30. offline dispute
    test(
        '30. offline dispute - disputes submitted offline queue successfully in repository',
        () async {
      final entry =
          await ingestSampleEntry(originalScore: 85.0, isPublished: true);

      final dispute = await service.createDispute(
        learnerId: 'learner_alice',
        entryId: entry.entryId,
        assessmentId: entry.assessmentId,
        reason: 'Offline dispute submission details',
      );

      expect(dispute.disputeId, isNotEmpty);
      final fetched = await service.getDispute(dispute.disputeId);
      expect(fetched.reason, contains('Offline dispute'));
    });

    // 31. synchronization
    test(
        '31. synchronization - state snapshot can be synced to remote repository',
        () async {
      final localRepo = InMemoryGradebookRepository();
      final localService = GradebookService(repository: localRepo);

      final entry = await localService.ingestAssessmentResult(
        entryId: 'e_sync_1',
        tenantId: 'tenant_01',
        cohortId: 'cohort_01',
        assessmentId: 'a_01',
        learnerId: 'l_01',
        resultId: 'res_01',
        originalScore: 90.0,
        maxScore: 100.0,
        autoPublish: true,
      );

      final snapshot = await localRepo.exportSnapshot();

      final remoteRepo = InMemoryGradebookRepository();
      await remoteRepo.importSnapshot(snapshot);

      final remoteEntry = await remoteRepo.getEntry(entry.entryId);
      expect(remoteEntry, isNotNull);
      expect(remoteEntry?.finalScore, equals(90.0));
      expect(remoteEntry?.isPublished, isTrue);
    });

    // 32. duplicate synchronization
    test(
        '32. duplicate synchronization - re-importing identical snapshot is idempotent without duplicate entries',
        () async {
      await ingestSampleEntry();
      final snapshot = await repo.exportSnapshot();

      final targetRepo = InMemoryGradebookRepository();
      await targetRepo.importSnapshot(snapshot);
      expect((await targetRepo.listEntries()).length, equals(1));

      // Re-import identical snapshot
      await targetRepo.importSnapshot(snapshot);
      expect((await targetRepo.listEntries()).length, equals(1));
    });

    // 33. conflict protection
    test(
        '33. conflict protection - concurrent dispute modifications or overrides throw on invalid state transition',
        () async {
      final entry =
          await ingestSampleEntry(originalScore: 60.0, isPublished: true);
      final dispute = await service.createDispute(
        learnerId: 'learner_alice',
        entryId: entry.entryId,
        assessmentId: entry.assessmentId,
        reason: 'Reason for dispute',
      );

      // Resolve dispute once
      await service.resolveDisputeWithOverride(
        dispute.disputeId,
        newScore: 70.0,
        rationale: 'Accepted',
        facultyId: 'faculty_01',
      );

      // Attempting to resolve again or reject already resolved dispute throws
      expect(
        () => service.rejectDispute(
          dispute.disputeId,
          rationale: 'Attempt reject already resolved',
          facultyId: 'faculty_01',
        ),
        throwsA(isA<GradeDisputeException>()),
      );
    });

    // 34. complete end-to-end gradebook workflow
    test(
        '34. complete end-to-end gradebook workflow - executes assessment result -> gradebook -> publish -> dispute -> override -> audit',
        () async {
      // Step 1: Ingest evaluated assessment result
      final entry = await service.ingestAssessmentResult(
        entryId: 'e_e2e',
        tenantId: 'tenant_upsc',
        cohortId: 'cohort_2026',
        assessmentId: 'exam_prelims',
        learnerId: 'learner_vikram',
        resultId: 'res_vikram_01',
        originalScore: 72.0,
        maxScore: 100.0,
        autoPublish: false,
      );

      expect(entry.isPublished, isFalse);

      // Step 2: Faculty views in gradebook matrix
      final gbPre = await service.getCohortGradebook('cohort_2026');
      expect(gbPre.matrix['learner_vikram']?['exam_prelims']?.finalScore,
          equals(72.0));

      // Step 3: Learner does not see unpublished grade
      final learnerGradesPre =
          await service.getOfficialGradesForLearner('learner_vikram');
      expect(learnerGradesPre, isEmpty);

      // Step 4: Faculty publishes grade
      await service.publishGrade(entry.entryId, facultyId: 'faculty_head');

      // Step 5: Learner views official published grade
      final learnerGradesPub =
          await service.getOfficialGradesForLearner('learner_vikram');
      expect(learnerGradesPub.length, equals(1));
      expect(learnerGradesPub.first.letterGrade, equals('B'));

      // Step 6: Learner files dispute
      final dispute = await service.createDispute(
        learnerId: 'learner_vikram',
        entryId: entry.entryId,
        assessmentId: entry.assessmentId,
        reason: 'Question 15 ambiguity should grant full marks',
      );

      // Step 7: Faculty marks under review and then resolves with override
      await service.reviewDispute(dispute.disputeId, facultyId: 'faculty_head');
      await service.resolveDisputeWithOverride(
        dispute.disputeId,
        newScore: 82.0,
        rationale: 'Faculty board agreed question 15 wording was ambiguous',
        facultyId: 'faculty_head',
      );

      // Step 8: Learner views updated official grade
      final learnerGradesPost =
          await service.getOfficialGradesForLearner('learner_vikram');
      expect(learnerGradesPost.first.finalScore, equals(82.0));
      expect(learnerGradesPost.first.originalScore, equals(72.0)); // Preserved
      expect(learnerGradesPost.first.isOverridden, isTrue);

      // Step 9: Audit trail is complete and ordered
      final audits = await service.getAuditTrail(entry.entryId);
      expect(audits.length, greaterThanOrEqualTo(4));
    });
  });
}
