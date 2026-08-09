import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P9 — Doctrine / Article / Act collections (TITAN-KO-015.0 P9).
///
/// Collections are deterministic P6 query results reused by the P9 service.
/// They must contain only valid case IDs, order deterministically and handle
/// empty/invalid identifiers safely.
void main() {
  final service = CaseDiscoveryService();

  void expectValidResults(List<CaseSearchResult> results) {
    for (final r in results) {
      expect(service.caseIds, contains(r.caseId),
          reason: 'a collection may only contain valid corpus case IDs');
      expect(r.caseName, isNotEmpty);
    }
  }

  group('A. doctrine collections', () {
    test('BASIC_STRUCTURE resolves to its eight landmark cases', () {
      final results = service.casesForDoctrine('BASIC_STRUCTURE');
      final ids = results.map((r) => r.caseId).toSet();
      expect(
        ids,
        containsAll([
          'KESAVANANDA',
          'MINERVA_MILLS',
          'IR_COELHO',
          'L_CHANDRA_KUMAR',
          'M_NAGARAJ',
          'NJAC_2015',
          'SC_OR_1993',
          'SR_BOMMAI',
        ]),
      );
      expectValidResults(results);
    });

    test('a doctrine resolves by canonical ID or by name', () {
      final byId = service.casesForDoctrine('BASIC_STRUCTURE');
      final byName = service.casesForDoctrine('Basic Structure Doctrine');
      expect(byId.map((r) => r.caseId), byName.map((r) => r.caseId));
    });

    test('an unassociated doctrine yields an empty collection', () {
      expect(service.casesForDoctrine('ECLIPSE'), isEmpty);
    });

    test('an unknown doctrine yields an empty collection', () {
      expect(service.casesForDoctrine('NO_SUCH_DOCTRINE'), isEmpty);
      expect(service.casesForDoctrine(''), isEmpty);
    });
  });

  group('B. article collections', () {
    test('Article 21 associates its full validated set', () {
      final results = service.casesForArticle('21');
      expect(results.length, 28);
      final ids = results.map((r) => r.caseId).toSet();
      expect(ids, containsAll(['MANEKA_GANDHI', 'PUTTASWAMY', 'OLGA_TELLIS']));
      expectValidResults(results);
    });

    test('article variants fold onto the same collection', () {
      final a = service.casesForArticle('21');
      final b = service.casesForArticle('Article 21');
      expect(a.map((r) => r.caseId), b.map((r) => r.caseId));
    });

    test('an unassociated article yields an empty collection', () {
      expect(service.casesForArticle('999'), isEmpty);
    });

    test('an empty article identifier yields an empty collection', () {
      expect(service.casesForArticle(''), isEmpty);
    });
  });

  group('C. act collections', () {
    test('Indian Penal Code, 1860 associates its five cases', () {
      final results = service.casesForAct('Indian Penal Code, 1860');
      final ids = results.map((r) => r.caseId).toSet();
      expect(
        ids,
        containsAll([
          'BACHAN_SINGH',
          'JOSEPH_SHINE',
          'NAVTEJ_JOHAR',
          'INDEPENDENT_THOUGHT',
          'MITHU',
        ]),
      );
      expectValidResults(results);
    });

    test('Representation of the People Act, 1951 associates its three cases',
        () {
      final results =
          service.casesForAct('Representation of the People Act, 1951');
      final ids = results.map((r) => r.caseId).toSet();
      expect(ids, containsAll(['ADR_ASSOCIATION', 'LILY_THOMAS', 'PUCL_NOTA']));
      expectValidResults(results);
    });

    test('an unassociated Act yields an empty collection', () {
      expect(service.casesForAct('Nonexistent Act of 1900'), isEmpty);
    });
  });

  group('D. determinism and limits', () {
    test('identical queries return identical orderings', () {
      for (final query in ['BASIC_STRUCTURE', '21', 'Indian Penal Code']) {
        expect(service.casesForDoctrine(query).map((r) => r.caseId).toList(),
            service.casesForDoctrine(query).map((r) => r.caseId).toList());
        expect(service.casesForArticle(query).map((r) => r.caseId).toList(),
            service.casesForArticle(query).map((r) => r.caseId).toList());
        expect(service.casesForAct(query).map((r) => r.caseId).toList(),
            service.casesForAct(query).map((r) => r.caseId).toList());
      }
    });

    test('limit truncates deterministically', () {
      final limited = service.casesForArticle('21', limit: 5);
      expect(limited.length, 5);
      expect(limited.map((r) => r.caseId).toList(),
          service.casesForArticle('21').take(5).map((r) => r.caseId).toList());
    });
  });
}
