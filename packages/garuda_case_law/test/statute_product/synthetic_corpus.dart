import 'package:garuda_acts/garuda_acts.dart'
    show ActCategory, ActKnowledgeObject, ActMetadata, ActStatus;
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_constitution/garuda_constitution.dart'
    show ArticleKnowledgeObject;
import 'package:garuda_doctrine/garuda_doctrine.dart'
    show DoctrineCategory, DoctrineKnowledgeObject, DoctrineStatus;

/// Synthetic corpus builder for the P13 unit tests (TITAN-KO-015.0 P13).
///
/// A minimal but structurally valid corpus + constitution + acts + doctrine
/// set that exercises the statute-product layer's case/doctrine association,
/// missing-data and legal-safety behavior precisely:
///
/// - `ALPHA` (2000) — fully enriched: references `Article 21`, `Article 100`,
///   `Representation of the People Act, 1951` and `Section 154 CrPC`; doctrine
///   membership in `SYNTH_DOCTRINE` and `SECOND_DOCTRINE`; a followed → `BETA`
///   edge.
/// - `BETA` (2005) — references `Art. 21` (a different spelling of the same
///   Article — must fold to the same key `21`); `SYNTH_DOCTRINE` member.
/// - `DELTA` (1995) — references `article 21` (a third spelling) and
///   `Section 41 CrPC`; no doctrine membership.
/// - `GAMMA` (2010) — sparse and disconnected: references only `Article 100`
///   (also referenced by `ALPHA`), no doctrine, empty text fields.
/// - `ZETA` (2012) — sparse: references only `Article 400`, no doctrine — the
///   only case for Article 400, giving a provision with no safely associated
///   doctrine.
/// - `EPSILON` (2008) — references `Article 300` (present in no corpus — the
///   verbatim-only resolution path).
///
/// Constitution corpus (synthetic):
///
/// - `21` — `Right to life` (Part III) — resolves `Article 21` products.
/// - `100` — `Synthetic article` — resolves `Article 100` products.
///
/// Acts corpus (synthetic):
///
/// - `Representation of the People Act, 1951` — resolves the act product.
///
/// Doctrine records:
///
/// - `SYNTH_DOCTRINE` — members `[ALPHA, BETA]` from the case records and the
///   doctrine record references; shared with `SECOND_DOCTRINE` via `ALPHA`.
/// - `SECOND_DOCTRINE` — member `[ALPHA]` only.
/// - `SPARSE_DOCTRINE` — no resolvable case references.
///
/// Nothing here is new legal data — it is a test-only corpus used to exercise
/// behavior the fully-enriched 49-case production corpus cannot produce.
CaseKnowledgeObject syntheticCase({
  required String caseId,
  required String caseName,
  required int year,
  List<String> articles = const [],
  List<String> acts = const [],
  List<String> sections = const [],
  List<String> doctrines = const [],
  List<String> precedentsFollowed = const [],
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
    sections: sections,
    doctrines: doctrines,
    precedentsFollowed: precedentsFollowed,
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

/// Builds one synthetic constitution Article record (identity metadata only).
ArticleKnowledgeObject syntheticArticle({
  required String articleNumber,
  required String officialTitle,
  String part = 'Part III',
  String chapter = 'Fundamental Rights',
}) {
  return ArticleKnowledgeObject(
    articleNumber: articleNumber,
    officialTitle: officialTitle,
    part: part,
    chapter: chapter,
    originalNumber: articleNumber,
    currentNumber: articleNumber,
    officialConstitutionalText:
        'Synthetic constitutional text of Article $articleNumber.',
    originalGarudaExplanation:
        'Synthetic explanation of Article $articleNumber.',
    objectId: 'AR-$articleNumber',
    title: 'Article $articleNumber',
    officialName: 'Article $articleNumber — $officialTitle',
    description: 'Synthetic description of Article $articleNumber.',
    effectiveDate: DateTime(1950, 1, 26),
  );
}

/// Builds one synthetic Act record (identity metadata only).
ActKnowledgeObject syntheticAct({
  required String officialName,
  required String shortTitle,
  required int year,
  required String actId,
  String actNumber = '1 of 2000',
}) {
  return ActKnowledgeObject(
    objectId: 'AC-$actId',
    actId: actId,
    metadata: ActMetadata(
      officialName: officialName,
      shortTitle: shortTitle,
      year: year,
      actNumber: actNumber,
      status: ActStatus.inForce,
      category: ActCategory.governance,
      ministry: 'Synthetic Ministry',
      gazetteReference: 'Synthetic Gazette',
      officialPdfUrl: 'https://example.invalid/$actId.pdf',
      commencementDate: DateTime(year, 1, 1),
      statementOfObjectsAndReasons:
          'Synthetic statement of objects and reasons.',
      applicability: 'Synthetic applicability.',
    ),
    evidenceReferences: ['synthetic-evidence-$actId'],
  );
}

/// The six-case synthetic corpus described at the top of this file.
List<CaseKnowledgeObject> syntheticStatuteCorpus() => [
      syntheticCase(
        caseId: 'ALPHA',
        caseName: 'Alpha v. State',
        year: 2000,
        articles: const ['Article 21', 'Article 100'],
        acts: const ['Representation of the People Act, 1951'],
        sections: const ['Section 154 CrPC'],
        doctrines: const ['SYNTH_DOCTRINE', 'SECOND_DOCTRINE'],
        precedentsFollowed: const ['BETA'],
        holdings: const ['Alpha holding.'],
        issues: const ['Alpha issue.'],
        themes: const ['equality'],
        subjects: const ['constitution'],
      ),
      syntheticCase(
        caseId: 'BETA',
        caseName: 'Beta v. Union',
        year: 2005,
        articles: const ['Art. 21'],
        doctrines: const ['SYNTH_DOCTRINE'],
        holdings: const ['Beta holding.'],
        issues: const ['Beta issue.'],
      ),
      syntheticCase(
        caseId: 'DELTA',
        caseName: 'Delta v. Union',
        year: 1995,
        articles: const ['article 21'],
        sections: const ['Section 41 CrPC'],
        holdings: const ['Delta holding.'],
        issues: const ['Delta issue.'],
      ),
      syntheticCase(
        caseId: 'GAMMA',
        caseName: 'Gamma v. State',
        year: 2010,
        articles: const ['Article 100'],
        emptyTexts: true,
      ),
      syntheticCase(
        caseId: 'EPSILON',
        caseName: 'Epsilon v. State',
        year: 2008,
        articles: const ['Article 300'],
        emptyTexts: true,
      ),
      syntheticCase(
        caseId: 'ZETA',
        caseName: 'Zeta v. State',
        year: 2012,
        articles: const ['Article 400'],
        emptyTexts: true,
      ),
    ];

/// The synthetic constitution corpus (Articles 21 and 100 only).
List<ArticleKnowledgeObject> syntheticConstitutionArticles() => [
      syntheticArticle(articleNumber: '21', officialTitle: 'Right to life'),
      syntheticArticle(
          articleNumber: '100', officialTitle: 'Synthetic article'),
    ];

/// The synthetic central-acts corpus (RPA 1951 only).
List<ActKnowledgeObject> syntheticActs() => [
      syntheticAct(
        actId: 'act_synth_rpa_1951',
        officialName: 'The Representation of the People Act, 1951',
        shortTitle: 'Representation of the People Act (RPA)',
        year: 1951,
        actNumber: '43 of 1951',
      ),
    ];

/// The synthetic doctrine records described at the top of this file.
List<DoctrineKnowledgeObject> syntheticDoctrines() => [
      syntheticDoctrine(
        doctrineId: 'SYNTH_DOCTRINE',
        name: 'Synthetic Doctrine',
        originatingCase: 'Alpha v. State',
        landmarkCases: const ['Beta v. Union'],
      ),
      syntheticDoctrine(
        doctrineId: 'SECOND_DOCTRINE',
        name: 'Second Doctrine',
        originatingCase: 'Alpha v. State',
      ),
      syntheticDoctrine(
        doctrineId: 'SPARSE_DOCTRINE',
        name: 'Sparse Doctrine',
      ),
    ];

/// A service over the synthetic corpus (self-contained: synthetic constitution,
/// acts and doctrine corpora too).
StatuteKnowledgeProductService syntheticService() =>
    StatuteKnowledgeProductService(
      cases: syntheticStatuteCorpus(),
      constitutionArticles: syntheticConstitutionArticles(),
      acts: syntheticActs(),
      doctrines: syntheticDoctrines(),
    );
