import 'package:garuda_case_law/garuda_case_law.dart';

/// Synthetic corpus builder for the P11 unit tests (TITAN-KO-015.0 P11).
///
/// A minimal but structurally valid corpus that exercises the explanation
/// layer's missing-data and legal-safety behavior precisely:
///
/// - `ALPHA` (2000) — fully enriched: P4 intelligence, doctrine
///   `BASIC_STRUCTURE`, Article 21, `Criminal Procedure Code`, and two direct
///   precedent edges (`followed → BETA`, `overruled → DELTA`).
/// - `BETA` (2005) — enriched: P4 intelligence, doctrine `BASIC_STRUCTURE`,
///   Article 21, but no edges of its own (only targeted by ALPHA).
/// - `GAMMA` (2010) — fully sparse and disconnected: no intelligence, no
///   articles, no Acts, no doctrines, no edges, and empty text fields.
/// - `DELTA` (1995) — enriched: P4 intelligence, Article 21, no edges of its
///   own (only targeted by ALPHA's overruled edge).
///
/// Nothing here is new legal data — it is a test-only corpus used to exercise
/// behavior the fully-enriched 49-case production corpus cannot produce.
CaseKnowledgeObject syntheticCase({
  required String caseId,
  required String caseName,
  required int year,
  List<String> articles = const [],
  List<String> acts = const [],
  List<String> doctrines = const [],
  List<String> precedentsFollowed = const [],
  List<String> precedentsOverruled = const [],
  List<String> relatedCases = const [],
  List<String> holdings = const [],
  List<String> issues = const [],
  bool withIntelligence = true,
  bool emptyTexts = false,
}) {
  final c = CaseKnowledgeObject(
    objectId: 'KO-$caseId',
    caseId: caseId,
    caseName: caseName,
    citation: 'AIR $year SC $caseId',
    year: year,
    bench: 'Bench of Five',
    historicalContext:
        emptyTexts ? '' : 'Synthetic historical context for $caseName.',
    facts: emptyTexts ? '' : 'Synthetic facts for $caseName.',
    decision: emptyTexts ? '' : 'Synthetic decision for $caseName.',
    constitutionalSignificance: emptyTexts
        ? ''
        : 'Synthetic constitutional significance for $caseName.',
    judgmentDate: DateTime(year, 1, 1),
    garudaExplanation: 'Synthetic explanation.',
    oneLineSummary:
        emptyTexts ? '' : 'Synthetic one-line summary for $caseName.',
    detailedSummary:
        emptyTexts ? '' : 'Synthetic detailed summary for $caseName.',
    relatedArticles: articles,
    relatedActs: acts,
    doctrines: doctrines,
    precedentsFollowed: precedentsFollowed,
    precedentsOverruled: precedentsOverruled,
    relatedCases: relatedCases,
  );
  if (!withIntelligence) return c;
  return c.copyWith(
    judgmentIntelligence: JudgmentIntelligence(
      caseId: caseId,
      issues: [
        for (final (i, text) in issues.indexed)
          JudgmentIssue(issueId: 'i-$caseId-$i', issue: text),
      ],
      holdings: [
        for (final (i, text) in holdings.indexed)
          JudgmentHolding(
            holdingId: 'h-$caseId-$i',
            holding: text,
            evidence: const IntelligenceEvidence.unverified(),
          ),
      ],
      reasoning: JudgmentReasoning(
        summary: 'Synthetic reasoning summary for $caseName.',
        approach: InterpretiveApproach.other,
        doctrinalReasoning: ['Synthetic doctrinal reasoning for $caseName.'],
        reasoningTools: ['Synthetic reasoning tool for $caseName.'],
        evidence: const IntelligenceEvidence.unverified(),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.upheld,
        operativeResult: 'Operative result for $caseName.',
        majorityOutcome: 'Majority outcome for $caseName.',
        evidence: const IntelligenceEvidence.unverified(),
      ),
      judicialSignificance: JudicialSignificance(
        constitutionalSignificance: 'Constitutional significance of $caseName.',
        legalSignificance: 'Legal significance of $caseName.',
        historicalSignificance: 'Historical significance of $caseName.',
        significanceScore: 75,
      ),
      upscIntelligence: UpscJudgmentIntelligence(
        prelimsFacts: ['Prelims fact for $caseName.'],
        mainsThemes: ['Mains theme for $caseName.'],
      ),
    ),
  );
}

/// The four-case synthetic corpus described at the top of this file.
List<CaseKnowledgeObject> syntheticExplanationCorpus() => [
      syntheticCase(
        caseId: 'ALPHA',
        caseName: 'Alpha v. State',
        year: 2000,
        articles: ['21'],
        acts: ['Criminal Procedure Code'],
        doctrines: ['BASIC_STRUCTURE'],
        precedentsFollowed: ['BETA'],
        precedentsOverruled: ['DELTA'],
        holdings: ['Holding of Alpha.'],
        issues: ['Issue of Alpha.'],
      ),
      syntheticCase(
        caseId: 'BETA',
        caseName: 'Beta v. Union',
        year: 2005,
        articles: ['21'],
        doctrines: ['BASIC_STRUCTURE'],
        holdings: ['Holding of Beta.'],
        issues: ['Issue of Beta.'],
      ),
      syntheticCase(
        caseId: 'GAMMA',
        caseName: 'Gamma v. Nobody',
        year: 2010,
        withIntelligence: false,
        emptyTexts: true,
      ),
      syntheticCase(
        caseId: 'DELTA',
        caseName: 'Delta v. State',
        year: 1995,
        articles: ['21'],
        holdings: ['Holding of Delta.'],
        issues: ['Issue of Delta.'],
      ),
    ];
