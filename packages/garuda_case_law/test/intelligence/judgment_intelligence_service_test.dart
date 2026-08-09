import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P4.3 — JudgmentIntelligenceService read accessors, build/enrich and
/// validate operations (TITAN-KO-015.0 P4).
void main() {
  final service = JudgmentIntelligenceService();
  final kesavananda = CaseSeedData.cases
      .firstWhere((c) => c.caseId == 'KESAVANANDA');

  group('Read accessors', () {
    test('getIntelligence returns the aggregate for a known case', () async {
      final intel = await service.getIntelligence('KESAVANANDA');
      expect(intel, isNotNull);
      expect(intel!.caseId, 'KESAVANANDA');
    });

    test('getBench returns an established bench', () async {
      final bench = await service.getBench('KESAVANANDA');
      expect(bench, isNotNull);
      expect(bench!.isEstablished, isTrue);
      expect(bench.benchSize, 13);
    });

    test('getHoldings / getRatio return curated content', () async {
      final holdings = await service.getHoldings('KESAVANANDA');
      final ratios = await service.getRatio('KESAVANANDA');
      expect(holdings, isNotEmpty);
      expect(holdings.first.legalPrinciple, 'Basic Structure Doctrine');
      expect(ratios, isNotEmpty);
    });

    test('getUpscIntelligence and getSyllabusAreas are populated', () async {
      final upsc = await service.getUpscIntelligence('KESAVANANDA');
      expect(upsc, isNotNull);
      expect(upsc!.prelimsFacts, isNotEmpty);
      final areas = await service.getSyllabusAreas('KESAVANANDA');
      expect(areas, contains(UpscSyllabusArea.gs2));
    });

    test('unknown caseId resolves to null/empty safely', () async {
      expect(await service.getBench('NO_SUCH_CASE'), isNull);
      expect(await service.getHoldings('NO_SUCH_CASE'), isEmpty);
      expect(await service.getIntelligence('NO_SUCH_CASE'), isNull);
    });
  });

  group('Build / enrich / validate', () {
    test('buildIntelligence derives bench/issues/ratios from the record',
        () {
      final built = service.buildIntelligence(kesavananda);
      expect(built.caseId, 'KESAVANANDA');
      expect(built.bench!.isEstablished, isTrue);
      expect(built.issues, isNotEmpty);
      expect(built.ratios, isNotEmpty);
      expect(built.holdings, isNotEmpty);
    });

    test('enrichCaseFromRecord attaches intelligence to a copy', () {
      final enriched = service.enrichCaseFromRecord(kesavananda);
      expect(enriched.judgmentIntelligence, isNotNull);
      expect(enriched.judgmentIntelligence!.caseId, 'KESAVANANDA');
    });

    test('validateIntelligence passes for a curated case', () {
      final result = service.validateIntelligence(kesavananda);
      expect(result.isValid, isTrue);
    });

    test('validateRepository passes for the whole corpus', () async {
      final result = await service.validateRepository();
      expect(result.isValid, isTrue);
    });

    test('missing intelligence is flagged by validation', () {
      final bare = _withoutIntelligence(kesavananda);
      final result = service.validateIntelligence(bare);
      expect(result.isValid, isFalse);
      expect(
          result.errors.any((e) => e.code == 'MISSING_INTELLIGENCE'), isTrue);
    });
  });

  group('Analytical helpers', () {
    test('getPrelimsKeywords aggregates facts, traps and keywords', () async {
      final keywords = await service.getPrelimsKeywords('KESAVANANDA');
      expect(keywords, isNotEmpty);
      expect(
          keywords.any((k) => k.contains('13-judge bench')), isTrue);
    });
  });
}

/// Returns a copy of the case without Judgment Intelligence attached
/// (copyWith cannot null a nullable field).
CaseKnowledgeObject _withoutIntelligence(CaseKnowledgeObject c) {
  final json = c.toJson()..remove('judgmentIntelligence');
  return CaseKnowledgeObject.fromJson(json);
}
