import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart'
    show DoctrineCategory, DoctrineKnowledgeObject, DoctrineStatus;

/// Synthetic corpus builder for the P12 unit tests (TITAN-KO-015.0 P12).
///
/// A minimal but structurally valid corpus + doctrine set that exercises the
/// doctrine-product layer's missing-data and legal-safety behavior precisely:
///
/// - `ALPHA` (2000) — fully enriched: P4 intelligence, a recorded Article 21
///   and `Criminal Procedure Code`, a followed → `BETA` edge, an overruled →
///   `DELTA` edge, and doctrine membership in `SYNTH_DOCTRINE` (establishes)
///   and `SECOND_DOCTRINE` (applies).
/// - `BETA` (2005) — enriched: P4 intelligence, Article 21, doctrine
///   `SYNTH_DOCTRINE` (applies), no edges of its own.
/// - `GAMMA` (2010) — fully sparse and disconnected: no intelligence, no
///   articles, no Acts, no doctrines, no edges, empty text fields.
/// - `DELTA` (1995) — enriched: P4 intelligence, Article 21, `Criminal
///   Procedure Code`, no edges of its own (only targeted by ALPHA's overruled
///   edge), and no doctrine membership.
///
/// Doctrine records:
///
/// - `SYNTH_DOCTRINE` — members `[ALPHA (establishes), BETA (applies)]` from
///   the originating-case / landmark-case record references; a shared-member
///   overlap with `SECOND_DOCTRINE` via `ALPHA`.
/// - `SECOND_DOCTRINE` — member `[ALPHA (applies)]` only (single-case, no
///   intra-doctrine precedent edge).
/// - `SPARSE_DOCTRINE` — no resolvable case references (zero constituent
///   cases): exercises the sparse/disconnected doctrine path.
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
  List<String> themes = const [],
  List<String> subjects = const [],
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
    themes: themes,
    subjects: subjects,
    evidenceIds: [CaseOfficialSources.evidenceIdFor(caseId)],
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

/// Builds one synthetic doctrine record. Case references are the exact display
/// case names so the P5 doctrine-case-name resolver links them deterministically.
DoctrineKnowledgeObject syntheticDoctrine({
  required String doctrineId,
  required String name,
  String? originatingCase,
  List<String> landmarkCases = const [],
  List<String> subsequentCases = const [],
  List<String> expandedBy = const [],
  List<String> limitedBy = const [],
  List<String> distinguishedIn = const [],
  DoctrineCategory category = DoctrineCategory.constitutionalInterpretation,
  DoctrineStatus currentStatus = DoctrineStatus.settledLaw,
  List<String> aliases = const [],
}) {
  return DoctrineKnowledgeObject(
    objectId: 'DO-$doctrineId',
    doctrineId: doctrineId,
    name: name,
    aliases: aliases,
    category: category,
    origin: 'Synthetic origin of $name.',
    currentStatus: currentStatus,
    officialDefinition: 'Synthetic official definition of $name.',
    plainLanguageExplanation: 'Synthetic plain-language explanation of $name.',
    purpose: 'Synthetic purpose of $name.',
    scope: 'Synthetic scope of $name.',
    originatingCase: originatingCase ?? '',
    historicalContext: 'Synthetic historical context of $name.',
    evolution: 'Synthetic recorded evolution of $name.',
    currentPosition: 'Synthetic recorded current position of $name.',
    oneLineSummary: 'Synthetic one-line summary of $name.',
    detailedExplanation: 'Synthetic detailed explanation of $name.',
    landmarkCases: landmarkCases,
    subsequentCases: subsequentCases,
    expandedBy: expandedBy,
    limitedBy: limitedBy,
    distinguishedIn: distinguishedIn,
    primarySource: 'Synthetic primary source of $name.',
    citations: ['Synthetic citation of $name.'],
    evidenceReferences: ['Synthetic evidence reference of $name.'],
  );
}

/// The four-case synthetic corpus described at the top of this file.
List<CaseKnowledgeObject> syntheticDoctrineCorpus() => [
      syntheticCase(
        caseId: 'ALPHA',
        caseName: 'Alpha v. State',
        year: 2000,
        articles: const ['Article 21'],
        acts: const ['Criminal Procedure Code'],
        doctrines: const ['SYNTH_DOCTRINE'],
        precedentsFollowed: const ['BETA'],
        precedentsOverruled: const ['DELTA'],
        holdings: const ['Due process protection applies to life and liberty.'],
        issues: const ['Does due process apply under Article 21?'],
        themes: const ['Fundamental rights'],
        subjects: const ['Polity'],
      ),
      syntheticCase(
        caseId: 'BETA',
        caseName: 'Beta v. Union',
        year: 2005,
        articles: const ['Article 21'],
        doctrines: const ['SYNTH_DOCTRINE'],
        holdings: const ['Procedural fairness is integral to Article 21.'],
        themes: const ['Fundamental rights'],
        subjects: const ['Polity'],
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
        articles: const ['Article 21'],
        acts: const ['Criminal Procedure Code'],
      ),
    ];

/// The three synthetic doctrine records described at the top of this file.
List<DoctrineKnowledgeObject> syntheticDoctrines() => [
      syntheticDoctrine(
        doctrineId: 'SYNTH_DOCTRINE',
        name: 'Synthetic Doctrine',
        originatingCase: 'Alpha v. State',
        landmarkCases: const ['Beta v. Union'],
      ),
      syntheticDoctrine(
        doctrineId: 'SECOND_DOCTRINE',
        name: 'Second Synthetic Doctrine',
        landmarkCases: const ['Alpha v. State'],
      ),
      syntheticDoctrine(
        doctrineId: 'SPARSE_DOCTRINE',
        name: 'Sparse Doctrine',
        originatingCase: 'Nonexistent v. State',
        currentStatus: DoctrineStatus.evolvingJurisprudence,
        aliases: const ['Sparse Alias'],
      ),
    ];
