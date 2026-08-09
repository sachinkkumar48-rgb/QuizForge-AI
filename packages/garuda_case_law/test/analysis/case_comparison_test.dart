import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P10 — Case comparison behavior (TITAN-KO-015.0 P10).
///
/// Every assertion is grounded in actual corpus records: P3 fields, P4
/// Judgment Intelligence and P5 graph edges. A comparison must separate factual
/// source data from structural observation and never claim legal similarity.
void main() {
  final service = CrossCaseAnalysisService();

  group('A. two-case comparison', () {
    final result = service.compareTwo('MINERVA_MILLS', 'KESAVANANDA');

    test('resolves both cases in input order', () {
      expect(result.caseIds, ['MINERVA_MILLS', 'KESAVANANDA']);
      expect(
          result.items.map((i) => i.caseId), ['MINERVA_MILLS', 'KESAVANANDA']);
      expect(result.unresolvedCaseIds, isEmpty);
      expect(result.isEmpty, isFalse);
    });

    test('each item carries factual P3/P4 source data', () {
      for (final item in result.items) {
        expect(item.caseName, isNotEmpty);
        expect(item.citation, isNotEmpty);
        expect(item.year, greaterThan(0));
        expect(item.bench, isNotEmpty);
        expect(item.hasIntelligence, isTrue,
            reason: 'every enriched corpus record carries P4 intelligence');
        expect(item.holdings, isNotEmpty);
        expect(item.ratios, isNotEmpty);
        expect(item.issues, isNotEmpty);
        expect(item.evidenceIds, isNotEmpty);
        expect(item.caseObject.caseId, item.caseId);
        expect(item.provenance, contains('p4:judgmentIntelligence'));
      }
    });

    test('holdings are read from P4, not regenerated', () {
      final minerva =
          result.items.firstWhere((i) => i.caseId == 'MINERVA_MILLS');
      final kesavananda =
          result.items.firstWhere((i) => i.caseId == 'KESAVANANDA');
      expect(minerva.holdings, isNotEmpty);
      expect(minerva.holdings.length,
          minerva.caseObject.judgmentIntelligence!.holdings.length);
      expect(kesavananda.holdings.length, 2,
          reason: 'KESAVANANDA has exactly two P4 holdings');
      expect(minerva.holdings, isNot(kesavananda.holdings));
    });

    test('ratios are read from P4, not regenerated', () {
      final kesavananda =
          result.items.firstWhere((i) => i.caseId == 'KESAVANANDA');
      expect(kesavananda.ratios.length, 3,
          reason: 'KESAVANANDA has exactly three P4 ratios');
      expect(
          kesavananda.ratios,
          kesavananda.caseObject.judgmentIntelligence!.ratios
              .map((r) => r.ratio));
    });

    test('issues are read from P4, not regenerated', () {
      final minerva =
          result.items.firstWhere((i) => i.caseId == 'MINERVA_MILLS');
      expect(minerva.issues.length, 1,
          reason: 'MINERVA_MILLS has exactly one P4 issue');
    });

    test('outcomes and significance are exposed', () {
      final minerva =
          result.items.firstWhere((i) => i.caseId == 'MINERVA_MILLS');
      final kesavananda =
          result.items.firstWhere((i) => i.caseId == 'KESAVANANDA');
      expect(minerva.outcome, 'struckDown');
      expect(kesavananda.outcome, 'upheldWithDirections');
      expect(minerva.significance, isNotEmpty);
    });

    test('shared structured attributes are exposed explicitly', () {
      final sharedByKind = <String, List<SharedAttribute>>{};
      for (final s in result.sharedAttributes) {
        sharedByKind.putIfAbsent(s.kind.name, () => []).add(s);
      }
      final articleValues =
          sharedByKind['article']!.map((s) => s.value).toList();
      expect(articleValues, containsAll(['14', '19', '31c', '32', '368']));
      final doctrineValues =
          sharedByKind['doctrine']!.map((s) => s.value).toList();
      expect(doctrineValues, contains('BASIC_STRUCTURE'));
      for (final s in result.sharedAttributes) {
        expect(s.caseIds, hasLength(2));
        expect(s.provenance, isNotEmpty);
      }
    });

    test('chronology is observed, not asserted as law', () {
      final chrono = result.observations
          .where((o) => o.type == StructuralObservationType.chronologicalOrder);
      expect(chrono.map((o) => o.label),
          contains('KESAVANANDA (1973) precedes MINERVA_MILLS (1980)'));
    });

    test('P5 graph edges are observed verbatim', () {
      final edges = result.observations
          .where((o) => o.type == StructuralObservationType.graphRelationship)
          .map((o) => o.label)
          .toList();
      expect(edges, contains('MINERVA_MILLS followed KESAVANANDA'));
      expect(edges, contains('MINERVA_MILLS related KESAVANANDA'));
      expect(edges, contains('KESAVANANDA related MINERVA_MILLS'));
    });

    test('holdings/ratios/issues/outcomes differences are structural', () {
      final types = result.observations.map((o) => o.type).toSet();
      expect(types, contains(StructuralObservationType.holdingDifference));
      expect(types, contains(StructuralObservationType.ratioDifference));
      expect(types, contains(StructuralObservationType.issueDifference));
      expect(types, contains(StructuralObservationType.outcomeDifference));
      for (final o in result.observations) {
        expect(o.references, isNotEmpty);
        expect(o.provenance, isNotEmpty);
      }
    });

    test('no legal-similarity claim is emitted', () {
      final json = result.toJson().toString();
      expect(json.toLowerCase(), isNot(contains('legally similar')));
      expect(json.toLowerCase(), isNot(contains('similarity score')));
    });
  });

  group('B. case resolution', () {
    test('resolves by canonical ID and by name identically', () {
      final byId = service.compareTwo('MINERVA_MILLS', 'KESAVANANDA');
      final byName = service.compareTwo('Minerva Mills Ltd. v. Union of India',
          'Kesavananda Bharati v. State of Kerala');
      expect(byId.caseIds, byName.caseIds);
      expect(byId.toJson(), byName.toJson());
    });

    test('unknown identifiers are reported, never fabricated', () {
      final result = service.compareTwo('MINERVA_MILLS', 'NO_SUCH_CASE');
      expect(result.caseIds, ['MINERVA_MILLS']);
      expect(result.unresolvedCaseIds, ['NO_SUCH_CASE']);
      expect(result.items, hasLength(1));
    });

    test('duplicate identifiers are de-duplicated', () {
      final result = service.compareCases(['MINERVA_MILLS', 'MINERVA_MILLS']);
      expect(result.caseIds, ['MINERVA_MILLS']);
      expect(result.items, hasLength(1));
    });
  });

  group('C. multi-case comparison', () {
    final result = service.compareCases(
        ['MINERVA_MILLS', 'GOLAKNATH', 'KESAVANANDA', 'SAJJAN_SINGH']);

    test('resolves all cases in input order', () {
      expect(result.caseIds,
          ['MINERVA_MILLS', 'GOLAKNATH', 'KESAVANANDA', 'SAJJAN_SINGH']);
      expect(result.items, hasLength(4));
    });

    test('shared attributes list every case carrying them', () {
      for (final s in result.sharedAttributes) {
        expect(s.caseIds.length, greaterThanOrEqualTo(2));
        for (final id in s.caseIds) {
          expect(result.caseIds, contains(id));
        }
      }
    });

    test('observations are deterministic and deduplicated', () {
      final labels = result.observations.map((o) => o.label).toList();
      expect(labels.toSet().length, labels.length,
          reason: 'no duplicate observations');
      final edgeLabels = result.observations
          .where((o) => o.type == StructuralObservationType.graphRelationship)
          .map((o) => o.label)
          .toList();
      // SAJJAN_SINGH is disconnected; edges only among the connected three.
      expect(edgeLabels, isNot(contains('SAJJAN_SINGH')));
    });
  });

  group('D. edge cases', () {
    test('empty selection yields an empty comparison', () {
      final result = service.compareCases(const []);
      expect(result.isEmpty, isTrue);
      expect(result.items, isEmpty);
      expect(result.observations, isEmpty);
      expect(result.sharedAttributes, isEmpty);
    });

    test('same case twice yields a single-item comparison', () {
      final result = service.compareCases(['KESAVANANDA', 'KESAVANANDA']);
      expect(result.caseIds, ['KESAVANANDA']);
      expect(result.items, hasLength(1));
      expect(result.sharedAttributes, isEmpty);
      expect(result.observations, isEmpty);
    });

    test('missing P4 intelligence is surfaced, not fabricated', () {
      final a = syntheticCase(
        caseId: 'SYN_A',
        caseName: 'Synthetic A',
        year: 1990,
        holdings: const ['Holding A'],
        issues: const ['Issue A'],
        evidenceIds: const ['ev_SYN_A_official'],
      );
      final b = syntheticCase(
        caseId: 'SYN_B',
        caseName: 'Synthetic B',
        year: 2000,
        withIntelligence: false,
        evidenceIds: const ['ev_SYN_B_official'],
      );
      final svc = CrossCaseAnalysisService(cases: [a, b]);
      final result = svc.compareTwo('SYN_A', 'SYN_B');
      final itemA = result.items.firstWhere((i) => i.caseId == 'SYN_A');
      final itemB = result.items.firstWhere((i) => i.caseId == 'SYN_B');
      expect(itemA.hasIntelligence, isTrue);
      expect(itemA.holdings, isNotEmpty);
      expect(itemB.hasIntelligence, isFalse);
      expect(itemB.holdings, isEmpty);
      expect(itemB.ratios, isEmpty);
      expect(itemB.issues, isEmpty);
      expect(itemB.outcome, isEmpty);
      // The P3 significance fallback still surfaces factual record data.
      expect(itemB.significance, 'Synthetic constitutional significance.');
      // Structural difference between present and absent intelligence.
      final types = result.observations.map((o) => o.type).toSet();
      expect(types, contains(StructuralObservationType.holdingDifference));
    });

    test('cases sharing no structured attribute emit a negative observation',
        () {
      final a = syntheticCase(
        caseId: 'SYN_DISJOINT_A',
        caseName: 'Disjoint A',
        year: 1990,
        articles: const ['Article 1'],
        acts: const ['Act Alpha'],
        holdings: const ['Holding A'],
      );
      final b = syntheticCase(
        caseId: 'SYN_DISJOINT_B',
        caseName: 'Disjoint B',
        year: 2000,
        articles: const ['Article 2'],
        acts: const ['Act Beta'],
        holdings: const ['Holding B'],
      );
      final svc = CrossCaseAnalysisService(cases: [a, b]);
      final result = svc.compareTwo('SYN_DISJOINT_A', 'SYN_DISJOINT_B');
      expect(result.sharedAttributes, isEmpty);
      final negative = result.observations
          .any((o) => o.type == StructuralObservationType.noSharedAttributes);
      expect(negative, isTrue);
    });
  });

  group('E. serialization round-trip', () {
    test('a comparison survives toJson/fromJson unchanged', () {
      final result = service.compareTwo('MINERVA_MILLS', 'KESAVANANDA');
      final restored = CaseComparisonResult.fromJson(result.toJson());
      expect(restored.toJson(), result.toJson());
    });
  });
}
