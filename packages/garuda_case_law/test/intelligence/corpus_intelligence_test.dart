import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// Corpus-wide intelligence integrity (TITAN-KO-015.0 P4).
///
/// Every one of the 49 landmark cases must carry complete, evidence-gated
/// Judgment Intelligence: a seed entry, derived bench/issues/ratios, curated
/// holdings/outcome/significance/UPSC content, and clean validation.
void main() {
  final cases = CaseSeedData.cases;

  group('Corpus Intelligence Coverage', () {
    test('all 49 seeded cases carry Judgment Intelligence', () {
      expect(cases.length, 49);
      for (final c in cases) {
        expect(c.judgmentIntelligence, isNotNull,
            reason: '${c.caseId} must carry Judgment Intelligence');
      }
    });

    test('every case has a curated seed entry in the registry', () {
      final seeds = JudgmentIntelligenceSeedData.seeds;
      expect(seeds.length, 49);
      final caseIds = cases.map((c) => c.caseId).toSet();
      expect(seeds.keys.toSet(), caseIds,
          reason: 'seed keys must exactly match the corpus case IDs');
    });

    test('bench is established for every case', () {
      for (final c in cases) {
        final bench = c.judgmentIntelligence!.bench!;
        expect(bench.isEstablished, isTrue,
            reason: '${c.caseId} bench must be established');
        expect(bench.judgeNames, isNotEmpty,
            reason: '${c.caseId} must have judge names');
      }
    });

    test('every case has at least one issue and one ratio', () {
      for (final c in cases) {
        final intel = c.judgmentIntelligence!;
        expect(intel.issues, isNotEmpty, reason: '${c.caseId} needs issues');
        expect(intel.ratios, isNotEmpty, reason: '${c.caseId} needs ratios');
      }
    });

    test('every case has curated holdings, outcome and significance', () {
      for (final c in cases) {
        final intel = c.judgmentIntelligence!;
        expect(intel.holdings, isNotEmpty,
            reason: '${c.caseId} needs curated holdings');
        expect(intel.outcome, isNotNull,
            reason: '${c.caseId} needs an outcome');
        expect(intel.judicialSignificance, isNotNull,
            reason: '${c.caseId} needs judicial significance');
        expect(intel.upscIntelligence, isNotNull,
            reason: '${c.caseId} needs UPSC intelligence');
      }
    });

    test('every case has a decision-year timeline event', () {
      for (final c in cases) {
        final intel = c.judgmentIntelligence!;
        expect(intel.timeline, isNotEmpty,
            reason: '${c.caseId} needs a timeline');
        final decisionEvent =
            intel.timeline.where((t) => t.year == c.year).isNotEmpty;
        expect(decisionEvent, isTrue,
            reason: '${c.caseId} timeline must include the decision year');
      }
    });

    test('significance scores are within 0-100 and benchmark key cases high',
        () {
      for (final c in cases) {
        final score = c.judgmentIntelligence!.judicialSignificance!
            .significanceScore;
        expect(score, inInclusiveRange(0, 100), reason: c.caseId);
      }
      expect(
          cases
              .firstWhere((c) => c.caseId == 'KESAVANANDA')
              .judgmentIntelligence!
              .judicialSignificance!
              .significanceScore,
          greaterThanOrEqualTo(95));
      expect(
          cases
              .firstWhere((c) => c.caseId == 'PUTTASWAMY')
              .judgmentIntelligence!
              .judicialSignificance!
              .significanceScore,
          greaterThanOrEqualTo(95));
    });
  });

  group('Corpus Evidence Integrity', () {
    test('no curated holdings/ratios/outcomes claim verified without registered '
        'evidence', () {
      for (final c in cases) {
        final intel = c.judgmentIntelligence!;
        final verifiedRefs = <String>[
          for (final h in intel.holdings) h.evidence.evidenceId,
          for (final r in intel.ratios) r.evidence.evidenceId,
          if (intel.outcome != null) intel.outcome!.evidence.evidenceId,
        ];
        for (final ref in verifiedRefs) {
          expect(CaseOfficialSources.isRegisteredEvidence(ref), isTrue,
              reason: '$ref for ${c.caseId} must resolve');
        }
      }
    });

    test('official source is present on every case', () {
      for (final c in cases) {
        expect(c.officialSource, isNotEmpty,
            reason: '${c.caseId} needs an official source');
      }
    });
  });

  group('Corpus Validation', () {
    test('the whole corpus passes the evidence-gated intelligence validator',
        () {
      final result = JudgmentIntelligenceValidator.validateRepository(cases);
      final errorList = result.issues
          .where((i) => i.severity == IntelligenceIssueSeverity.error)
          .map((e) => e.toString())
          .toList();
      if (errorList.isNotEmpty) {
        print('Intelligence errors:\n${errorList.join('\n')}');
      }
      expect(result.isValid, isTrue);
    });

    test('CaseValidator.validateRepository remains clean with intelligence '
        'checks enabled', () async {
      final result =
          await CaseValidator.validateRepository(InMemoryCaseRepository());
      if (!result.isValid) {
        print('Validator errors: ${result.errors}');
      }
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });
  });
}
