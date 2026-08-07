import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

void main() {
  group('InMemoryCaseRepository Query Tests', () {
    late InMemoryCaseRepository repository;

    setUp(() {
      repository = InMemoryCaseRepository();
    });

    test('getCases returns all 20 Phase I Landmark Cases', () async {
      final cases = await repository.getCases();
      expect(cases.length, equals(20));
    });

    test('findCase retrieves case by ID, objectId, or case name', () async {
      final kesavananda = await repository.findCase('KESAVANANDA');
      expect(kesavananda, isNotNull);
      expect(kesavananda!.caseName, contains('Kesavananda Bharati'));

      final golaknath = await repository.findCase('KO-CASE-GOLAKNATH');
      expect(golaknath, isNotNull);
      expect(golaknath!.caseId, equals('GOLAKNATH'));

      final puttaswamy = await repository.findCase('Puttaswamy');
      expect(puttaswamy, isNotNull);
      expect(puttaswamy!.citation, contains('2017'));
    });

    test('getCasesByArticle retrieves cases referencing Article 21', () async {
      final art21Cases = await repository.getCasesByArticle('21');
      expect(art21Cases, isNotEmpty);
      expect(art21Cases.any((c) => c.caseId == 'MANEKA_GANDHI'), isTrue);
      expect(art21Cases.any((c) => c.caseId == 'PUTTASWAMY'), isTrue);
    });

    test('getCasesByAmendment retrieves cases referencing 42nd Amendment', () async {
      final amd42Cases = await repository.getCasesByAmendment('42nd Amendment');
      expect(amd42Cases, isNotEmpty);
      expect(amd42Cases.any((c) => c.caseId == 'MINERVA_MILLS'), isTrue);
    });

    test('getCasesByJudge retrieves cases decided by Justice Chandrachud or Sikri', () async {
      final sikriCases = await repository.getCasesByJudge('Sikri');
      expect(sikriCases, isNotEmpty);
      expect(sikriCases.any((c) => c.caseId == 'KESAVANANDA'), isTrue);
    });

    test('searchCases performs multi-criteria search', () async {
      final basicStructureResults = await repository.searchCases('Basic Structure');
      expect(basicStructureResults, isNotEmpty);
      expect(basicStructureResults.any((c) => c.caseId == 'KESAVANANDA'), isTrue);
      expect(basicStructureResults.any((c) => c.caseId == 'MINERVA_MILLS'), isTrue);

      final privacyResults = await repository.searchCases('Privacy');
      expect(privacyResults.any((c) => c.caseId == 'PUTTASWAMY'), isTrue);
    });
  });
}
