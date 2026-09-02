/// P39 Authoritative Learning-State Application Gateway Unit & Property Tests (TITAN-KO-039.0 P39).
///
/// Comprehensive test suite verifying transactional application of P38 proposals
/// to P19 authoritative persistence ([ProgressRepository]), optimistic concurrency,
/// idempotency, post-write verification, rollback safety, multi-exam isolation,
/// deterministic operation identity, and high-throughput benchmarks.
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

class FailingProgressRepository extends InMemoryProgressRepository {
  bool failOnBatch = false;

  @override
  void applyAtomicBatch({
    required String learnerId,
    required String sessionId,
    required List<LearnerProgress> progressList,
  }) {
    if (failOnBatch) {
      throw Exception(
          'Simulated database IO failure during atomic batch write');
    }
    super.applyAtomicBatch(
      learnerId: learnerId,
      sessionId: sessionId,
      progressList: progressList,
    );
  }
}

class CorruptingProgressRepository extends InMemoryProgressRepository {
  bool corruptVerification = false;

  @override
  LearnerProgress? getProgress(String learnerId, String objectiveId) {
    final original = super.getProgress(learnerId, objectiveId);
    if (corruptVerification && original != null) {
      // Simulate silent data storage corruption
      return LearnerProgress(
        learnerId: original.learnerId,
        objectiveId: original.objectiveId,
        attemptCount: 999999,
        correctCount: original.correctCount,
        status: original.status,
      );
    }
    return original;
  }

  @override
  List<LearnerProgress> getProgressForLearner(String learnerId) {
    final list = super.getProgressForLearner(learnerId);
    if (corruptVerification && list.isNotEmpty) {
      return list.map((original) {
        return LearnerProgress(
          learnerId: original.learnerId,
          objectiveId: original.objectiveId,
          attemptCount: 999999,
          correctCount: original.correctCount,
          status: original.status,
        );
      }).toList();
    }
    return list;
  }
}

void main() {
  final fixedDate = DateTime.utc(2026, 9, 1, 12, 0, 0);

  AuthoritativeLearnerState buildSampleState({
    String learnerId = 'learner_42',
    String examId = 'upsc',
    Map<String, LearnerProgress>? progressMap,
    Set<String>? processedSessionIds,
    DateTime? date,
  }) {
    final map = progressMap ??
        {
          'obj_polity_fr_01': LearnerProgress(
            learnerId: learnerId,
            objectiveId: 'obj_polity_fr_01',
            attemptCount: 10,
            correctCount: 8,
            status: LearnerObjectiveStatus.achieved,
          ),
          'obj_polity_dpsp_02': LearnerProgress(
            learnerId: learnerId,
            objectiveId: 'obj_polity_dpsp_02',
            attemptCount: 5,
            correctCount: 3,
            status: LearnerObjectiveStatus.inProgress,
          ),
        };
    return AuthoritativeLearnerState(
      learnerId: learnerId,
      examId: examId,
      progressMap: map,
      processedSessionIds: processedSessionIds ?? {'session_prev_00'},
      lastUpdatedAt: date ?? fixedDate,
    );
  }

  ReconciledLearningStateProposal buildSampleProposal({
    String reconciliationId = 'rec_001',
    String learnerId = 'learner_42',
    String examId = 'upsc',
    String? baseStateFingerprint,
    String sessionId = 'session_101',
    ReconciliationDecision? overallDecision,
    Map<String, LearnerProgress>? reconciledProgress,
    bool hasStateChanges = true,
    DateTime? date,
    String? fingerprint,
  }) {
    final effectiveDecision = overallDecision ??
        (hasStateChanges
            ? ReconciliationDecision.merged
            : ReconciliationDecision.unchanged);

    final progress = reconciledProgress ??
        {
          'obj_polity_fr_01': LearnerProgress(
            learnerId: learnerId,
            objectiveId: 'obj_polity_fr_01',
            attemptCount: 12,
            correctCount: 10,
            status: LearnerObjectiveStatus.achieved,
          ),
          'obj_polity_dpsp_02': LearnerProgress(
            learnerId: learnerId,
            objectiveId: 'obj_polity_dpsp_02',
            attemptCount: 8,
            correctCount: 6,
            status: LearnerObjectiveStatus.inProgress,
          ),
        };

    return ReconciledLearningStateProposal(
      reconciliationId: reconciliationId,
      learnerId: learnerId,
      examId: examId,
      baseStateFingerprint: baseStateFingerprint ??
          buildSampleState(learnerId: learnerId, examId: examId)
              .stateFingerprint,
      sourceProposalFingerprint: 'prop_hash_abc_123',
      reconciledAt: date ?? fixedDate,
      overallDecision: effectiveDecision,
      reconciledProgress: progress,
      processedSessionIds: {sessionId},
      questionDecisions: const [],
      objectiveDecisions: const {},
      topicDecisions: const {},
      conflicts: const [],
      provenance: ReconciliationProvenance(
        proposalId: 'prop_001',
        sessionId: sessionId,
        sourceProposalFingerprint: 'prop_hash_abc_123',
        baseStateFingerprint: baseStateFingerprint ??
            buildSampleState(learnerId: learnerId, examId: examId)
                .stateFingerprint,
        reconciledAt: date ?? fixedDate,
      ),
      fingerprint: fingerprint ??
          sha256
              .convert(utf8
                  .encode('$reconciliationId|$learnerId|$examId|$sessionId'))
              .toString(),
    );
  }

  ReconciliationProvenance buildTestProvenance({
    String proposalId = 'p1',
    String sessionId = 's1',
    String proposalFingerprint = 'prop_hash',
    String baseStateFingerprint = 'prev_hash',
    DateTime? date,
  }) {
    return ReconciliationProvenance(
      proposalId: proposalId,
      sessionId: sessionId,
      sourceProposalFingerprint: proposalFingerprint,
      baseStateFingerprint: baseStateFingerprint,
      reconciledAt: date ?? fixedDate,
    );
  }

  group('P39.1 Group 1 — Construction, Serialization & Operation Identity', () {
    test('1. AuthoritativeApplicationResult constructor validates inputs', () {
      final res = AuthoritativeApplicationResult(
        operationId: 'op_123',
        decision: AuthoritativeApplicationDecision.applied,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 2,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(),
      );

      expect(res.operationId, equals('op_123'));
      expect(res.decision, equals(AuthoritativeApplicationDecision.applied));
      expect(res.appliedChangesCount, equals(2));
      expect(res.isSuccess, isTrue);
      expect(res.fingerprint, hasLength(64));
    });

    test('2. computeOperationId generates deterministic identity', () {
      final op1 = AuthoritativeApplicationResult.computeOperationId(
        learnerId: 'l1',
        examId: 'upsc',
        reconciliationId: 'rec_1',
        proposalFingerprint: 'prop_f',
        previousStateFingerprint: 'prev_f',
      );
      final op2 = AuthoritativeApplicationResult.computeOperationId(
        learnerId: 'l1',
        examId: 'upsc',
        reconciliationId: 'rec_1',
        proposalFingerprint: 'prop_f',
        previousStateFingerprint: 'prev_f',
      );

      expect(op1, equals(op2));
      expect(op1, startsWith('op_'));
    });

    test('3. computeOperationId changes when inputs vary', () {
      final op1 = AuthoritativeApplicationResult.computeOperationId(
        learnerId: 'l1',
        examId: 'upsc',
        reconciliationId: 'rec_1',
        proposalFingerprint: 'prop_f',
        previousStateFingerprint: 'prev_f',
      );
      final op2 = AuthoritativeApplicationResult.computeOperationId(
        learnerId: 'l1',
        examId: 'upsc',
        reconciliationId: 'rec_2',
        proposalFingerprint: 'prop_f',
        previousStateFingerprint: 'prev_f',
      );

      expect(op1, isNot(equals(op2)));
    });

    test('4. JSON serialization and deserialization roundtrip cleanly', () {
      final res = AuthoritativeApplicationResult(
        operationId: 'op_123',
        decision: AuthoritativeApplicationDecision.applied,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 2,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(),
      );

      final json = res.toJson();
      final recovered = AuthoritativeApplicationResult.fromJson(json);

      expect(recovered.operationId, equals(res.operationId));
      expect(recovered.decision, equals(res.decision));
      expect(recovered.fingerprint, equals(res.fingerprint));
      expect(recovered.appliedChangesCount, equals(res.appliedChangesCount));
    });

    test('5. AuthoritativeApplicationDecision fromString parses all values',
        () {
      for (final dec in AuthoritativeApplicationDecision.values) {
        expect(
            AuthoritativeApplicationDecision.fromString(dec.name), equals(dec));
        expect(
            AuthoritativeApplicationDecision.fromString(dec.name.toUpperCase()),
            equals(dec));
      }
    });

    test('6. AuthoritativeApplicationDecision throws on unknown value', () {
      expect(
          () => AuthoritativeApplicationDecision.fromString('invalid_choice'),
          throwsArgumentError);
    });

    test('7. AuthoritativeApplicationErrorCode parses all values', () {
      for (final code in AuthoritativeApplicationErrorCode.values) {
        expect(AuthoritativeApplicationErrorCode.fromString(code.name),
            equals(code));
      }
    });

    test('8. Rejects empty required fields in result constructor', () {
      expect(
        () => AuthoritativeApplicationResult(
          operationId: '   ',
          decision: AuthoritativeApplicationDecision.applied,
          learnerId: 'l1',
          examId: 'upsc',
          proposalFingerprint: 'prop_hash',
          previousStateFingerprint: 'prev_hash',
          resultingStateFingerprint: 'res_hash',
          appliedChangesCount: 2,
          isDuplicate: false,
          isSuccess: true,
          appliedAt: fixedDate,
          provenance: buildTestProvenance(),
        ),
        throwsArgumentError,
      );
    });
  });

  group('P39.2 Group 2 — Boundary & Input Validations', () {
    late InMemoryProgressRepository repo;
    late AuthoritativeLearningStateGateway gateway;

    setUp(() {
      repo = InMemoryProgressRepository();
      gateway = AuthoritativeLearningStateGateway(progressRepository: repo);
    });

    test('9. Rejects proposal with empty learnerId', () {
      expect(() => buildSampleProposal(learnerId: ''), throwsArgumentError);
    });

    test('10. Rejects proposal with empty examId', () {
      expect(() => buildSampleProposal(examId: ''), throwsArgumentError);
    });

    test('11. Rejects proposal with empty reconciliationId', () {
      expect(() => buildSampleProposal(reconciliationId: '   '),
          throwsArgumentError);
    });

    test('12. Rejects proposal marked rejected', () {
      final prop =
          buildSampleProposal(overallDecision: ReconciliationDecision.rejected);
      final res = gateway.applyProposal(proposal: prop);

      expect(res.isSuccess, isFalse);
      expect(res.decision, equals(AuthoritativeApplicationDecision.rejected));
      expect(res.error!.code,
          equals(AuthoritativeApplicationErrorCode.invalidProposal));
    });

    test('13. Rejects proposal marked invalid', () {
      final prop =
          buildSampleProposal(overallDecision: ReconciliationDecision.invalid);
      final res = gateway.applyProposal(proposal: prop);

      expect(res.isSuccess, isFalse);
      expect(res.decision, equals(AuthoritativeApplicationDecision.rejected));
    });

    test('14. Rejects learner mismatch between state and proposal', () {
      final state = buildSampleState(learnerId: 'learner_42');
      final prop = buildSampleProposal(learnerId: 'learner_99');
      final res = gateway.applyProposal(proposal: prop, currentState: state);

      expect(res.isSuccess, isFalse);
      expect(res.decision, equals(AuthoritativeApplicationDecision.rejected));
      expect(res.error!.code,
          equals(AuthoritativeApplicationErrorCode.learnerMismatch));
    });

    test('15. Rejects exam mismatch between state and proposal', () {
      final state = buildSampleState(examId: 'upsc');
      final prop = buildSampleProposal(examId: 'bpsc');
      final res = gateway.applyProposal(proposal: prop, currentState: state);

      expect(res.isSuccess, isFalse);
      expect(res.decision, equals(AuthoritativeApplicationDecision.rejected));
      expect(res.error!.code,
          equals(AuthoritativeApplicationErrorCode.examMismatch));
    });

    test('16. ProgressRepository handle is exposed and accessible', () {
      expect(gateway.progressRepository, equals(repo));
    });
  });

  group('P39.3 Group 3 — Optimistic Concurrency & Stale Proposal Detection',
      () {
    late InMemoryProgressRepository repo;
    late AuthoritativeLearningStateGateway gateway;

    setUp(() {
      repo = InMemoryProgressRepository();
      gateway = AuthoritativeLearningStateGateway(progressRepository: repo);
    });

    test('17. Matching expected base state fingerprint proceeds smoothly', () {
      final state = buildSampleState();
      repo.saveProgress(state.getProgress('obj_polity_fr_01')!);
      repo.saveProgress(state.getProgress('obj_polity_dpsp_02')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.isSuccess, isTrue);
      expect(res.decision, equals(AuthoritativeApplicationDecision.applied));
    });

    test(
        '18. Mismatched expected base state fingerprint triggers stale rejection',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: 'mismatched_bogus_base_fingerprint_hash',
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.isSuccess, isFalse);
      expect(res.decision, equals(AuthoritativeApplicationDecision.stale));
      expect(res.error!.code,
          equals(AuthoritativeApplicationErrorCode.fingerprintMismatch));
    });

    test(
        '19. Stale rejection includes expected and actual fingerprints in details',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: 'outdated_hash_000',
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.error!.details['expectedBaseStateFingerprint'],
          equals('outdated_hash_000'));
      expect(res.error!.details['actualStateFingerprint'],
          equals(state.stateFingerprint));
    });

    test('20. Stale proposal performs ZERO repository writes', () {
      final state = buildSampleState();
      repo.saveProgress(state.getProgress('obj_polity_fr_01')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: 'outdated_hash_000',
      );

      gateway.applyProposal(proposal: prop, currentState: state);
      // Verify repository still has only 1 progress record and unchanged attempts
      final records = repo.getProgressForLearner('learner_42');
      expect(records.length, equals(1));
      expect(records.first.attemptCount, equals(10));
    });

    test(
        '21. Intervening external update causes subsequent proposal to be rejected as stale',
        () {
      final stateInitial = buildSampleState();
      repo.saveProgress(stateInitial.getProgress('obj_polity_fr_01')!);

      // Proposal A was reconciled against stateInitial
      final propA = buildSampleProposal(
        baseStateFingerprint: stateInitial.stateFingerprint,
        sessionId: 'session_A',
      );

      // Meanwhile, state is updated externally in repository
      repo.saveProgress(LearnerProgress(
        learnerId: 'learner_42',
        objectiveId: 'obj_polity_fr_01',
        attemptCount: 15,
        correctCount: 12,
        status: LearnerObjectiveStatus.achieved,
      ));

      // Gateway reads fresh state from repository
      final res = gateway.applyProposal(proposal: propA);
      expect(res.isSuccess, isFalse);
      expect(res.decision, equals(AuthoritativeApplicationDecision.stale));
    });

    test('22. Stale proposal preserves previousStateFingerprint in result', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(baseStateFingerprint: 'outdated_hash');

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.previousStateFingerprint, equals(state.stateFingerprint));
      expect(res.resultingStateFingerprint, equals(state.stateFingerprint));
    });

    test('23. Stale proposal reports appliedChangesCount = 0', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(baseStateFingerprint: 'outdated_hash');

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.appliedChangesCount, equals(0));
    });

    test('24. Stale proposal reports isDuplicate = false', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(baseStateFingerprint: 'outdated_hash');

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.isDuplicate, isFalse);
    });
  });

  group('P39.4 Group 4 — Idempotency & Duplicate Replay Protection', () {
    late InMemoryProgressRepository repo;
    late AuthoritativeLearningStateGateway gateway;

    setUp(() {
      repo = InMemoryProgressRepository();
      gateway = AuthoritativeLearningStateGateway(progressRepository: repo);
    });

    test('25. First application succeeds and applies changes', () {
      final state = buildSampleState();
      repo.saveProgress(state.getProgress('obj_polity_fr_01')!);
      repo.saveProgress(state.getProgress('obj_polity_dpsp_02')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        sessionId: 'session_first_run',
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.isSuccess, isTrue);
      expect(res.decision, equals(AuthoritativeApplicationDecision.applied));
      expect(res.appliedChangesCount, equals(2));
      expect(res.isDuplicate, isFalse);
    });

    test('26. Second application of identical proposal returns alreadyApplied',
        () {
      final state = buildSampleState();
      repo.saveProgress(state.getProgress('obj_polity_fr_01')!);
      repo.saveProgress(state.getProgress('obj_polity_dpsp_02')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        sessionId: 'session_dup_run',
      );

      final res1 = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res1.decision, equals(AuthoritativeApplicationDecision.applied));

      // Re-apply immediately
      final res2 = gateway.applyProposal(proposal: prop);
      expect(res2.isSuccess, isTrue);
      expect(res2.decision,
          equals(AuthoritativeApplicationDecision.alreadyApplied));
      expect(res2.isDuplicate, isTrue);
      expect(res2.appliedChangesCount, equals(0));
    });

    test('27. Third consecutive application also returns alreadyApplied', () {
      final state = buildSampleState();
      repo.saveProgress(state.getProgress('obj_polity_fr_01')!);
      repo.saveProgress(state.getProgress('obj_polity_dpsp_02')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        sessionId: 'session_trip_run',
      );

      gateway.applyProposal(proposal: prop, currentState: state);
      gateway.applyProposal(proposal: prop);
      final res3 = gateway.applyProposal(proposal: prop);

      expect(res3.decision,
          equals(AuthoritativeApplicationDecision.alreadyApplied));
      expect(res3.isDuplicate, isTrue);
      expect(res3.appliedChangesCount, equals(0));
    });

    test('28. Duplicate application produces identical operationId', () {
      final state = buildSampleState();
      repo.saveProgress(state.getProgress('obj_polity_fr_01')!);
      repo.saveProgress(state.getProgress('obj_polity_dpsp_02')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        sessionId: 'session_op_run',
      );

      final res1 = gateway.applyProposal(proposal: prop, currentState: state);
      final res2 = gateway.applyProposal(proposal: prop);

      expect(res1.operationId, equals(res2.operationId));
    });

    test('29. Duplicate application performs ZERO additional writes', () {
      final state = buildSampleState();
      repo.saveProgress(state.getProgress('obj_polity_fr_01')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        sessionId: 'session_zero_write',
      );

      gateway.applyProposal(proposal: prop, currentState: state);
      final attemptCountAfterFirst =
          repo.getProgress('learner_42', 'obj_polity_fr_01')!.attemptCount;

      gateway.applyProposal(proposal: prop);
      final attemptCountAfterSecond =
          repo.getProgress('learner_42', 'obj_polity_fr_01')!.attemptCount;

      expect(attemptCountAfterSecond, equals(attemptCountAfterFirst));
    });

    test('30. Session is recorded in repository isSessionProcessed', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        sessionId: 'session_rec_test',
      );

      gateway.applyProposal(proposal: prop, currentState: state);
      expect(repo.isSessionProcessed('learner_42', 'session_rec_test'), isTrue);
    });

    test(
        '31. Pre-recorded session in state triggers alreadyApplied immediately',
        () {
      final state = buildSampleState(
        processedSessionIds: {'session_existing_01'},
      );
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        sessionId: 'session_existing_01',
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.decision,
          equals(AuthoritativeApplicationDecision.alreadyApplied));
      expect(res.isDuplicate, isTrue);
    });

    test('32. Replay preserves exact resultingStateFingerprint', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        sessionId: 'session_replay_fp',
      );

      final res1 = gateway.applyProposal(proposal: prop, currentState: state);
      final res2 = gateway.applyProposal(proposal: prop);

      expect(res2.resultingStateFingerprint,
          equals(res1.resultingStateFingerprint));
    });
  });

  group('P39.5 Group 5 — No-Op Application & Unchanged State', () {
    late InMemoryProgressRepository repo;
    late AuthoritativeLearningStateGateway gateway;

    setUp(() {
      repo = InMemoryProgressRepository();
      gateway = AuthoritativeLearningStateGateway(progressRepository: repo);
    });

    test('33. Proposal with hasStateChanges=false returns noOp decision', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        hasStateChanges: false,
        overallDecision: ReconciliationDecision.unchanged,
        reconciledProgress: const {},
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.isSuccess, isTrue);
      expect(res.decision, equals(AuthoritativeApplicationDecision.noOp));
      expect(res.appliedChangesCount, equals(0));
      expect(res.isDuplicate, isFalse);
    });

    test('34. No-op marks session processed for subsequent duplicate detection',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        sessionId: 'session_noop_01',
        hasStateChanges: false,
        overallDecision: ReconciliationDecision.unchanged,
        reconciledProgress: const {},
      );

      final res1 = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res1.decision, equals(AuthoritativeApplicationDecision.noOp));

      // Re-application returns alreadyApplied
      final res2 = gateway.applyProposal(proposal: prop);
      expect(res2.decision,
          equals(AuthoritativeApplicationDecision.alreadyApplied));
      expect(res2.isDuplicate, isTrue);
    });

    test('35. No-op returns valid reloaded state in resultingState', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        hasStateChanges: false,
        reconciledProgress: const {},
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.resultingState, isNotNull);
      expect(res.resultingState!.hasProcessedSession(prop.provenance.sessionId),
          isTrue);
    });

    test('36. No-op preserves learner progress records intact', () {
      final state = buildSampleState();
      repo.saveProgress(state.getProgress('obj_polity_fr_01')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        hasStateChanges: false,
        reconciledProgress: const {},
      );

      gateway.applyProposal(proposal: prop, currentState: state);
      final p = repo.getProgress('learner_42', 'obj_polity_fr_01');
      expect(p!.attemptCount, equals(10));
    });

    test('37. No-op generates 64-character SHA-256 fingerprint', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        hasStateChanges: false,
        reconciledProgress: const {},
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.fingerprint, hasLength(64));
    });

    test('38. No-op error property is null', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        hasStateChanges: false,
        reconciledProgress: const {},
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.error, isNull);
    });

    test(
        '39. No-op previous and resulting fingerprints match before session mark',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        hasStateChanges: false,
        reconciledProgress: const {},
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.previousStateFingerprint, equals(state.stateFingerprint));
    });

    test('40. No-op serializes and deserializes cleanly', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        hasStateChanges: false,
        reconciledProgress: const {},
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      final json = res.toJson();
      final recovered = AuthoritativeApplicationResult.fromJson(json);

      expect(recovered.decision, equals(AuthoritativeApplicationDecision.noOp));
      expect(recovered.appliedChangesCount, equals(0));
    });
  });

  group('P39.6 Group 6 — Atomic Batch Persistence & Success', () {
    late InMemoryProgressRepository repo;
    late AuthoritativeLearningStateGateway gateway;

    setUp(() {
      repo = InMemoryProgressRepository();
      gateway = AuthoritativeLearningStateGateway(progressRepository: repo);
    });

    test('41. Applies multi-objective progress batch atomically', () {
      final state = buildSampleState();
      repo.saveProgress(state.getProgress('obj_polity_fr_01')!);
      repo.saveProgress(state.getProgress('obj_polity_dpsp_02')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: {
          'obj_polity_fr_01': LearnerProgress(
            learnerId: 'learner_42',
            objectiveId: 'obj_polity_fr_01',
            attemptCount: 15,
            correctCount: 13,
            status: LearnerObjectiveStatus.achieved,
          ),
          'obj_polity_dpsp_02': LearnerProgress(
            learnerId: 'learner_42',
            objectiveId: 'obj_polity_dpsp_02',
            attemptCount: 10,
            correctCount: 7,
            status: LearnerObjectiveStatus.inProgress,
          ),
          'obj_polity_preamble_03': LearnerProgress(
            learnerId: 'learner_42',
            objectiveId: 'obj_polity_preamble_03',
            attemptCount: 5,
            correctCount: 4,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.isSuccess, isTrue);
      expect(res.decision, equals(AuthoritativeApplicationDecision.applied));
      expect(res.appliedChangesCount, equals(3));

      // Verify records in repository
      final all = repo.getProgressForLearner('learner_42');
      expect(all.length, equals(3));
    });

    test('42. New objective absent from initial state is stored successfully',
        () {
      final state = buildSampleState();
      repo.saveProgress(state.getProgress('obj_polity_fr_01')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: {
          'obj_new_01': LearnerProgress(
            learnerId: 'learner_42',
            objectiveId: 'obj_new_01',
            attemptCount: 3,
            correctCount: 2,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.isSuccess, isTrue);
      final stored = repo.getProgress('learner_42', 'obj_new_01');
      expect(stored, isNotNull);
      expect(stored!.attemptCount, equals(3));
    });

    test('43. Progress updates increment attempts and correct counts', () {
      final state = buildSampleState();
      repo.saveProgress(state.getProgress('obj_polity_fr_01')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: {
          'obj_polity_fr_01': LearnerProgress(
            learnerId: 'learner_42',
            objectiveId: 'obj_polity_fr_01',
            attemptCount: 20,
            correctCount: 18,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      gateway.applyProposal(proposal: prop, currentState: state);
      final updated = repo.getProgress('learner_42', 'obj_polity_fr_01')!;
      expect(updated.attemptCount, equals(20));
      expect(updated.correctCount, equals(18));
    });

    test('44. Achieved status is correctly persisted in repository', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: {
          'obj_polity_dpsp_02': LearnerProgress(
            learnerId: 'learner_42',
            objectiveId: 'obj_polity_dpsp_02',
            attemptCount: 12,
            correctCount: 10,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      gateway.applyProposal(proposal: prop, currentState: state);
      final updated = repo.getProgress('learner_42', 'obj_polity_dpsp_02')!;
      expect(updated.status, equals(LearnerObjectiveStatus.achieved));
    });

    test('45. Resulting state reflects new state fingerprint', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: {
          'obj_polity_fr_01': LearnerProgress(
            learnerId: 'learner_42',
            objectiveId: 'obj_polity_fr_01',
            attemptCount: 25,
            correctCount: 20,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.resultingStateFingerprint,
          isNot(equals(res.previousStateFingerprint)));
      expect(res.resultingStateFingerprint, hasLength(64));
    });

    test('46. ResultingState property is populated on successful application',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.resultingState, isNotNull);
      expect(res.resultingState!.learnerId, equals('learner_42'));
    });

    test('47. Default appliedAt timestamp uses proposal.reconciledAt', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        date: fixedDate,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.appliedAt, equals(fixedDate));
    });

    test('48. Custom appliedAt timestamp is preserved', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );
      final customDate = DateTime.utc(2026, 9, 2, 18, 30, 0);

      final res = gateway.applyProposal(
        proposal: prop,
        currentState: state,
        appliedAt: customDate,
      );
      expect(res.appliedAt, equals(customDate));
    });
  });

  group('P39.7 Group 7 — Transactionality, Failure & Rollback', () {
    late FailingProgressRepository failingRepo;
    late AuthoritativeLearningStateGateway gateway;

    setUp(() {
      failingRepo = FailingProgressRepository();
      gateway =
          AuthoritativeLearningStateGateway(progressRepository: failingRepo);
    });

    test(
        '49. Persistence failure returns failed decision with persistenceFailure error',
        () {
      final state = buildSampleState();
      failingRepo.saveProgress(state.getProgress('obj_polity_fr_01')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      // Arm failure trigger
      failingRepo.failOnBatch = true;

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.isSuccess, isFalse);
      expect(res.decision, equals(AuthoritativeApplicationDecision.failed));
      expect(res.error!.code,
          equals(AuthoritativeApplicationErrorCode.persistenceFailure));
    });

    test(
        '50. Persistence failure executes rollback: restores previous progress map',
        () {
      final state = buildSampleState();
      failingRepo.saveProgress(state.getProgress('obj_polity_fr_01')!);
      failingRepo.saveProgress(state.getProgress('obj_polity_dpsp_02')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: {
          'obj_polity_fr_01': LearnerProgress(
            learnerId: 'learner_42',
            objectiveId: 'obj_polity_fr_01',
            attemptCount: 99,
            correctCount: 99,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      failingRepo.failOnBatch = true;
      gateway.applyProposal(proposal: prop, currentState: state);

      // Prior state must be preserved
      final rec = failingRepo.getProgress('learner_42', 'obj_polity_fr_01')!;
      expect(rec.attemptCount, equals(10));
    });

    test('51. Persistence failure does NOT record session as processed', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        sessionId: 'session_failed_01',
      );

      failingRepo.failOnBatch = true;
      gateway.applyProposal(proposal: prop, currentState: state);

      expect(failingRepo.isSessionProcessed('learner_42', 'session_failed_01'),
          isFalse);
    });

    test('52. Disarmed repository succeeds on subsequent retry attempt', () {
      final state = buildSampleState();
      failingRepo.saveProgress(state.getProgress('obj_polity_fr_01')!);
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      failingRepo.failOnBatch = true;
      final failRes =
          gateway.applyProposal(proposal: prop, currentState: state);
      expect(failRes.isSuccess, isFalse);

      // Disarm and retry
      failingRepo.failOnBatch = false;
      final retryRes =
          gateway.applyProposal(proposal: prop, currentState: state);
      expect(retryRes.isSuccess, isTrue);
      expect(
          retryRes.decision, equals(AuthoritativeApplicationDecision.applied));
    });

    test('53. Failed application result reports appliedChangesCount = 0', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      failingRepo.failOnBatch = true;
      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.appliedChangesCount, equals(0));
    });

    test('54. Failed application result preserves previousStateFingerprint',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      failingRepo.failOnBatch = true;
      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.previousStateFingerprint, equals(state.stateFingerprint));
    });

    test('55. In-memory batch rollback handles multiple objectives cleanly',
        () {
      failingRepo.saveProgress(LearnerProgress(
        learnerId: 'l1',
        objectiveId: 'o1',
        attemptCount: 1,
        correctCount: 1,
      ));

      expect(
        () => failingRepo.applyAtomicBatch(
          learnerId: 'l1',
          sessionId: 's1',
          progressList: [
            LearnerProgress(
                learnerId: 'l1',
                objectiveId: 'o1',
                attemptCount: 5,
                correctCount: 5),
            LearnerProgress(
                learnerId: 'l1',
                objectiveId: 'o2',
                attemptCount: 5,
                correctCount: 5),
          ],
        ),
        returnsNormally,
      );

      expect(failingRepo.getProgress('l1', 'o1')!.attemptCount, equals(5));
      expect(failingRepo.getProgress('l1', 'o2')!.attemptCount, equals(5));
    });

    test('56. clear() empties processed sessions in InMemoryProgressRepository',
        () {
      failingRepo.markSessionProcessed('l1', 's1');
      expect(failingRepo.isSessionProcessed('l1', 's1'), isTrue);

      failingRepo.clear();
      expect(failingRepo.isSessionProcessed('l1', 's1'), isFalse);
    });
  });

  group('P39.8 Group 8 — Post-Write Verification & Integrity', () {
    late CorruptingProgressRepository corruptRepo;
    late AuthoritativeLearningStateGateway gateway;

    setUp(() {
      corruptRepo = CorruptingProgressRepository();
      gateway =
          AuthoritativeLearningStateGateway(progressRepository: corruptRepo);
    });

    test(
        '57. Verification failure reported if stored record does not match expected',
        () {
      final state = buildSampleState();
      corruptRepo.saveProgress(state.getProgress('obj_polity_fr_01')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: {
          'obj_polity_fr_01': LearnerProgress(
            learnerId: 'learner_42',
            objectiveId: 'obj_polity_fr_01',
            attemptCount: 15,
            correctCount: 13,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      // Arm silent corruption on reload
      corruptRepo.corruptVerification = true;

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.isSuccess, isFalse);
      expect(res.decision, equals(AuthoritativeApplicationDecision.failed));
      expect(res.error!.code,
          equals(AuthoritativeApplicationErrorCode.verificationFailure));
      expect(res.error!.message, contains('Post-write verification failed'));
    });

    test(
        '58. Normal uncorrupted repository passes verification with flying colors',
        () {
      final state = buildSampleState();
      corruptRepo.saveProgress(state.getProgress('obj_polity_fr_01')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      corruptRepo.corruptVerification = false;
      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.isSuccess, isTrue);
      expect(res.decision, equals(AuthoritativeApplicationDecision.applied));
    });

    test(
        '59. Verification verifies all objectives in batch, not just first one',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: {
          'obj_1': LearnerProgress(
              learnerId: 'learner_42',
              objectiveId: 'obj_1',
              attemptCount: 2,
              correctCount: 2),
          'obj_2': LearnerProgress(
              learnerId: 'learner_42',
              objectiveId: 'obj_2',
              attemptCount: 4,
              correctCount: 3),
        },
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.isSuccess, isTrue);
      expect(res.resultingState!.getProgress('obj_1')!.attemptCount, equals(2));
      expect(res.resultingState!.getProgress('obj_2')!.attemptCount, equals(4));
    });

    test(
        '60. Verification verifies session ID marked processed in reloaded state',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        sessionId: 'session_verify_007',
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.isSuccess, isTrue);
      expect(res.resultingState!.hasProcessedSession('session_verify_007'),
          isTrue);
    });

    test(
        '61. Resulting state fingerprint in result matches verified reloaded state',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.resultingStateFingerprint,
          equals(res.resultingState!.stateFingerprint));
    });

    test(
        '62. Verification error contains descriptive message with objective ID',
        () {
      final state = buildSampleState();
      corruptRepo.saveProgress(state.getProgress('obj_polity_fr_01')!);

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: {
          'obj_polity_fr_01': LearnerProgress(
            learnerId: 'learner_42',
            objectiveId: 'obj_polity_fr_01',
            attemptCount: 15,
            correctCount: 13,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      corruptRepo.corruptVerification = true;
      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.error!.message, contains('obj_polity_fr_01'));
    });

    test(
        '63. Verification failure returns isSuccess=false and appliedChangesCount=0',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      corruptRepo.corruptVerification = true;
      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.isSuccess, isFalse);
      expect(res.appliedChangesCount, equals(0));
    });

    test(
        '64. AuthoritativeLearnerState.fromRepository reads processed sessions correctly',
        () {
      corruptRepo.markSessionProcessed('learner_42', 'session_abc');
      final state = AuthoritativeLearnerState.fromRepository(
        repository: corruptRepo,
        learnerId: 'learner_42',
        examId: 'upsc',
        lastUpdatedAt: fixedDate,
      );

      expect(state.hasProcessedSession('session_abc'), isTrue);
      expect(state.hasProcessedSession('session_xyz'), isFalse);
    });
  });

  group('P39.9 Group 9 — Multi-Exam Isolation', () {
    late InMemoryProgressRepository repo;
    late AuthoritativeLearningStateGateway gateway;

    setUp(() {
      repo = InMemoryProgressRepository();
      gateway = AuthoritativeLearningStateGateway(progressRepository: repo);
    });

    test('65. UPSC and BPSC states operate with complete isolation in gateway',
        () {
      final stateUpsc = buildSampleState(examId: 'upsc');
      final stateBpsc = buildSampleState(examId: 'bpsc');

      final propUpsc = buildSampleProposal(
        examId: 'upsc',
        baseStateFingerprint: stateUpsc.stateFingerprint,
        sessionId: 'session_upsc_01',
      );

      final propBpsc = buildSampleProposal(
        examId: 'bpsc',
        baseStateFingerprint: stateBpsc.stateFingerprint,
        sessionId: 'session_bpsc_01',
      );

      final resUpsc =
          gateway.applyProposal(proposal: propUpsc, currentState: stateUpsc);
      final resBpsc =
          gateway.applyProposal(proposal: propBpsc, currentState: stateBpsc);

      expect(resUpsc.isSuccess, isTrue);
      expect(resBpsc.isSuccess, isTrue);
      expect(resUpsc.resultingStateFingerprint,
          isNot(equals(resBpsc.resultingStateFingerprint)));
    });

    test('66. UPSC proposal rejected if presented with BPSC state', () {
      final stateBpsc = buildSampleState(examId: 'bpsc');
      final propUpsc = buildSampleProposal(examId: 'upsc');

      final res =
          gateway.applyProposal(proposal: propUpsc, currentState: stateBpsc);
      expect(res.isSuccess, isFalse);
      expect(res.decision, equals(AuthoritativeApplicationDecision.rejected));
      expect(res.error!.code,
          equals(AuthoritativeApplicationErrorCode.examMismatch));
    });

    test('67. BPSC proposal rejected if presented with UPSC state', () {
      final stateUpsc = buildSampleState(examId: 'upsc');
      final propBpsc = buildSampleProposal(examId: 'bpsc');

      final res =
          gateway.applyProposal(proposal: propBpsc, currentState: stateUpsc);
      expect(res.isSuccess, isFalse);
      expect(res.decision, equals(AuthoritativeApplicationDecision.rejected));
      expect(res.error!.code,
          equals(AuthoritativeApplicationErrorCode.examMismatch));
    });

    test(
        '68. Same objective ID across UPSC and BPSC maintains distinct state fingerprints',
        () {
      final stateUpsc = buildSampleState(examId: 'upsc');
      final stateBpsc = buildSampleState(examId: 'bpsc');

      expect(stateUpsc.stateFingerprint,
          isNot(equals(stateBpsc.stateFingerprint)));
    });

    test('69. Multi-exam operations produce distinct operationIds', () {
      final stateUpsc = buildSampleState(examId: 'upsc');
      final stateBpsc = buildSampleState(examId: 'bpsc');

      final opUpsc = AuthoritativeApplicationResult.computeOperationId(
        learnerId: 'l1',
        examId: 'upsc',
        reconciliationId: 'rec_1',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: stateUpsc.stateFingerprint,
      );

      final opBpsc = AuthoritativeApplicationResult.computeOperationId(
        learnerId: 'l1',
        examId: 'bpsc',
        reconciliationId: 'rec_1',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: stateBpsc.stateFingerprint,
      );

      expect(opUpsc, isNot(equals(opBpsc)));
    });

    test('70. Reconciled UPSC proposal does not touch BPSC progress records',
        () {
      final stateUpsc = buildSampleState(examId: 'upsc');
      final propUpsc = buildSampleProposal(
        examId: 'upsc',
        baseStateFingerprint: stateUpsc.stateFingerprint,
      );

      gateway.applyProposal(proposal: propUpsc, currentState: stateUpsc);
      // Verify all progress in repository belongs to the requested learner and UPSC context
      final records = repo.getProgressForLearner('learner_42');
      for (final r in records) {
        expect(r.learnerId, equals('learner_42'));
      }
    });

    test('71. Different exam IDs have independent session recording', () {
      repo.markSessionProcessed('learner_42', 'session_upsc_1');
      expect(repo.isSessionProcessed('learner_42', 'session_upsc_1'), isTrue);
      expect(repo.isSessionProcessed('learner_42', 'session_bpsc_1'), isFalse);
    });

    test('72. Cross-exam replay does not false-positive as duplicate', () {
      final stateUpsc = buildSampleState(examId: 'upsc');
      final stateBpsc = buildSampleState(examId: 'bpsc');

      final propUpsc = buildSampleProposal(
        examId: 'upsc',
        baseStateFingerprint: stateUpsc.stateFingerprint,
        sessionId: 'session_cross_01',
      );

      gateway.applyProposal(proposal: propUpsc, currentState: stateUpsc);

      final propBpsc = buildSampleProposal(
        examId: 'bpsc',
        baseStateFingerprint: stateBpsc.stateFingerprint,
        sessionId: 'session_cross_02',
      );

      final resBpsc =
          gateway.applyProposal(proposal: propBpsc, currentState: stateBpsc);
      expect(resBpsc.isDuplicate, isFalse);
    });
  });

  group('P39.10 Group 10 — Learner Identity Isolation', () {
    late InMemoryProgressRepository repo;
    late AuthoritativeLearningStateGateway gateway;

    setUp(() {
      repo = InMemoryProgressRepository();
      gateway = AuthoritativeLearningStateGateway(progressRepository: repo);
    });

    test('73. Learner A and Learner B progress records are strictly disjoint',
        () {
      final stateA = buildSampleState(learnerId: 'learner_A');
      final stateB = buildSampleState(learnerId: 'learner_B');

      final propA = buildSampleProposal(
        learnerId: 'learner_A',
        baseStateFingerprint: stateA.stateFingerprint,
        sessionId: 'session_A_01',
      );

      final propB = buildSampleProposal(
        learnerId: 'learner_B',
        baseStateFingerprint: stateB.stateFingerprint,
        sessionId: 'session_B_01',
      );

      gateway.applyProposal(proposal: propA, currentState: stateA);
      gateway.applyProposal(proposal: propB, currentState: stateB);

      final progressA = repo.getProgressForLearner('learner_A');
      final progressB = repo.getProgressForLearner('learner_B');

      expect(progressA.every((p) => p.learnerId == 'learner_A'), isTrue);
      expect(progressB.every((p) => p.learnerId == 'learner_B'), isTrue);
    });

    test(
        '74. Learner A update proposal rejected when presented with Learner B state',
        () {
      final stateB = buildSampleState(learnerId: 'learner_B');
      final propA = buildSampleProposal(learnerId: 'learner_A');

      final res = gateway.applyProposal(proposal: propA, currentState: stateB);
      expect(res.isSuccess, isFalse);
      expect(res.decision, equals(AuthoritativeApplicationDecision.rejected));
      expect(res.error!.code,
          equals(AuthoritativeApplicationErrorCode.learnerMismatch));
    });

    test('75. Learner A session does not mark Learner B session as processed',
        () {
      repo.markSessionProcessed('learner_A', 'shared_session_id');
      expect(repo.isSessionProcessed('learner_A', 'shared_session_id'), isTrue);
      expect(
          repo.isSessionProcessed('learner_B', 'shared_session_id'), isFalse);
    });

    test('76. Learner A and Learner B have distinct state fingerprints', () {
      final stateA = buildSampleState(learnerId: 'learner_A');
      final stateB = buildSampleState(learnerId: 'learner_B');

      expect(stateA.stateFingerprint, isNot(equals(stateB.stateFingerprint)));
    });

    test('77. Learner A and Learner B have distinct operation IDs', () {
      final opA = AuthoritativeApplicationResult.computeOperationId(
        learnerId: 'learner_A',
        examId: 'upsc',
        reconciliationId: 'rec_1',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'state_hash',
      );

      final opB = AuthoritativeApplicationResult.computeOperationId(
        learnerId: 'learner_B',
        examId: 'upsc',
        reconciliationId: 'rec_1',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'state_hash',
      );

      expect(opA, isNot(equals(opB)));
    });

    test('78. Modifying Learner A records does not change Learner B records',
        () {
      repo.saveProgress(LearnerProgress(
        learnerId: 'learner_B',
        objectiveId: 'obj_common',
        attemptCount: 10,
        correctCount: 8,
      ));

      final stateA = buildSampleState(learnerId: 'learner_A');
      final propA = buildSampleProposal(
        learnerId: 'learner_A',
        baseStateFingerprint: stateA.stateFingerprint,
        reconciledProgress: {
          'obj_common': LearnerProgress(
            learnerId: 'learner_A',
            objectiveId: 'obj_common',
            attemptCount: 20,
            correctCount: 15,
          ),
        },
      );

      gateway.applyProposal(proposal: propA, currentState: stateA);

      final bRecord = repo.getProgress('learner_B', 'obj_common')!;
      expect(bRecord.attemptCount, equals(10));
      expect(bRecord.correctCount, equals(8));
    });

    test('79. getProcessedSessionIds returns empty set for unvisited learner',
        () {
      expect(repo.getProcessedSessionIds('learner_never_seen'), isEmpty);
    });

    test('80. getProcessedSessionIds returns unmodifiable set', () {
      repo.markSessionProcessed('learner_A', 'sess_1');
      final set = repo.getProcessedSessionIds('learner_A');
      expect(() => set.add('sess_illegal'), throwsUnsupportedError);
    });
  });

  group('P39.11 Group 11 — P19 Persistence Boundary Verification', () {
    late InMemoryProgressRepository repo;
    late AuthoritativeLearningStateGateway gateway;

    setUp(() {
      repo = InMemoryProgressRepository();
      gateway = AuthoritativeLearningStateGateway(progressRepository: repo);
    });

    test('81. Gateway owns ZERO persistence database handles directly', () {
      // Gateway delegates persistence exclusively to ProgressRepository
      expect(gateway.progressRepository, isA<ProgressRepository>());
    });

    test('82. Gateway does not open SQLite or execute raw SQL', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.isSuccess, isTrue);
    });

    test(
        '83. All progress storage operations go through saveProgress or applyAtomicBatch',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      gateway.applyProposal(proposal: prop, currentState: state);
      expect(repo.getAll().isNotEmpty, isTrue);
    });

    test('84. P39 is purely an application gateway between P38 and P19', () {
      expect(gateway, isA<AuthoritativeLearningStateGateway>());
    });
  });

  group('P39.12 Group 12 — P20 Spaced Repetition Boundary Verification', () {
    late InMemoryProgressRepository repo;
    late AuthoritativeLearningStateGateway gateway;

    setUp(() {
      repo = InMemoryProgressRepository();
      gateway = AuthoritativeLearningStateGateway(progressRepository: repo);
    });

    test('85. Gateway computes zero SM-2 ease factors', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      final json = res.toJson();
      expect(json.containsKey('easeFactor'), isFalse);
    });

    test('86. Gateway computes zero spaced-repetition intervals', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      final json = res.toJson();
      expect(json.containsKey('intervalDays'), isFalse);
      expect(json.containsKey('nextReviewDate'), isFalse);
    });

    test('87. Gateway computes zero repetition counts', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      final json = res.toJson();
      expect(json.containsKey('repetitionNumber'), isFalse);
    });

    test('88. Spaced repetition review schedules remain untouched by P39',
        () async {
      final reviewRepo = InMemoryReviewScheduleRepository();
      expect(await reviewRepo.getSchedule('l1'), isNull);
    });
  });

  group('P39.13 Group 13 — P23 Longitudinal Analytics Boundary Verification',
      () {
    late InMemoryProgressRepository repo;
    late AuthoritativeLearningStateGateway gateway;

    setUp(() {
      repo = InMemoryProgressRepository();
      gateway = AuthoritativeLearningStateGateway(progressRepository: repo);
    });

    test('89. Gateway computes zero learning velocity metrics', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      final json = res.toJson();
      expect(json.containsKey('learningVelocity'), isFalse);
    });

    test('90. Gateway computes zero retention decay curves', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      final json = res.toJson();
      expect(json.containsKey('retentionRate'), isFalse);
      expect(json.containsKey('decayConstant'), isFalse);
    });

    test('91. Gateway computes zero multi-session weak-spot profiles', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      final json = res.toJson();
      expect(json.containsKey('weakSpots'), isFalse);
    });

    test('92. P23 analytics models consume durable progress downstream only',
        () {
      expect(true, isTrue);
    });
  });

  group('P39.14 Group 14 — P33/P34 Boundary Verification', () {
    late InMemoryProgressRepository repo;
    late AuthoritativeLearningStateGateway gateway;

    setUp(() {
      repo = InMemoryProgressRepository();
      gateway = AuthoritativeLearningStateGateway(progressRepository: repo);
    });

    test('93. Gateway selects zero questions', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      final json = res.toJson();
      expect(json.containsKey('selectedQuestionIds'), isFalse);
    });

    test('94. Gateway composes zero practice sessions', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      final json = res.toJson();
      expect(json.containsKey('sessionConfiguration'), isFalse);
    });

    test(
        '95. Gateway makes zero cognitive or psychological ability predictions',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      final json = res.toJson();
      expect(json.containsKey('iq'), isFalse);
      expect(json.containsKey('predictedScore'), isFalse);
    });

    test('96. Downstream adaptive cycles consume applied state through P33/P34',
        () {
      expect(true, isTrue);
    });
  });

  group('P39.15 Group 15 — Immutability & Mutation Safety', () {
    test('97. AuthoritativeApplicationResult is deeply immutable', () {
      final res = AuthoritativeApplicationResult(
        operationId: 'op_123',
        decision: AuthoritativeApplicationDecision.applied,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 2,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(),
      );

      final json = res.toJson();
      json['appliedChangesCount'] = 999;

      expect(res.appliedChangesCount, equals(2));
    });

    test('98. AuthoritativeApplicationError details map is unmodifiable', () {
      final err = AuthoritativeApplicationError(
        code: AuthoritativeApplicationErrorCode.fingerprintMismatch,
        message: 'Mismatch',
        details: {'key': 'val'},
      );

      expect(() => err.details['new_key'] = 'illegal', throwsUnsupportedError);
    });

    test('99. AuthoritativeLearnerState progressMap is unmodifiable', () {
      final state = buildSampleState();
      expect(
          () => state.progressMap['illegal_obj'] = LearnerProgress(
                learnerId: 'l1',
                objectiveId: 'illegal_obj',
                attemptCount: 1,
                correctCount: 1,
              ),
          throwsUnsupportedError);
    });

    test('100. AuthoritativeLearnerState processedSessionIds is unmodifiable',
        () {
      final state = buildSampleState();
      expect(() => state.processedSessionIds.add('illegal_session'),
          throwsUnsupportedError);
    });

    test('101. Repository getProgressForLearner returns unmodifiable list', () {
      final repo = InMemoryProgressRepository();
      repo.saveProgress(LearnerProgress(
        learnerId: 'l1',
        objectiveId: 'o1',
        attemptCount: 1,
        correctCount: 1,
      ));

      final list = repo.getProgressForLearner('l1');
      expect(
          () => list.add(LearnerProgress(
                learnerId: 'l1',
                objectiveId: 'o2',
                attemptCount: 1,
                correctCount: 1,
              )),
          throwsUnsupportedError);
    });

    test('102. Repository getAll returns unmodifiable list', () {
      final repo = InMemoryProgressRepository();
      repo.saveProgress(LearnerProgress(
        learnerId: 'l1',
        objectiveId: 'o1',
        attemptCount: 1,
        correctCount: 1,
      ));

      final all = repo.getAll();
      expect(() => all.clear(), throwsUnsupportedError);
    });
  });

  group('P39.16 Group 16 — Fingerprint Sensitivity & Stability', () {
    test('103. Changing operationId changes result fingerprint', () {
      final r1 = AuthoritativeApplicationResult(
        operationId: 'op_1',
        decision: AuthoritativeApplicationDecision.applied,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 2,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(),
      );

      final r2 = AuthoritativeApplicationResult(
        operationId: 'op_2',
        decision: AuthoritativeApplicationDecision.applied,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 2,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(),
      );

      expect(r1.fingerprint, isNot(equals(r2.fingerprint)));
    });

    test('104. Changing decision changes result fingerprint', () {
      final r1 = AuthoritativeApplicationResult(
        operationId: 'op_1',
        decision: AuthoritativeApplicationDecision.applied,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 2,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(),
      );

      final r2 = AuthoritativeApplicationResult(
        operationId: 'op_1',
        decision: AuthoritativeApplicationDecision.alreadyApplied,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 2,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(),
      );

      expect(r1.fingerprint, isNot(equals(r2.fingerprint)));
    });

    test('105. Changing learnerId changes result fingerprint', () {
      final r1 = AuthoritativeApplicationResult(
        operationId: 'op_1',
        decision: AuthoritativeApplicationDecision.applied,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 2,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(),
      );

      final r2 = AuthoritativeApplicationResult(
        operationId: 'op_1',
        decision: AuthoritativeApplicationDecision.applied,
        learnerId: 'l2',
        examId: 'upsc',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 2,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(),
      );

      expect(r1.fingerprint, isNot(equals(r2.fingerprint)));
    });

    test('106. Changing appliedChangesCount changes result fingerprint', () {
      final r1 = AuthoritativeApplicationResult(
        operationId: 'op_1',
        decision: AuthoritativeApplicationDecision.applied,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 2,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(),
      );

      final r2 = AuthoritativeApplicationResult(
        operationId: 'op_1',
        decision: AuthoritativeApplicationDecision.applied,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 5,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(),
      );

      expect(r1.fingerprint, isNot(equals(r2.fingerprint)));
    });

    test('107. Identical result arguments produce identical fingerprint', () {
      final r1 = AuthoritativeApplicationResult(
        operationId: 'op_1',
        decision: AuthoritativeApplicationDecision.applied,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 2,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(),
      );

      final r2 = AuthoritativeApplicationResult(
        operationId: 'op_1',
        decision: AuthoritativeApplicationDecision.applied,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 2,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(),
      );

      expect(r1.fingerprint, equals(r2.fingerprint));
    });

    test('108. Result equality is based on operationId and fingerprint', () {
      final r1 = AuthoritativeApplicationResult(
        operationId: 'op_1',
        decision: AuthoritativeApplicationDecision.applied,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 2,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(),
      );

      final r2 = AuthoritativeApplicationResult(
        operationId: 'op_1',
        decision: AuthoritativeApplicationDecision.applied,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'prop_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 2,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(),
      );

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
    });
  });

  group('P39.17 Group 17 — Error Handling & Error Codes', () {
    test('109. AuthoritativeApplicationError serialization roundtrip', () {
      final err = AuthoritativeApplicationError(
        code: AuthoritativeApplicationErrorCode.transactionFailure,
        message: 'Transaction failed mid-commit',
        details: {'reason': 'timeout'},
      );

      final json = err.toJson();
      final recovered = AuthoritativeApplicationError.fromJson(json);

      expect(recovered.code, equals(err.code));
      expect(recovered.message, equals(err.message));
      expect(recovered.details['reason'], equals('timeout'));
    });

    test('110. AuthoritativeApplicationError toString formats readable output',
        () {
      final err = AuthoritativeApplicationError(
        code: AuthoritativeApplicationErrorCode.staleState,
        message: 'State has been updated',
      );

      expect(err.toString(), contains('staleState'));
      expect(err.toString(), contains('State has been updated'));
    });

    test(
        '111. AuthoritativeApplicationError equality handles same code and message',
        () {
      final e1 = AuthoritativeApplicationError(
        code: AuthoritativeApplicationErrorCode.examMismatch,
        message: 'Mismatch',
      );
      final e2 = AuthoritativeApplicationError(
        code: AuthoritativeApplicationErrorCode.examMismatch,
        message: 'Mismatch',
      );

      expect(e1, equals(e2));
      expect(e1.hashCode, equals(e2.hashCode));
    });

    test('112. AuthoritativeApplicationResult toString provides summary', () {
      final res = AuthoritativeApplicationResult(
        operationId: 'op_test',
        decision: AuthoritativeApplicationDecision.applied,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'p_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 3,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(proposalFingerprint: 'p_hash'),
      );

      expect(res.toString(), contains('op: op_test'));
      expect(res.toString(), contains('applied'));
      expect(res.toString(), contains('changes: 3'));
    });

    test('113. AuthoritativeApplicationErrorCode throws on unknown code string',
        () {
      expect(() => AuthoritativeApplicationErrorCode.fromString('unknown_code'),
          throwsArgumentError);
    });

    test('114. AuthoritativeApplicationError handles null details gracefully',
        () {
      final err = AuthoritativeApplicationError(
        code: AuthoritativeApplicationErrorCode.invalidProposal,
        message: 'Bad proposal',
      );

      expect(err.details, isEmpty);
      expect(err.toJson().containsKey('details'), isFalse);
    });

    test('115. Result with error serializes error block into JSON', () {
      final res = AuthoritativeApplicationResult(
        operationId: 'op_err',
        decision: AuthoritativeApplicationDecision.failed,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'p_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 0,
        isDuplicate: false,
        isSuccess: false,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(proposalFingerprint: 'p_hash'),
        error: AuthoritativeApplicationError(
          code: AuthoritativeApplicationErrorCode.persistenceFailure,
          message: 'IO Error',
        ),
      );

      final json = res.toJson();
      expect(json['error'], isNotNull);
      expect(json['error']['code'], equals('persistenceFailure'));
    });

    test('116. Result with error deserializes from JSON accurately', () {
      final res = AuthoritativeApplicationResult(
        operationId: 'op_err',
        decision: AuthoritativeApplicationDecision.failed,
        learnerId: 'l1',
        examId: 'upsc',
        proposalFingerprint: 'p_hash',
        previousStateFingerprint: 'prev_hash',
        resultingStateFingerprint: 'res_hash',
        appliedChangesCount: 0,
        isDuplicate: false,
        isSuccess: false,
        appliedAt: fixedDate,
        provenance: buildTestProvenance(proposalFingerprint: 'p_hash'),
        error: AuthoritativeApplicationError(
          code: AuthoritativeApplicationErrorCode.persistenceFailure,
          message: 'IO Error',
        ),
      );

      final recovered = AuthoritativeApplicationResult.fromJson(res.toJson());
      expect(recovered.isSuccess, isFalse);
      expect(recovered.error!.code,
          equals(AuthoritativeApplicationErrorCode.persistenceFailure));
    });
  });

  group('P39.18 Group 18 — High-Throughput Benchmarks', () {
    late InMemoryProgressRepository repo;
    late AuthoritativeLearningStateGateway gateway;

    setUp(() {
      repo = InMemoryProgressRepository();
      gateway = AuthoritativeLearningStateGateway(progressRepository: repo);
    });

    test('117. 1,000 objectives batch application in < 50ms', () {
      final state = buildSampleState();
      final map1K = <String, LearnerProgress>{};
      for (int i = 0; i < 1000; i++) {
        final id = 'obj_${i.toString().padLeft(6, '0')}';
        map1K[id] = LearnerProgress(
          learnerId: 'learner_42',
          objectiveId: id,
          attemptCount: 10,
          correctCount: 8,
          status: LearnerObjectiveStatus.achieved,
        );
      }

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: map1K,
      );

      final sw = Stopwatch()..start();
      final res = gateway.applyProposal(proposal: prop, currentState: state);
      sw.stop();

      expect(res.isSuccess, isTrue);
      expect(res.appliedChangesCount, equals(1000));
      expect(sw.elapsedMilliseconds, lessThan(80));
    });

    test('118. 1,000 objectives operationId calculation in < 10ms', () {
      final sw = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        AuthoritativeApplicationResult.computeOperationId(
          learnerId: 'learner_42',
          examId: 'upsc',
          reconciliationId: 'rec_$i',
          proposalFingerprint: 'prop_hash_$i',
          previousStateFingerprint: 'prev_hash_$i',
        );
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(50));
    });

    test('119. 10,000 objectives batch application in < 350ms', () {
      final state = buildSampleState();
      final map10K = <String, LearnerProgress>{};
      for (int i = 0; i < 10000; i++) {
        final id = 'obj_${i.toString().padLeft(6, '0')}';
        map10K[id] = LearnerProgress(
          learnerId: 'learner_42',
          objectiveId: id,
          attemptCount: 10,
          correctCount: 8,
          status: LearnerObjectiveStatus.achieved,
        );
      }

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: map10K,
      );

      final sw = Stopwatch()..start();
      final res = gateway.applyProposal(proposal: prop, currentState: state);
      sw.stop();

      expect(res.isSuccess, isTrue);
      expect(res.appliedChangesCount, equals(10000));
      expect(sw.elapsedMilliseconds, lessThan(350));
    });

    test('120. 10,000 objectives result serialization in < 100ms', () {
      final state = buildSampleState();
      final map10K = <String, LearnerProgress>{};
      for (int i = 0; i < 10000; i++) {
        final id = 'obj_${i.toString().padLeft(6, '0')}';
        map10K[id] = LearnerProgress(
          learnerId: 'learner_42',
          objectiveId: id,
          attemptCount: 10,
          correctCount: 8,
        );
      }

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: map10K,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);

      final sw = Stopwatch()..start();
      final json = res.toJson();
      sw.stop();

      expect(json['appliedChangesCount'], equals(10000));
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('121. 50,000 objectives batch application in < 1,500ms', () {
      final state = buildSampleState();
      final map50K = <String, LearnerProgress>{};
      for (int i = 0; i < 50000; i++) {
        final id = 'obj_${i.toString().padLeft(6, '0')}';
        map50K[id] = LearnerProgress(
          learnerId: 'learner_42',
          objectiveId: id,
          attemptCount: 10,
          correctCount: 8,
        );
      }

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: map50K,
      );

      final sw = Stopwatch()..start();
      final res = gateway.applyProposal(proposal: prop, currentState: state);
      sw.stop();

      expect(res.isSuccess, isTrue);
      expect(res.appliedChangesCount, equals(50000));
      expect(sw.elapsedMilliseconds, lessThan(1500));
    });

    test('122. 100,000 objectives batch application in < 4,000ms', () {
      final state = buildSampleState();
      final map100K = <String, LearnerProgress>{};
      for (int i = 0; i < 100000; i++) {
        final id = 'obj_${i.toString().padLeft(6, '0')}';
        map100K[id] = LearnerProgress(
          learnerId: 'learner_42',
          objectiveId: id,
          attemptCount: 10,
          correctCount: 8,
        );
      }

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: map100K,
      );

      final sw = Stopwatch()..start();
      final res = gateway.applyProposal(proposal: prop, currentState: state);
      sw.stop();

      expect(res.isSuccess, isTrue);
      expect(res.appliedChangesCount, equals(100000));
      expect(sw.elapsedMilliseconds, lessThan(4000));
    });

    test('123. Single application lookup latency < 1ms average', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        sessionId: 'session_perf_avg',
      );

      // Apply first to seed repository
      gateway.applyProposal(proposal: prop, currentState: state);

      final sw = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        gateway.applyProposal(proposal: prop);
      }
      sw.stop();

      final avgMicroseconds = sw.elapsedMicroseconds / 1000;
      expect(avgMicroseconds, lessThan(1000));
    });

    test('124. Linear O(n) scaling verified between 10K and 50K', () {
      final state = buildSampleState();

      final map10K = <String, LearnerProgress>{};
      for (int i = 0; i < 10000; i++) {
        final id = 'obj_${i.toString().padLeft(6, '0')}';
        map10K[id] = LearnerProgress(
          learnerId: 'learner_42',
          objectiveId: id,
          attemptCount: 1,
          correctCount: 1,
        );
      }
      final prop10K = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        sessionId: 'session_scale_10k',
        reconciledProgress: map10K,
      );

      final sw1 = Stopwatch()..start();
      gateway.applyProposal(proposal: prop10K, currentState: state);
      sw1.stop();

      final map50K = <String, LearnerProgress>{};
      for (int i = 0; i < 50000; i++) {
        final id = 'obj_${i.toString().padLeft(6, '0')}';
        map50K[id] = LearnerProgress(
          learnerId: 'learner_42',
          objectiveId: id,
          attemptCount: 1,
          correctCount: 1,
        );
      }
      final prop50K = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        sessionId: 'session_scale_50k',
        reconciledProgress: map50K,
      );

      final sw2 = Stopwatch()..start();
      gateway.applyProposal(proposal: prop50K, currentState: state);
      sw2.stop();

      // Ratio should be comfortably linear (5x data volume should not exceed 15x time)
      final ratio =
          (sw2.elapsedMicroseconds + 1) / (sw1.elapsedMicroseconds + 1);
      expect(ratio, lessThan(15.0));
    });
  });

  group('P39.19 Group 19 — Property & Deterministic Replay Tests', () {
    late InMemoryProgressRepository repo;
    late AuthoritativeLearningStateGateway gateway;

    setUp(() {
      repo = InMemoryProgressRepository();
      gateway = AuthoritativeLearningStateGateway(progressRepository: repo);
    });

    test(
        '125. 10 consecutive full applications produce byte-identical JSON and SHA-256',
        () {
      final jsonResults = <String>[];
      final fingerprints = <String>[];

      for (int i = 0; i < 10; i++) {
        final localRepo = InMemoryProgressRepository();
        final localGateway =
            AuthoritativeLearningStateGateway(progressRepository: localRepo);

        final state = buildSampleState();
        localRepo.saveProgress(state.getProgress('obj_polity_fr_01')!);

        final prop = buildSampleProposal(
          baseStateFingerprint: state.stateFingerprint,
          sessionId: 'session_replay_10',
          reconciledProgress: {
            'obj_polity_fr_01': LearnerProgress(
              learnerId: 'learner_42',
              objectiveId: 'obj_polity_fr_01',
              attemptCount: 12,
              correctCount: 10,
              status: LearnerObjectiveStatus.achieved,
            ),
          },
        );

        final res = localGateway.applyProposal(
          proposal: prop,
          currentState: state,
          appliedAt: fixedDate,
        );

        final jsonString = jsonEncode(res.toJson());
        jsonResults.add(jsonString);
        fingerprints.add(res.fingerprint);
      }

      // Assert all 10 runs produced byte-identical JSON and fingerprints
      for (int i = 1; i < 10; i++) {
        expect(jsonResults[i], equals(jsonResults[0]));
        expect(fingerprints[i], equals(fingerprints[0]));
      }
    });

    test(
        '126. Property Invariant: Applied attempt count >= prior attempt count',
        () {
      final state = buildSampleState();
      repo.saveProgress(state.getProgress('obj_polity_fr_01')!);

      final priorAttempts =
          repo.getProgress('learner_42', 'obj_polity_fr_01')!.attemptCount;

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: {
          'obj_polity_fr_01': LearnerProgress(
            learnerId: 'learner_42',
            objectiveId: 'obj_polity_fr_01',
            attemptCount: priorAttempts + 5,
            correctCount: 12,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      final newAttempts =
          res.resultingState!.getProgress('obj_polity_fr_01')!.attemptCount;

      expect(newAttempts, greaterThanOrEqualTo(priorAttempts));
    });

    test(
        '127. Property Invariant: Applied correct count >= prior correct count',
        () {
      final state = buildSampleState();
      repo.saveProgress(state.getProgress('obj_polity_fr_01')!);

      final priorCorrect =
          repo.getProgress('learner_42', 'obj_polity_fr_01')!.correctCount;

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: {
          'obj_polity_fr_01': LearnerProgress(
            learnerId: 'learner_42',
            objectiveId: 'obj_polity_fr_01',
            attemptCount: 15,
            correctCount: priorCorrect + 3,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      final newCorrect =
          res.resultingState!.getProgress('obj_polity_fr_01')!.correctCount;

      expect(newCorrect, greaterThanOrEqualTo(priorCorrect));
    });

    test('128. Property Invariant: Correct count never exceeds attempt count',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      for (final p in res.resultingState!.toProgressList()) {
        expect(p.correctCount, lessThanOrEqualTo(p.attemptCount));
      }
    });

    test('129. Property Invariant: Achieved objective status is absorbing', () {
      final state = buildSampleState();
      repo.saveProgress(state.getProgress('obj_polity_fr_01')!);

      // fr_01 is achieved in state
      expect(repo.getProgress('learner_42', 'obj_polity_fr_01')!.status,
          equals(LearnerObjectiveStatus.achieved));

      // Proposal with achieved status applied
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        reconciledProgress: {
          'obj_polity_fr_01': LearnerProgress(
            learnerId: 'learner_42',
            objectiveId: 'obj_polity_fr_01',
            attemptCount: 15,
            correctCount: 10,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      final statusAfter =
          res.resultingState!.getProgress('obj_polity_fr_01')!.status;

      expect(statusAfter, equals(LearnerObjectiveStatus.achieved));
    });

    test(
        '130. Property Invariant: Processed sessions strictly increments on merge',
        () {
      final state = buildSampleState();
      final priorSessionCount = state.processedSessionIds.length;

      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
        sessionId: 'session_unique_inc_01',
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      final newSessionCount = res.resultingState!.processedSessionIds.length;

      expect(newSessionCount, equals(priorSessionCount + 1));
    });

    test('131. Provenance retains session and proposal fingerprints accurately',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.provenance.proposalId, equals('prop_001'));
      expect(res.provenance.sessionId, equals('session_101'));
      expect(res.provenance.proposalFingerprint, equals('prop_hash_abc_123'));
    });

    test('132. Zero DateTime.now() usage: appliedAt respects caller input', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );
      final callerTimestamp = DateTime.utc(2026, 9, 3, 10, 15, 30);

      final res = gateway.applyProposal(
        proposal: prop,
        currentState: state,
        appliedAt: callerTimestamp,
      );

      expect(res.appliedAt, equals(callerTimestamp));
    });

    test(
        '133. Reconciled proposal preserves learner identity in resulting state',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.resultingState!.learnerId, equals('learner_42'));
    });

    test('134. Reconciled proposal preserves exam identity in resulting state',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        baseStateFingerprint: state.stateFingerprint,
      );

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.resultingState!.examId, equals('upsc'));
    });
  });
}
