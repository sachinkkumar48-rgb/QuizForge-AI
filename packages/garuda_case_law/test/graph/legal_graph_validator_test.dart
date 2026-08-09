import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P5 validation — graph integrity: missing nodes, invalid IDs, duplicate
/// edges, self-loops and evidence validation (TITAN-KO-015.0 P5).
void main() {
  final caseIds = {'A', 'B', 'C'};
  final doctrineIds = {'D1', 'D2'};

  PrecedentGraphEdge precedentEdge({
    String source = 'A',
    String target = 'B',
    PrecedentRelationshipType type = PrecedentRelationshipType.followed,
    List<String> evidence = const ['ev_A_official'],
  }) =>
      PrecedentGraphEdge(
        sourceId: source,
        targetId: target,
        type: type,
        evidenceIds: evidence,
        provenance: 'corpus:precedentsFollowed',
      );

  group('Valid graphs', () {
    test('the corpus graph is fully valid', () {
      final result =
          LegalGraphValidator.validateGraph(LegalGraphSeed.fromCorpus().build());
      expect(result.isValid, isTrue);
      expect(result.issues, isEmpty);
    });

    test('a clean synthetic edge set is valid', () {
      final result = LegalGraphValidator.validateEdges(
        [precedentEdge()],
        caseIds: caseIds,
        doctrineIds: doctrineIds,
      );
      expect(result.isValid, isTrue);
    });
  });

  group('Duplicate edges', () {
    test('duplicate (source, type, target) is detected', () {
      final result = LegalGraphValidator.validateEdges(
        [precedentEdge(), precedentEdge()],
        caseIds: caseIds,
        doctrineIds: doctrineIds,
      );
      expect(result.isValid, isFalse);
      expect(result.issues.map((i) => i.code), contains('duplicate_edge'));
    });

    test('same endpoints with different types are not duplicates', () {
      final result = LegalGraphValidator.validateEdges(
        [
          precedentEdge(type: PrecedentRelationshipType.followed),
          precedentEdge(type: PrecedentRelationshipType.overruled),
        ],
        caseIds: caseIds,
        doctrineIds: doctrineIds,
      );
      expect(result.isValid, isTrue);
    });
  });

  group('Self-loops', () {
    test('a self-loop is detected as invalid', () {
      final result = LegalGraphValidator.validateEdges(
        [precedentEdge(source: 'A', target: 'A')],
        caseIds: caseIds,
        doctrineIds: doctrineIds,
      );
      expect(result.isValid, isFalse);
      expect(result.issues.map((i) => i.code), contains('self_loop'));
    });
  });

  group('Missing nodes', () {
    test('a source node that is not in the graph is detected', () {
      final result = LegalGraphValidator.validateEdges(
        [precedentEdge(source: 'UNKNOWN')],
        caseIds: caseIds,
        doctrineIds: doctrineIds,
      );
      expect(result.isValid, isFalse);
      expect(result.issues.map((i) => i.code), contains('missing_source_node'));
      expect(result.issues.map((i) => i.code), contains('unknown_case_id'));
    });

    test('a target node that is not in the graph is detected', () {
      final result = LegalGraphValidator.validateEdges(
        [precedentEdge(target: 'UNKNOWN')],
        caseIds: caseIds,
        doctrineIds: doctrineIds,
      );
      expect(result.issues.map((i) => i.code), contains('missing_target_node'));
    });

    test('a doctrine edge to a missing doctrine is detected', () {
      final result = LegalGraphValidator.validateEdges(
        [
          const DoctrineGraphEdge(
            sourceId: 'A',
            targetId: 'NO_DOCTRINE',
            type: DoctrineRelationshipType.engages,
            evidenceIds: ['ev_A_official'],
          ),
        ],
        caseIds: caseIds,
        doctrineIds: doctrineIds,
      );
      expect(result.issues.map((i) => i.code), contains('unknown_doctrine_id'));
    });
  });

  group('Invalid canonical IDs', () {
    test('non-canonical case IDs are flagged on both endpoints', () {
      final result = LegalGraphValidator.validateEdges(
        [
          precedentEdge(
            source: 'a',
            target: 'b',
            evidence: const ['ev_a_official'],
          ),
        ],
        caseIds: caseIds,
        doctrineIds: doctrineIds,
      );
      expect(
          result.issues.where((i) => i.code == 'unknown_case_id').length,
          greaterThanOrEqualTo(2));
    });

  });

  group('Evidence validation', () {
    test('an edge with no evidence is flagged', () {
      final result = LegalGraphValidator.validateEdges(
        [precedentEdge(evidence: const [])],
        caseIds: caseIds,
        doctrineIds: doctrineIds,
      );
      expect(result.issues.map((i) => i.code), contains('missing_evidence'));
    });

    test('an unregistered evidence reference is flagged', () {
      final result = LegalGraphValidator.validateEdges(
        [precedentEdge(evidence: const ['not-a-registered-evidence'])],
        caseIds: caseIds,
        doctrineIds: doctrineIds,
      );
      expect(
          result.issues.map((i) => i.code), contains('unregistered_evidence'));
    });

    test('doctrine-record evidence is registered', () {
      expect(LegalGraphSeed.isRegisteredEvidence('ev_KESAVANANDA_official'),
          isTrue);
      expect(LegalGraphSeed.isRegisteredEvidence('doctrine:BASIC_STRUCTURE'),
          isTrue);
      expect(LegalGraphSeed.isRegisteredEvidence('doctrine:NOT_A_DOCTRINE'),
          isFalse);
    });
  });
}
