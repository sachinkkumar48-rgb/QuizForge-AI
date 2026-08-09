import 'package:garuda_case_law/garuda_case_law.dart';

/// Synthetic case builder for the P10 unit tests (TITAN-KO-015.0 P10).
///
/// Mirrors the synthetic-case helper used by the P7 validator tests: a minimal
/// but structurally valid `CaseKnowledgeObject` with optional P4
/// Judgment Intelligence. Used to exercise missing-intelligence, same-year and
/// disconnected-case behavior that the fully-enriched 49-case corpus cannot
/// produce.
CaseKnowledgeObject syntheticCase({
  required String caseId,
  required String caseName,
  required int year,
  DateTime? judgmentDate,
  List<String> judges = const [],
  List<String> articles = const [],
  List<String> acts = const [],
  List<String> doctrines = const [],
  List<String> precedentsFollowed = const [],
  List<String> relatedCases = const [],
  List<String> holdings = const [],
  List<String> ratios = const [],
  List<String> issues = const [],
  bool withIntelligence = true,
  List<String> evidenceIds = const [],
}) {
  final c = CaseKnowledgeObject(
    objectId: 'KO-$caseId',
    caseId: caseId,
    caseName: caseName,
    citation: 'AIR $year SC $caseId',
    year: year,
    bench: 'Bench of Five',
    historicalContext: 'Synthetic historical context.',
    facts: 'Synthetic facts.',
    decision: 'Synthetic decision.',
    constitutionalSignificance: 'Synthetic constitutional significance.',
    judgmentDate: judgmentDate ?? DateTime(year, 1, 1),
    garudaExplanation: 'Synthetic explanation.',
    oneLineSummary: 'Synthetic one-line summary.',
    detailedSummary: 'Synthetic detailed summary.',
    judges: judges,
    relatedArticles: articles,
    relatedActs: acts,
    doctrines: doctrines,
    precedentsFollowed: precedentsFollowed,
    relatedCases: relatedCases,
    evidenceIds: evidenceIds,
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
      ratios: [
        for (final text in ratios)
          JudgmentRatio(
            ratio: text,
            evidence: const IntelligenceEvidence.unverified(),
          ),
      ],
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.upheld,
        operativeResult: 'Operative result for $caseId.',
        evidence: const IntelligenceEvidence.unverified(),
      ),
      judicialSignificance: JudicialSignificance(
        constitutionalSignificance: 'Constitutional significance of $caseId.',
      ),
    ),
  );
}
