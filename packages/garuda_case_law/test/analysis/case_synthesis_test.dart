import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P10 — Multi-case synthesis (TITAN-KO-015.0 P10).
///
/// Synthesis is an evidence-preserving aggregation: it re-presents validated
/// data and aggregates only deterministic structural facts. It never invents a
/// legal conclusion.
void main() {
  final service = CrossCaseAnalysisService();

  group('A. two-case synthesis', () {
    final result = service.synthesize(['MINERVA_MILLS', 'KESAVANANDA']);

    test('re-presents both cases with their source data', () {
      expect(result.caseIds, ['MINERVA_MILLS', 'KESAVANANDA']);
      expect(result.entries, hasLength(2));
      for (final e in result.entries) {
        expect(e.caseName, isNotEmpty);
        expect(e.citation, isNotEmpty);
        expect(e.holdings, isNotEmpty);
        expect(e.ratios, isNotEmpty);
        expect(e.issues, isNotEmpty);
        expect(e.evidenceIds, isNotEmpty);
        expect(e.caseObject.caseId, e.caseId);
      }
    });

    test('aggregates distinct attributes deterministically', () {
      final agg = result.aggregate;
      expect(
          agg.articles,
          containsAll(
              ['13', '14', '19', '31', '31a', '31b', '31c', '32', '368']));
      expect(agg.doctrines,
          containsAll(['BASIC_STRUCTURE', 'HARMONIOUS_CONSTRUCTION']));
      expect(agg.earliestYear, 1973);
      expect(agg.latestYear, 1980);
      expect(agg.yearSpan, 7);
      expect(agg.totalHoldings, 4);
      expect(agg.totalRatios, 6);
    });

    test('aggregates attributes common to every case', () {
      final agg = result.aggregate;
      expect(agg.commonArticles, ['14', '19', '31c', '32', '368']);
      expect(agg.commonDoctrines, ['BASIC_STRUCTURE']);
      expect(agg.commonActs, isEmpty,
          reason: 'the two cases cite different amendments');
    });

    test('exposes the P5 edges among the selection verbatim', () {
      final ids = result.graphRelationships.map((e) => e.edgeId).toSet();
      expect(ids, contains('e:MINERVA_MILLS|followed|KESAVANANDA'));
      expect(ids, contains('e:MINERVA_MILLS|related|KESAVANANDA'));
      expect(ids, contains('e:KESAVANANDA|related|MINERVA_MILLS'));
    });

    test('carries P9 discovery links within the selection', () {
      expect(result.discoveryLinks, isNotEmpty);
      final pairKeys = result.discoveryLinks
          .map((l) => '${l.sourceCaseId}->${l.targetCaseId}')
          .toSet();
      expect(pairKeys, contains('MINERVA_MILLS->KESAVANANDA'));
      for (final link in result.discoveryLinks) {
        expect(link.reasons, isNotEmpty);
        expect(result.caseIds, contains(link.targetCaseId));
      }
    });

    test('emits a chronological-span observation only', () {
      expect(result.observations, hasLength(1));
      final obs = result.observations.single;
      expect(obs.type, StructuralObservationType.chronologicalSpan);
      expect(obs.label, 'selection spans 1973–1980');
    });
  });

  group('B. three-case synthesis', () {
    final result =
        service.synthesize(['KESAVANANDA', 'GOLAKNATH', 'MINERVA_MILLS']);

    test('resolves all cases and aggregates across the set', () {
      expect(result.caseIds, ['KESAVANANDA', 'GOLAKNATH', 'MINERVA_MILLS']);
      expect(result.entries, hasLength(3));
      expect(result.aggregate.doctrines,
          containsAll(['BASIC_STRUCTURE', 'PROSPECTIVE_OVERRULING']));
      expect(result.aggregate.earliestYear, 1967);
      expect(result.aggregate.latestYear, 1980);
      // No doctrine is engaged by all three, so the common set is empty.
      expect(result.aggregate.commonDoctrines, isEmpty);
    });
  });

  group('C. edge cases', () {
    test('empty selection yields an empty synthesis', () {
      final result = service.synthesize(const []);
      expect(result.isEmpty, isTrue);
      expect(result.entries, isEmpty);
      expect(result.aggregate.articles, isEmpty);
      expect(result.graphRelationships, isEmpty);
      expect(result.discoveryLinks, isEmpty);
    });

    test('unresolved identifiers are reported, never fabricated', () {
      final result = service.synthesize(['KESAVANANDA', 'NO_SUCH_CASE']);
      expect(result.caseIds, ['KESAVANANDA']);
      expect(result.unresolvedCaseIds, ['NO_SUCH_CASE']);
    });

    test('a single case is a valid synthesis with trivial common attributes',
        () {
      final result = service.synthesize(['GOLAKNATH']);
      expect(result.isEmpty, isFalse);
      expect(result.entries, hasLength(1));
      expect(result.aggregate.commonArticles, isNotEmpty);
      expect(result.graphRelationships, isEmpty);
      expect(result.discoveryLinks, isEmpty);
    });
  });

  group('D. evidence preservation', () {
    test('evidence IDs from the records are preserved verbatim', () {
      final result = service.synthesize(['MINERVA_MILLS', 'KESAVANANDA']);
      for (final e in result.entries) {
        final recordIds = e.caseObject.evidenceIds;
        expect(e.evidenceIds, recordIds);
        expect(e.evidenceIds, isNotEmpty);
      }
    });

    test('every observation and discovery reason carries provenance', () {
      final result = service.synthesize(['MINERVA_MILLS', 'KESAVANANDA']);
      for (final o in result.observations) {
        expect(o.references, isNotEmpty);
        expect(o.provenance, isNotEmpty);
      }
      for (final link in result.discoveryLinks) {
        for (final r in link.reasons) {
          expect(r.references, isNotEmpty);
          expect(r.provenance, isNotEmpty);
        }
      }
      for (final e in result.graphRelationships) {
        expect(e.provenance, isNotEmpty);
      }
    });
  });

  group('E. determinism', () {
    test('identical input yields identical serialized output', () {
      final input = ['MINERVA_MILLS', 'KESAVANANDA', 'GOLAKNATH'];
      final a = service.synthesize(input);
      final b = service.synthesize(input);
      expect(a.toJson(), b.toJson());
    });
  });

  group('F. serialization round-trip', () {
    test('a synthesis survives toJson/fromJson unchanged', () {
      final result = service.synthesize(['MINERVA_MILLS', 'KESAVANANDA']);
      final restored = CaseSynthesis.fromJson(result.toJson());
      expect(restored.toJson(), result.toJson());
    });
  });
}
