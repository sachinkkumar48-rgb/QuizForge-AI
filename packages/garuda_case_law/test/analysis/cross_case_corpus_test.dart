import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P10 — Corpus-wide verification over the full 49-case corpus
/// (TITAN-KO-015.0 P10).
///
/// Verifies that P10 processes every case, covers every doctrine, handles
/// sparse/disconnected records, keeps provenance non-empty and behaves
/// deterministically and offline-first across the whole validated corpus.
void main() {
  final service = CrossCaseAnalysisService();

  final caseIds = service.cases.map((c) => c.caseId).toList()..sort();
  final doctrineIds = service.doctrineIds.toList()..sort();

  test('canonical offline-first corpus is 49 cases / 69 nodes / 125 edges', () {
    expect(service.cases.length, 49);
    expect(service.graph.nodeCount, 69);
    expect(service.graph.edgeCount, 125);
    expect(doctrineIds, hasLength(20));
  });

  group('A. every case is analyzed without exceptions', () {
    test('two-case comparison runs for every corpus case', () {
      for (final id in caseIds) {
        final result = service.compareTwo('KESAVANANDA', id);
        expect(result.caseIds, contains(id));
        for (final o in result.observations) {
          expect(o.references, isNotEmpty);
          expect(o.provenance, isNotEmpty);
        }
        final item = result.items.firstWhere((i) => i.caseId == id);
        expect(item.hasIntelligence, isTrue,
            reason: 'every enriched corpus record carries P4 intelligence');
      }
    });

    test('precedent-chain analysis runs for every corpus case', () {
      for (final id in caseIds) {
        for (final dir in [
          PrecedentChainDirection.predecessor,
          PrecedentChainDirection.successor,
        ]) {
          final chain = service.precedentChainAnalysis(id, direction: dir);
          expect(chain, isNotNull,
              reason: 'a chain exists for every corpus case (anchor only)');
          expect(chain!.entries.first.caseId, id);
          // Sparse cases legitimately yield single-node chains.
          if (chain.length == 0) {
            expect(chain.entries, hasLength(1));
          }
        }
      }
    });
  });

  group('B. every doctrine is analyzed', () {
    test('all 20 doctrines process without exceptions', () {
      for (final d in doctrineIds) {
        final result = service.doctrineAnalysis(d);
        expect(result.doctrineId, d);
        expect(result.chronology.caseIds, result.caseIds);
        for (final c in result.cases) {
          expect(c.provenance, isNotEmpty);
          expect(c.edgeId, startsWith('e:'));
        }
        for (final e in result.graphRelationships) {
          expect(result.caseIds, contains(e.sourceId));
          expect(result.caseIds, contains(e.targetId));
        }
      }
    });

    test('member cases are chronologically ordered per doctrine', () {
      for (final d in doctrineIds) {
        final result = service.doctrineAnalysis(d);
        if (result.cases.length < 2) continue;
        final years = result.cases.map((c) => c.year).toList();
        final sorted = [...years]..sort();
        expect(years, sorted, reason: 'doctrine $d members are chronological');
      }
    });
  });

  group('C. sparse and disconnected cases', () {
    test('disconnected cases yield single-node chains, not fabricated links',
        () {
      for (final id in ['OLGA_TELLIS', 'SHAYARA_BANO', 'SUCHITA_SRIVASTAVA']) {
        expect(service.precedentChainAnalysis(id)!.length, 0);
        expect(
            service
                .precedentChainAnalysis(id,
                    direction: PrecedentChainDirection.successor)!
                .length,
            0);
      }
    });

    test('a comparison with a disconnected case is still valid', () {
      final result = service.compareTwo('OLGA_TELLIS', 'SHAYARA_BANO');
      expect(result.caseIds, containsAll(['OLGA_TELLIS', 'SHAYARA_BANO']));
      final edgeObs = result.observations
          .where((o) => o.type == StructuralObservationType.graphRelationship);
      expect(edgeObs, isEmpty,
          reason: 'no graph edge exists between two disconnected cases');
      // Chronology is still observed deterministically for the pair.
      final chrono = result.observations
          .any((o) => o.type == StructuralObservationType.chronologicalOrder);
      expect(chrono, isTrue);
    });
  });

  group('D. corpus-wide synthesis and chronology', () {
    test('chronologicalAnalysis orders the full corpus deterministically', () {
      final analysis = service.chronologicalAnalysis(caseIds);
      expect(analysis.entries, hasLength(49));
      expect(analysis.unresolvedCaseIds, isEmpty);
      expect(analysis.entries.map((e) => e.position),
          [for (var i = 0; i < 49; i++) i]);
      expect(analysis.earliest!.caseId, 'AK_GOPALAN');
      expect(analysis.latest!.caseId, 'JANHIT_ABHIYAN');
      expect(analysis.yearSpan, 72);
    });

    test('synthesize processes the full corpus with full provenance', () {
      final result = service.synthesize(caseIds);
      expect(result.caseIds, hasLength(49));
      expect(result.unresolvedCaseIds, isEmpty);
      expect(result.entries, hasLength(49));
      expect(result.aggregate.earliestYear, 1950);
      expect(result.aggregate.latestYear, 2022);
      expect(result.graphRelationships, hasLength(106),
          reason: 'all 106 directed case → case edges fall within the corpus');
      for (final e in result.graphRelationships) {
        expect(result.caseIds, contains(e.sourceId));
        expect(result.caseIds, contains(e.targetId));
        expect(e.provenance, isNotEmpty);
      }
      for (final link in result.discoveryLinks) {
        expect(result.caseIds, contains(link.sourceCaseId));
        expect(result.caseIds, contains(link.targetCaseId));
      }
    });
  });

  group('E. determinism across the corpus', () {
    test('corpus-wide comparison, chronology and synthesis are deterministic',
        () {
      final ids = caseIds.take(12).toList();
      final cmpA = service.compareCases(ids);
      final cmpB = service.compareCases(ids);
      expect(cmpA.toJson(), cmpB.toJson());

      final synA = service.synthesize(ids);
      final synB = service.synthesize(ids);
      expect(synA.toJson(), synB.toJson());

      final chrA = service.chronologicalAnalysis(ids);
      final chrB = service.chronologicalAnalysis(ids);
      expect(chrA.toJson(), chrB.toJson());
    });
  });

  group('F. no fabricated identifiers anywhere', () {
    test('all emitted case IDs and doctrine IDs are canonical', () {
      for (final id in caseIds) {
        final cmp = service.compareTwo('KESAVANANDA', id);
        for (final s in cmp.sharedAttributes) {
          for (final cid in s.caseIds) {
            expect(caseIds, contains(cid));
          }
          if (s.kind == SharedAttributeKind.doctrine) {
            expect(doctrineIds, contains(s.value));
          }
        }
      }
    });
  });
}
