import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P9 — Corpus-wide verification over the full 49-case corpus
/// (TITAN-KO-015.0 P9).
///
/// Verifies that P9 processes every case, handles sparse/disconnected records,
/// covers every doctrine, never fabricates IDs, keeps the P5 graph intact and
/// behaves deterministically and offline-first.
void main() {
  final service = CaseDiscoveryService();

  final caseIds = service.cases.map((c) => c.caseId).toList()..sort();
  final doctrineIds = service.doctrineIds.toList()..sort();

  test('canonical offline-first corpus is 49 cases / 69 nodes / 125 edges', () {
    expect(service.cases.length, 49);
    expect(service.graph.nodeCount, 69);
    expect(service.graph.edgeCount, 125);
  });

  test('every one of the 49 cases is processed without exceptions', () {
    for (final id in caseIds) {
      final related = service.discoverRelatedCases(id);
      expect(related, isNotNull);
      expect(service.directPrecedents(id), isNotNull);
      expect(service.ancestors(id), isNotNull);
      expect(service.descendants(id), isNotNull);

      // Chains and paths are legitimately null for isolated/disconnected cases.
      for (final chain in [
        service.predecessorChain(id),
        service.successorChain(id)
      ]) {
        if (chain != null) {
          expect(chain.nodeIds.first, id,
              reason: 'a chain must start at the queried case');
        }
      }
      for (final other in caseIds) {
        final path = service.pathBetween(id, other);
        if (path != null) {
          expect(path.nodeIds.first, id);
          expect(path.nodeIds.last, other);
          expect(path.edges.length, path.nodeIds.length - 1);
        }
      }
    }
  });

  test('no fabricated case IDs and no self-results anywhere in the corpus', () {
    for (final id in caseIds) {
      for (final r in service.discoverRelatedCases(id)) {
        expect(caseIds, contains(r.caseId),
            reason: 'only canonical corpus IDs may appear');
        expect(r.caseId, isNot(id), reason: 'no self-results');
        for (final reason in r.reasons) {
          expect(reason.references, isNotEmpty);
          expect(reason.provenance, isNotEmpty);
        }
      }
    }
  });

  test('discovery handles sparse and disconnected cases', () {
    // OLGA_TELLIS and SUCHITA_SRIVASTAVA have no graph edges.
    for (final id in ['OLGA_TELLIS', 'SUCHITA_SRIVASTAVA']) {
      final results = service.discoverRelatedCases(id);
      expect(results, isNotEmpty);
      expect(service.ancestors(id), isEmpty);
      expect(service.descendants(id), isEmpty);
      expect(service.directPrecedents(id), isEmpty);
    }
  });

  test('every doctrine resolves a valid (possibly empty) collection', () {
    expect(doctrineIds.length, 20);
    final withCases = <String>[];
    for (final d in doctrineIds) {
      final results = service.casesForDoctrine(d);
      for (final r in results) {
        expect(caseIds, contains(r.caseId));
      }
      if (results.isNotEmpty) withCases.add(d);
    }
    // At least the doctrines with corpus coverage are populated; the rest are
    // empty but safe (e.g. ECLIPSE, WAIVER).
    expect(withCases, isNotEmpty);
    expect(service.casesForDoctrine('ECLIPSE'), isEmpty);
  });

  test('precedent traversal never corrupts the P5 graph', () {
    final nodesBefore = service.graph.nodeCount;
    final edgesBefore = service.graph.edgeCount;
    for (final id in caseIds) {
      service.ancestors(id);
      service.descendants(id);
      service.directPrecedents(id);
      service.predecessorChain(id);
      service.successorChain(id);
      for (final other in caseIds) {
        service.pathBetween(id, other);
      }
    }
    expect(service.graph.nodeCount, nodesBefore);
    expect(service.graph.edgeCount, edgesBefore);
  });

  test('corpus-wide discovery is deterministic', () {
    for (final id in caseIds.take(10)) {
      final a = service.discoverRelatedCases(id);
      final b = service.discoverRelatedCases(id);
      expect(a.map((r) => r.caseId).toList(), b.map((r) => r.caseId).toList());
      for (var i = 0; i < a.length; i++) {
        expect(a[i].reasons.length, b[i].reasons.length);
      }
    }
  });

  test('related discovery never returns more cases than the corpus', () {
    for (final id in caseIds) {
      expect(service.discoverRelatedCases(id).length,
          lessThanOrEqualTo(caseIds.length - 1));
    }
  });
}
