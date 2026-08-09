import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P9 — Related Case Discovery behavior over the real 49-case corpus
/// (TITAN-KO-015.0 P9). Every assertion is grounded in actual corpus records:
/// graph edges, doctrine membership, article references and Act references.
void main() {
  final service = CaseDiscoveryService();

  group('A. valid case discovery', () {
    test('returns explainable results for a valid case', () {
      final results = service.discoverRelatedCases('MINERVA_MILLS');
      expect(results, isNotEmpty);
      for (final r in results) {
        expect(r.sourceCaseId, 'MINERVA_MILLS');
        expect(r.reasons, isNotEmpty);
        for (final reason in r.reasons) {
          expect(reason.references, isNotEmpty);
          expect(reason.provenance, isNotEmpty);
          expect(reason.label, isNotEmpty);
        }
        expect(service.caseIds, contains(r.caseId));
      }
    });

    test('resolves a case by canonical ID and by name', () {
      final byId = service.discoverRelatedCases('MINERVA_MILLS');
      final byName =
          service.discoverRelatedCases('Minerva Mills Ltd. v. Union of India');
      expect(byId.map((r) => r.caseId), byName.map((r) => r.caseId));
    });

    test('excludes the source case itself', () {
      final results = service.discoverRelatedCases('MINERVA_MILLS');
      expect(results.any((r) => r.caseId == 'MINERVA_MILLS'), isFalse);
    });

    test('unknown and empty IDs return an empty list', () {
      expect(service.discoverRelatedCases('NO_SUCH_CASE'), isEmpty);
      expect(service.discoverRelatedCases(''), isEmpty);
      expect(service.discoverRelatedCases('   '), isEmpty);
    });
  });

  group('B. reason kinds', () {
    test('direct precedent relationship yields a graph reason', () {
      final kesavananda = service
          .discoverRelatedCases('MINERVA_MILLS')
          .firstWhere((r) => r.caseId == 'KESAVANANDA');
      final graphReasons = kesavananda.reasons
          .where((r) => r.type == DiscoveryReasonType.graphRelationship);
      expect(graphReasons, isNotEmpty);
      expect(
        graphReasons.any((r) =>
            r.references.contains('e:MINERVA_MILLS|followed|KESAVANANDA')),
        isTrue,
        reason: 'the P5 followed edge must appear with its edge identifier',
      );
    });

    test('shared validated doctrine membership yields a doctrine reason', () {
      // MANEKA_GANDHI, NAVTEJ_JOHAR and SHAYARA_BANO all engage
      // MANIFEST_ARBITRARINESS.
      final navtej = service
          .discoverRelatedCases('MANEKA_GANDHI')
          .firstWhere((r) => r.caseId == 'NAVTEJ_JOHAR');
      expect(
        navtej.reasons.any((r) =>
            r.type == DiscoveryReasonType.sharedDoctrine &&
            r.references.contains('MANIFEST_ARBITRARINESS')),
        isTrue,
      );
    });

    test('shared constitutional article yields an article reason', () {
      final puttaswamy = service
          .discoverRelatedCases('MANEKA_GANDHI')
          .firstWhere((r) => r.caseId == 'PUTTASWAMY');
      expect(
        puttaswamy.reasons.any((r) =>
            r.type == DiscoveryReasonType.sharedArticle &&
            r.references.contains('21')),
        isTrue,
        reason: 'MANEKA_GANDHI and PUTTASWAMY both reference Article 21',
      );
    });

    test('shared Act reference yields an act reason', () {
      // NAVTEJ_JOHAR, JOSEPH_SHINE, BACHAN_SINGH, INDEPENDENT_THOUGHT and
      // MITHU all reference the Indian Penal Code, 1860.
      final joseph = service
          .discoverRelatedCases('NAVTEJ_JOHAR')
          .firstWhere((r) => r.caseId == 'JOSEPH_SHINE');
      final ipcKey =
          CaseSearchNormalizer.normalizeText('Indian Penal Code, 1860');
      expect(
        joseph.reasons.any((r) =>
            r.type == DiscoveryReasonType.sharedAct &&
            r.references.contains(ipcKey)),
        isTrue,
      );
    });

    test('a result may carry multiple independent reasons', () {
      // MINERVA_MILLS ↔ KESAVANANDA: followed edge, curated related edges,
      // shared BASIC_STRUCTURE doctrine and shared articles.
      final kesavananda = service
          .discoverRelatedCases('MINERVA_MILLS')
          .firstWhere((r) => r.caseId == 'KESAVANANDA');
      expect(kesavananda.reasons.length, greaterThanOrEqualTo(3));
      final kinds = kesavananda.reasonTypes;
      expect(kinds, contains(DiscoveryReasonType.graphRelationship));
      expect(kinds, contains(DiscoveryReasonType.sharedDoctrine));
      expect(kinds, contains(DiscoveryReasonType.sharedArticle));
    });

    test('reasons are ordered by kind priority then label', () {
      final kesavananda = service
          .discoverRelatedCases('MINERVA_MILLS')
          .firstWhere((r) => r.caseId == 'KESAVANANDA');
      expect(kesavananda.reasons.first.type,
          DiscoveryReasonType.graphRelationship);
      final labels = kesavananda.reasons.map((r) => r.label).toList();
      // Only equal-kind labels are lexicographically ordered; kind priority
      // governs across kinds. Verify each contiguous same-kind run is sorted.
      var i = 0;
      while (i < labels.length) {
        final kind = kesavananda.reasons[i].type;
        var j = i;
        while (j < labels.length && kesavananda.reasons[j].type == kind) {
          j++;
        }
        final run = labels.sublist(i, j);
        final sortedRun = List<String>.of(run)..sort();
        expect(run, sortedRun, reason: 'same-kind labels must be sorted');
        i = j;
      }
    });
  });

  group('C. sparse / disconnected cases', () {
    test('an isolated case yields only metadata-based reasons', () {
      // OLGA_TELLIS has no P5 graph edges and no doctrine membership; it is
      // discoverable only through shared articles/Acts.
      final results = service.discoverRelatedCases('OLGA_TELLIS');
      expect(results, isNotEmpty);
      for (final r in results) {
        expect(
          r.reasons.any(
              (reason) => reason.type == DiscoveryReasonType.graphRelationship),
          isFalse,
          reason:
              'OLGA_TELLIS has no graph edges, so no graph reason may appear',
        );
        expect(
          r.reasons.any(
              (reason) => reason.type == DiscoveryReasonType.sharedDoctrine),
          isFalse,
          reason: 'OLGA_TELLIS has no doctrine membership',
        );
      }
    });
  });

  group('D. deterministic ordering', () {
    test('identical queries return identical orderings', () {
      final a = service.discoverRelatedCases('MINERVA_MILLS');
      final b = service.discoverRelatedCases('MINERVA_MILLS');
      expect(a.map((r) => r.caseId).toList(), b.map((r) => r.caseId).toList());
      for (var i = 0; i < a.length; i++) {
        expect(a[i].reasons.map((r) => r.label).toList(),
            b[i].reasons.map((r) => r.label).toList());
      }
    });

    test('a stronger-connected case ranks above a weakly-connected one', () {
      final results = service.discoverRelatedCases('MINERVA_MILLS');
      // KESAVANANDA shares the most independent reasons with MINERVA_MILLS.
      expect(results.first.caseId, 'KESAVANANDA');
      for (var i = 1; i < results.length; i++) {
        expect(results[i - 1].reasons.length,
            greaterThanOrEqualTo(results[i].reasons.length));
      }
    });

    test('limit truncates deterministically', () {
      final full = service.discoverRelatedCases('MINERVA_MILLS');
      final limited = service.discoverRelatedCases('MINERVA_MILLS', limit: 3);
      expect(limited.length, 3);
      expect(limited.map((r) => r.caseId).toList(),
          full.take(3).map((r) => r.caseId).toList());
    });
  });

  group('E. serialization', () {
    test('RelatedCaseResult round-trips through JSON losslessly', () {
      final original = service.discoverRelatedCases('MINERVA_MILLS').first;
      final restored = RelatedCaseResult.fromJson(original.toJson());
      expect(restored.caseId, original.caseId);
      expect(restored.sourceCaseId, original.sourceCaseId);
      expect(restored.reasons.length, original.reasons.length);
      expect(restored.reasons.map((r) => r.label).toList(),
          original.reasons.map((r) => r.label).toList());
      expect(restored.caseObject.caseName, original.caseObject.caseName);
    });
  });
}
