import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P4.1 — Judgment Intelligence domain model: enums, value objects,
/// serialization round-trips and equality (TITAN-KO-015.0 P4).
void main() {
  group('OutcomeDisposition', () {
    test('exposes a stable set of dispositions', () {
      expect(OutcomeDisposition.values, containsAll([
        OutcomeDisposition.upheld,
        OutcomeDisposition.upheldWithDirections,
        OutcomeDisposition.struckDown,
        OutcomeDisposition.dismissed,
        OutcomeDisposition.guidelinesIssued,
        OutcomeDisposition.declaration,
      ]));
    });
  });

  group('IntelligenceEvidence', () {
    const evidence = IntelligenceEvidence(
      evidenceId: 'ev_KESAVANANDA_official',
      source: 'Supreme Court of India official judgment record',
      verified: true,
    );

    test('serializes and round-trips', () {
      final restored = IntelligenceEvidence.fromJson(evidence.toJson());
      expect(restored, evidence);
    });

    test('verified status is preserved', () {
      expect(evidence.verified, isTrue);
      const editorial =
          IntelligenceEvidence(evidenceId: 'x', source: '', verified: false);
      expect(editorial.verified, isFalse);
    });
  });

  group('JudgmentBench', () {
    const bench = JudgmentBench(
      benchSize: 13,
      judgeNames: ['A.N. Ray', 'S.M. Sikri'],
      benchType: JudgmentBenchType.fullBench,
      constitutionOfBench: '13-Judge Constitution Bench',
      evidence: IntelligenceEvidence(
        evidenceId: 'ev_KESAVANANDA_official',
        source: 'Supreme Court of India official judgment record',
        verified: true,
      ),
    );

    test('is established when size or judges present', () {
      expect(bench.isEstablished, isTrue);
      expect(
          const JudgmentBench(
            benchSize: 0,
            judgeNames: [],
            evidence: IntelligenceEvidence(
              evidenceId: '',
              source: '',
              verified: false,
            ),
          ).isEstablished,
          isFalse);
    });

    test('round-trips through JSON', () {
      expect(JudgmentBench.fromJson(bench.toJson()), bench);
    });
  });

  group('JudgmentIntelligence serialization', () {
    const intel = JudgmentIntelligence(
      caseId: 'KESAVANANDA',
      bench: JudgmentBench(
        benchSize: 13,
        judgeNames: ['S.M. Sikri'],
        benchType: JudgmentBenchType.fullBench,
        evidence: IntelligenceEvidence(
          evidenceId: 'ev_KESAVANANDA_official',
          source: 'Supreme Court of India official judgment record',
          verified: true,
        ),
      ),
      issues: [
        JudgmentIssue(
          issueId: 'iss_kesavananda_1',
          issue: 'Is the amending power plenary?',
          importance: IssueImportance.core,
          category: IssueCategory.constitutional,
          relatedArticles: ['Article 368'],
        ),
      ],
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_kesavananda_1',
          holding: 'Parliament cannot alter the basic structure.',
          legalPrinciple: 'Basic Structure Doctrine',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: IntelligenceEvidence(
            evidenceId: 'ev_KESAVANANDA_official',
            source: 'Supreme Court of India official judgment record',
            verified: true,
          ),
        ),
      ],
      ratios: [
        JudgmentRatio(
          ratio: 'The amending power cannot destroy the basic structure.',
          legalProposition: 'Basic Structure Doctrine',
          evidence: IntelligenceEvidence(
            evidenceId: 'ev_KESAVANANDA_official',
            source: 'Supreme Court of India official judgment record',
            verified: true,
          ),
        ),
      ],
    );

    test('toJson/fromJson preserves equality', () {
      final json = intel.toJson();
      final restored = JudgmentIntelligence.fromJson(json);
      expect(restored, intel);
    });

    test('populatedLayers counts non-empty layers', () {
      expect(intel.populatedLayers, greaterThanOrEqualTo(4));
      const empty = JudgmentIntelligence(caseId: 'X');
      expect(empty.populatedLayers, 0);
    });

    test('missing optional fields deserialize to empty/null safely', () {
      final restored = JudgmentIntelligence.fromJson(
          const JudgmentIntelligence(caseId: 'X').toJson());
      expect(restored.holdings, isEmpty);
      expect(restored.outcome, isNull);
      expect(restored.bench, isNull);
    });
  });

  group('UpscJudgmentIntelligence serialization', () {
    const upsc = UpscJudgmentIntelligence(
      prelimsFacts: ['Decided 1973 by a 13-judge bench.'],
      prelimsTraps: ['Golaknath is not current law.'],
      mainsThemes: ['Basic structure doctrine'],
      mainsArguments: ['The amending power is limited.'],
      mainsCounterarguments: ['"Amend" imports no express limitation.'],
      answerKeywords: ['Basic Structure'],
      essayThemes: ['Constitutionalism'],
      interviewAreas: ['Who defines basic structure?'],
      relatedSyllabusAreas: upscPolityCore,
    );

    test('round-trips all fields including the new analytical ones', () {
      final restored = UpscJudgmentIntelligence.fromJson(upsc.toJson());
      expect(restored, upsc);
      expect(restored.mainsCounterarguments,
          ['"Amend" imports no express limitation.']);
      expect(restored.relatedSyllabusAreas, isNotEmpty);
    });

    test('syllabus areas survive name-based serialization', () {
      final json = upsc.toJson();
      expect(json['relatedSyllabusAreas'], contains('gs2'));
      final restored = UpscJudgmentIntelligence.fromJson(json);
      expect(restored.relatedSyllabusAreas,
          contains(UpscSyllabusArea.gs2));
    });
  });

  group('JudicialSignificance serialization', () {
    const sig = JudicialSignificance(
      constitutionalSignificance: 'Foundational basic-structure judgment.',
      legalSignificance: 'Settles the amending-power limits.',
      upscSignificance: 'Most asked constitutional-law case.',
      historicalSignificance: 'Largest bench in history.',
      significanceScore: 98,
    );

    test('round-trips through JSON', () {
      expect(JudicialSignificance.fromJson(sig.toJson()), sig);
    });
  });

  group('JudgmentTimelineEvent serialization', () {
    const event = JudgmentTimelineEvent(
      year: 1973,
      event: 'Kesavananda decided.',
      significance: 'Basic structure established.',
      evidence: IntelligenceEvidence(
        evidenceId: 'ev_x',
        source: 'test source',
        verified: true,
      ),
    );

    test('round-trips through JSON', () {
      expect(JudgmentTimelineEvent.fromJson(event.toJson()), event);
    });
  });
}
