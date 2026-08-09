import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P4.7 — Evidence-gated validation of Judgment Intelligence
/// (TITAN-KO-015.0 P4).
void main() {
  final kesavananda =
      CaseSeedData.cases.firstWhere((c) => c.caseId == 'KESAVANANDA');

  group('Validator: corpus', () {
    test('whole corpus validates without errors', () {
      final result = JudgmentIntelligenceValidator.validateRepository(
          CaseSeedData.cases);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });
  });

  group('Validator: structural integrity', () {
    test('missing intelligence is an error', () {
      final bare = _withoutIntelligence(kesavananda);
      final result = JudgmentIntelligenceValidator.validate(bare);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'MISSING_INTELLIGENCE'),
          isTrue);
    });

    test('duplicate holding IDs are an error', () {
      final intel = kesavananda.judgmentIntelligence!;
      final dupIntel = intel.copyWith(
        holdings: [
          intel.holdings.first,
          intel.holdings.first,
        ],
      );
      final result =
          JudgmentIntelligenceValidator.validate(kesavananda.copyWith(
              judgmentIntelligence: dupIntel));
      expect(result.errors.any((e) => e.code == 'DUPLICATE_HOLDING_ID'),
          isTrue);
    });

    test('invalid significance score is an error', () {
      final intel = kesavananda.judgmentIntelligence!;
      final sig = intel.judicialSignificance!;
      final badSig = JudicialSignificance(
        constitutionalSignificance: sig.constitutionalSignificance,
        legalSignificance: sig.legalSignificance,
        upscSignificance: sig.upscSignificance,
        historicalSignificance: sig.historicalSignificance,
        significanceScore: 150,
      );
      final result = JudgmentIntelligenceValidator.validate(
          kesavananda.copyWith(
              judgmentIntelligence: intel.copyWith(
                  judicialSignificance: badSig)));
      expect(
          result.errors
              .any((e) => e.code == 'INVALID_SIGNIFICANCE_SCORE'),
          isTrue);
    });

    test('verified claim with unregistered evidence is an error', () {
      final intel = kesavananda.judgmentIntelligence!;
      const unregistered = JudgmentHolding(
        holdingId: 'hol_test',
        holding: 'A verified claim.',
        legalPrinciple: 'Test',
        scope: HoldingScope.medium,
        confidence: IntelligenceConfidence.verified,
        evidence: IntelligenceEvidence(
            evidenceId: 'ev_UNREGISTERED',
            source: 'Unknown',
            verified: true),
      );
      final result = JudgmentIntelligenceValidator.validate(
          kesavananda.copyWith(
              judgmentIntelligence:
                  intel.copyWith(holdings: [...intel.holdings, unregistered])));
      expect(
          result.errors
              .any((e) => e.code == 'UNREGISTERED_VERIFIED_EVIDENCE'),
          isTrue);
    });

    test('empty holdings is a warning, not an error', () {
      final intel = kesavananda.judgmentIntelligence!;
      final result = JudgmentIntelligenceValidator.validate(
          kesavananda.copyWith(
              judgmentIntelligence: intel.copyWith(holdings: const [])));
      expect(result.isValid, isTrue);
      expect(
          result.warnings
              .any((e) => e.code == 'EMPTY_HOLDINGS'),
          isTrue);
    });
  });

  group('CaseValidator integration', () {
    test('intelligence errors surface through CaseValidator', () async {
      final bare = _withoutIntelligence(kesavananda);
      final repo = _ListCaseRepository([bare]);
      final result = await CaseValidator.validateRepository(repo);
      expect(result.isValid, isFalse);
      expect(
          result.errors.any((e) => e.code == 'INTEL_MISSING_INTELLIGENCE'),
          isTrue);
    });

    test('validateIntelligence returns structured issues for a repository',
        () async {
      final result = await CaseValidator.validateIntelligence(
          InMemoryCaseRepository());
      expect(result.isValid, isTrue);
      expect(result.issues, isA<List<IntelligenceValidationIssue>>());
    });
  });
}

/// Returns a copy of the case without Judgment Intelligence attached
/// (copyWith cannot null a nullable field).
CaseKnowledgeObject _withoutIntelligence(CaseKnowledgeObject c) {
  final json = c.toJson()..remove('judgmentIntelligence');
  return CaseKnowledgeObject.fromJson(json);
}

/// Minimal repository backed by a fixed case list, for validator tests.
class _ListCaseRepository implements CaseRepository {
  final List<CaseKnowledgeObject> _cases;
  _ListCaseRepository(this._cases);

  @override
  Future<List<CaseKnowledgeObject>> getCases() async => _cases;

  @override
  Future<CaseKnowledgeObject?> findCase(String idOrName) async =>
      _cases.where((c) =>
          c.caseId == idOrName ||
          c.objectId == idOrName ||
          c.caseName == idOrName).firstOrNull;

  @override
  Future<List<CaseKnowledgeObject>> getCasesByAmendment(String amendment) async =>
      const [];

  @override
  Future<List<CaseKnowledgeObject>> getCasesByArticle(String articleNumber) async =>
      const [];

  @override
  Future<List<CaseKnowledgeObject>> getCasesByJudge(String judgeName) async =>
      const [];

  @override
  Future<List<CaseKnowledgeObject>> searchCases(String query) async =>
      _cases.where((c) =>
          c.caseName.toLowerCase().contains(query.toLowerCase())).toList();
}
