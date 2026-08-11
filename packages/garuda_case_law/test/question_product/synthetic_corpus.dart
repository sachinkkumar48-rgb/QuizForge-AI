import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart'
    show DoctrineCategory, DoctrineKnowledgeObject, DoctrineStatus;

/// Synthetic corpus + doctrine set + topic config for the P15 unit tests
/// (TITAN-KO-015.0 P15).
///
/// A minimal but structurally valid corpus + doctrine set + P14-style syllabus
/// configuration that exercises the question layer's generation, answer
/// composition, missing-data and legal-safety behavior precisely:
///
/// - `ALPHA` (2000) — fully enriched: two P4 issues, two P4 holdings with
///   explicit `legalPrinciple`, mainsThemes `Alpha mains theme`, syllabus areas
///   `[gs2]`, doctrine membership `SYNTH_DOCTRINE`, references `Article 21`.
/// - `BETA` (2005) — enriched: one issue, one holding with a legal principle,
///   doctrine membership `SYNTH_DOCTRINE`, an explicit P5 `related` edge to
///   `ALPHA` (via `relatedCases`), references `Article 14`.
/// - `DELTA` (1995) — sparse: NO judgment intelligence (missing P4 data) → a
///   case product is omitted entirely; it is still a topic member of
///   `topic_sparse`.
/// - `GAMMA` (2010) — enriched with one issue but a holding whose
///   `legalPrinciple` is empty → issue question present, principle question
///   omitted (missing data, never fabricated).
///
/// Doctrines (synthetic):
///
/// - `SYNTH_DOCTRINE` — constituent cases `[ALPHA, BETA]`.
/// - `SECOND_DOCTRINE` — constituent case `[ALPHA]` only.
/// - `SPARSE_DOCTRINE` — no resolvable case references (overview only).
///
/// P15 topic configuration (synthetic, mirrors P14):
///
/// - `topic_alpha` (GS2) — members `ALPHA` and `BETA`.
/// - `topic_sparse` (GS2) — member `DELTA`.
///
/// Nothing here is new legal data — it is a test-only corpus used to exercise
/// behavior the fully-enriched 49-case production corpus cannot produce.

/// Builds one synthetic P4 issue.
JudgmentIssue qaIssue(String id, String text) =>
    JudgmentIssue(issueId: id, issue: text);

/// Builds one synthetic P4 holding, optionally with an explicit legal principle.
JudgmentHolding qaHolding(
  String id,
  String text, {
  String principle = '',
  String evidenceId = 'EVIDENCE',
}) =>
    JudgmentHolding(
      holdingId: id,
      holding: text,
      legalPrinciple: principle,
      scope: HoldingScope.medium,
      confidence: IntelligenceConfidence.verified,
      evidence: IntelligenceEvidence(
        evidenceId: evidenceId,
        source: 'synthetic-official',
        verified: true,
      ),
    );

/// Builds one synthetic case with configurable P3/P4 fields.
CaseKnowledgeObject qaCase({
  required String caseId,
  required String caseName,
  required int year,
  List<String> themes = const [],
  List<String> subjects = const [],
  List<String> mainsThemes = const [],
  List<UpscSyllabusArea> syllabusAreas = const [],
  List<String> doctrines = const [],
  List<String> articles = const [],
  List<String> acts = const [],
  List<String> relatedCases = const [],
  List<JudgmentIssue> issues = const [],
  List<JudgmentHolding> holdings = const [],
  JudgmentIntelligence? intelligence,
  bool withIntelligence = true,
}) {
  final c = CaseKnowledgeObject(
    objectId: 'KO-$caseId',
    caseId: caseId,
    caseName: caseName,
    citation: 'AIR $year SC $caseId',
    year: year,
    bench: 'Bench of Five',
    historicalContext: 'Synthetic historical context for $caseName.',
    facts: 'Synthetic facts for $caseName.',
    decision: 'Synthetic decision for $caseName.',
    constitutionalSignificance: 'Synthetic significance for $caseName.',
    judgmentDate: DateTime(year, 1, 1),
    garudaExplanation: 'Synthetic explanation for $caseName.',
    oneLineSummary: 'Synthetic one-line summary for $caseName.',
    detailedSummary: 'Synthetic detailed summary for $caseName.',
    relatedArticles: articles,
    relatedActs: acts,
    relatedCases: relatedCases,
    doctrines: doctrines,
    themes: themes,
    subjects: subjects,
    evidenceIds: [CaseOfficialSources.evidenceIdFor(caseId)],
  );
  if (!withIntelligence) return c;
  final intel = intelligence ??
      JudgmentIntelligence(
        caseId: caseId,
        issues: issues,
        holdings: holdings,
        upscIntelligence: UpscJudgmentIntelligence(
          mainsThemes: mainsThemes,
          answerKeywords: const [],
          essayThemes: const [],
          relatedSyllabusAreas: syllabusAreas,
        ),
      );
  return c.copyWith(judgmentIntelligence: intel);
}

/// Builds one synthetic doctrine record.
DoctrineKnowledgeObject qaDoctrine({
  required String doctrineId,
  required String name,
  List<String> caseNames = const [],
  DoctrineCategory category = DoctrineCategory.constitutionalInterpretation,
}) {
  return DoctrineKnowledgeObject(
    objectId: 'DO-$doctrineId',
    doctrineId: doctrineId,
    name: name,
    aliases: const [],
    category: category,
    origin: 'Synthetic origin of $name.',
    currentStatus: DoctrineStatus.settledLaw,
    officialDefinition: 'Synthetic official definition of $name.',
    plainLanguageExplanation: 'Synthetic plain-language explanation of $name.',
    oneLineSummary: 'Synthetic one-line summary of $name.',
    purpose: 'Synthetic purpose of $name.',
    scope: 'Synthetic scope of $name.',
    originatingCase: caseNames.isEmpty ? '' : caseNames.first,
    historicalContext: 'Synthetic historical context of $name.',
    evolution: 'Synthetic recorded evolution of $name.',
    currentPosition: 'Synthetic recorded current position of $name.',
    detailedExplanation: 'Synthetic detailed explanation of $name.',
    landmarkCases: caseNames,
    subsequentCases: const [],
    expandedBy: const [],
    limitedBy: const [],
    distinguishedIn: const [],
    primarySource: 'Synthetic primary source of $name.',
    citations: const [],
    evidenceReferences: const [],
  );
}

/// The four-case synthetic corpus used by the P15 unit tests.
List<CaseKnowledgeObject> syntheticQaCorpus() => [
      qaCase(
        caseId: 'ALPHA',
        caseName: 'Alpha v. State',
        year: 2000,
        themes: const ['equality'],
        subjects: const ['constitution'],
        mainsThemes: const ['Alpha mains theme'],
        syllabusAreas: const [UpscSyllabusArea.gs2],
        doctrines: const ['SYNTH_DOCTRINE'],
        articles: const ['Article 21'],
        issues: [
          qaIssue(
              'iss_alpha_1', 'Whether the state action violates Article 21.'),
          qaIssue('iss_alpha_2',
              'Whether the impugned law is a reasonable restriction.'),
        ],
        holdings: [
          qaHolding(
            'hol_alpha_1',
            'The court held that procedural fairness is essential.',
            principle:
                'Procedural fairness is essential to a valid restriction.',
            evidenceId: CaseOfficialSources.evidenceIdFor('ALPHA'),
          ),
          qaHolding(
            'hol_alpha_2',
            'The court upheld the law as a reasonable restriction.',
            principle: 'A restriction must be proportionate to be reasonable.',
            evidenceId: CaseOfficialSources.evidenceIdFor('ALPHA'),
          ),
        ],
      ),
      qaCase(
        caseId: 'BETA',
        caseName: 'Beta v. Union',
        year: 2005,
        themes: const ['reservation'],
        subjects: const ['constitution'],
        mainsThemes: const ['Beta mains theme'],
        syllabusAreas: const [
          UpscSyllabusArea.gs2,
          UpscSyllabusArea.gs3,
        ],
        doctrines: const ['SYNTH_DOCTRINE'],
        articles: const ['Article 14'],
        relatedCases: const ['ALPHA'],
        issues: [
          qaIssue('iss_beta_1', 'Whether reservation quotas violate equality.'),
        ],
        holdings: [
          qaHolding(
            'hol_beta_1',
            'The court upheld the reservation policy.',
            principle:
                'Reservation is an exception to equality and must be balanced.',
            evidenceId: CaseOfficialSources.evidenceIdFor('BETA'),
          ),
        ],
      ),
      qaCase(
        caseId: 'DELTA',
        caseName: 'Delta v. Authority',
        year: 1995,
        themes: const ['environment'],
        subjects: const ['environment'],
        withIntelligence: false,
      ),
      qaCase(
        caseId: 'GAMMA',
        caseName: 'Gamma v. Regulator',
        year: 2010,
        themes: const ['governance'],
        subjects: const ['governance'],
        acts: const ['Reasonable Restrictions Act, 2000'],
        issues: [
          qaIssue('iss_gamma_1',
              'Whether the regulator exceeded its jurisdiction.'),
        ],
        holdings: [
          qaHolding('hol_gamma_1', 'The regulator acted within its powers.'),
        ],
      ),
    ];

/// The synthetic doctrine set used by the P15 unit tests.
List<DoctrineKnowledgeObject> syntheticQaDoctrines() => [
      qaDoctrine(
        doctrineId: 'SYNTH_DOCTRINE',
        name: 'Synthetic Doctrine',
        caseNames: const ['Alpha v. State', 'Beta v. Union'],
      ),
      qaDoctrine(
        doctrineId: 'SECOND_DOCTRINE',
        name: 'Second Synthetic Doctrine',
        caseNames: const ['Alpha v. State'],
      ),
      qaDoctrine(
        doctrineId: 'SPARSE_DOCTRINE',
        name: 'Sparse Synthetic Doctrine',
      ),
    ];

/// The synthetic P15 topic configuration (pedagogical mapping, not official
/// UPSC syllabus).
TopicSyllabusConfig syntheticQaTopicConfig() => const TopicSyllabusConfig(
      version: 'p15-test-1',
      mappingDeclaration:
          'Synthetic test mapping declaration. Topic membership is a '
          'pedagogical grouping and does NOT establish a legal relationship.',
      topics: [
        TopicIdentity(
          id: 'topic_alpha',
          name: 'Synthetic Topic Alpha',
          area: UpscSyllabusArea.gs2,
          pedagogicalPath: 'GS Paper II → Synthetic → Alpha',
          mappingKind: TopicMappingKind.pedagogicalMapping,
          configVersion: 'p15-test-1',
        ),
        TopicIdentity(
          id: 'topic_sparse',
          name: 'Synthetic Topic Sparse',
          area: UpscSyllabusArea.gs2,
          pedagogicalPath: 'GS Paper II → Synthetic → Sparse',
          mappingKind: TopicMappingKind.pedagogicalMapping,
          configVersion: 'p15-test-1',
        ),
      ],
      memberships: [
        TopicMembership(
          topicId: 'topic_alpha',
          caseId: 'ALPHA',
          signalField: TopicSignalField.p4MainsThemes,
          signalValue: 'Alpha mains theme',
        ),
        TopicMembership(
          topicId: 'topic_alpha',
          caseId: 'BETA',
          signalField: TopicSignalField.p3Themes,
          signalValue: 'reservation',
        ),
        TopicMembership(
          topicId: 'topic_sparse',
          caseId: 'DELTA',
          signalField: TopicSignalField.p3Themes,
          signalValue: 'environment',
        ),
      ],
      overviews: {
        'topic_alpha': 'Synthetic overview of topic alpha.',
        'topic_sparse': 'Synthetic overview of topic sparse.',
      },
    );

/// Builds the P15 service over the synthetic corpus + doctrines + topic config.
QuestionKnowledgeProductService buildSyntheticQaService() =>
    QuestionKnowledgeProductService(
      cases: syntheticQaCorpus(),
      doctrines: syntheticQaDoctrines(),
      topicProductService: TopicKnowledgeProductService(
        cases: syntheticQaCorpus(),
        doctrines: syntheticQaDoctrines(),
        config: syntheticQaTopicConfig(),
      ),
    );
