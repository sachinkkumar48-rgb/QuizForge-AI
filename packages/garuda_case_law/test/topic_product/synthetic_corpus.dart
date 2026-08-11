import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart'
    show DoctrineCategory, DoctrineKnowledgeObject, DoctrineStatus;

/// Synthetic corpus + syllabus config for the P14 unit tests
/// (TITAN-KO-015.0 P14).
///
/// A minimal but structurally valid corpus + doctrine set + P14 syllabus
/// configuration that exercises the topic layer's mapping, composition,
/// missing-data and legal-safety behavior precisely:
///
/// - `ALPHA` (2000) — fully enriched: P3 themes `equality`, subjects
///   `constitution`; P4 mainsThemes `Alpha mains theme`, answerKeywords
///   `Article 21` / `AlphaKeyword`, essayThemes `Alpha essay theme`,
///   relatedSyllabusAreas `[gs2]`; doctrine membership `SYNTH_DOCTRINE` /
///   `SECOND_DOCTRINE`; references `Article 21`.
/// - `BETA` (2005) — enriched: P3 themes `reservation`; P4 mainsThemes
///   `Beta mains theme`, relatedSyllabusAreas `[gs2, gs3]`; doctrine
///   membership `SYNTH_DOCTRINE`; references `Article 14`.
/// - `DELTA` (1995) — sparse: P3 themes `environment`, NO UPSC intelligence
///   (missing P4 data), no doctrine membership.
/// - `GAMMA` (2010) — sparse: no themes, no intelligence, no doctrines.
///
/// Doctrines (synthetic):
///
/// - `SYNTH_DOCTRINE` — constituent cases `[ALPHA, BETA]`.
/// - `SECOND_DOCTRINE` — constituent case `[ALPHA]` only.
/// - `SPARSE_DOCTRINE` — no resolvable case references.
///
/// P14 syllabus configuration (synthetic):
///
/// - `topic_alpha` (GS2) — members `ALPHA` (via `p4:mainsThemes`
///   `Alpha mains theme`) and `BETA` (via `p3:themes` `reservation`); ALPHA
///   also carries a second, distinct membership signal (`p3:themes` `equality`)
///   for the same topic, exercising multiple distinct signals.
/// - `topic_sparse` (GS2) — member `DELTA` (via `p3:themes` `environment`), a
///   case with no P4 UPSC data (missing upscRelevance section).
///
/// Nothing here is new legal data — it is a test-only corpus used to exercise
/// behavior the fully-enriched 49-case production corpus cannot produce.
CaseKnowledgeObject syntheticTopicCase({
  required String caseId,
  required String caseName,
  required int year,
  List<String> themes = const [],
  List<String> subjects = const [],
  List<String> mainsThemes = const [],
  List<String> answerKeywords = const [],
  List<String> essayThemes = const [],
  List<UpscSyllabusArea> syllabusAreas = const [],
  List<String> doctrines = const [],
  List<String> articles = const [],
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
    garudaExplanation: 'Synthetic explanation.',
    oneLineSummary: 'Synthetic one-line summary for $caseName.',
    detailedSummary: 'Synthetic detailed summary for $caseName.',
    relatedArticles: articles,
    doctrines: doctrines,
    themes: themes,
    subjects: subjects,
    evidenceIds: [CaseOfficialSources.evidenceIdFor(caseId)],
  );
  if (!withIntelligence) return c;
  return c.copyWith(
    judgmentIntelligence: JudgmentIntelligence(
      caseId: caseId,
      issues: const [],
      holdings: const [],
      reasoning: JudgmentReasoning(
        summary: 'Synthetic reasoning summary for $caseName.',
        approach: InterpretiveApproach.other,
        doctrinalReasoning: const [],
        reasoningTools: const [],
        evidence: const IntelligenceEvidence.unverified(),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.upheld,
        operativeResult: 'Operative result for $caseName.',
        evidence: const IntelligenceEvidence.unverified(),
      ),
      judicialSignificance: JudicialSignificance(
        constitutionalSignificance: 'Synthetic significance of $caseName.',
        legalSignificance: 'Legal significance of $caseName.',
        historicalSignificance: 'Historical significance of $caseName.',
        significanceScore: 75,
      ),
      upscIntelligence: UpscJudgmentIntelligence(
        mainsThemes: mainsThemes,
        answerKeywords: answerKeywords,
        essayThemes: essayThemes,
        relatedSyllabusAreas: syllabusAreas,
      ),
    ),
  );
}

/// Builds one synthetic doctrine record whose constituent cases are the given
/// synthetic case IDs (resolved via the doctrine record's case references).
DoctrineKnowledgeObject syntheticTopicDoctrine({
  required String doctrineId,
  required String name,
  List<String> caseNames = const [],
  DoctrineCategory category = DoctrineCategory.constitutionalInterpretation,
  DoctrineStatus currentStatus = DoctrineStatus.settledLaw,
}) {
  return DoctrineKnowledgeObject(
    objectId: 'DO-$doctrineId',
    doctrineId: doctrineId,
    name: name,
    aliases: const [],
    category: category,
    origin: 'Synthetic origin of $name.',
    currentStatus: currentStatus,
    officialDefinition: 'Synthetic official definition of $name.',
    plainLanguageExplanation: 'Synthetic plain-language explanation of $name.',
    purpose: 'Synthetic purpose of $name.',
    scope: 'Synthetic scope of $name.',
    originatingCase: caseNames.isEmpty ? '' : caseNames.first,
    historicalContext: 'Synthetic historical context of $name.',
    evolution: 'Synthetic recorded evolution of $name.',
    currentPosition: 'Synthetic recorded current position of $name.',
    oneLineSummary: 'Synthetic one-line summary of $name.',
    detailedExplanation: 'Synthetic detailed explanation of $name.',
    landmarkCases: caseNames,
    subsequentCases: const [],
    expandedBy: const [],
    limitedBy: const [],
    distinguishedIn: const [],
    primarySource: 'Synthetic primary source of $name.',
    citations: ['Synthetic citation of $name.'],
    evidenceReferences: ['Synthetic evidence reference of $name.'],
  );
}

/// The four-case synthetic corpus used by the P14 unit tests.
List<CaseKnowledgeObject> syntheticTopicCorpus() => [
      syntheticTopicCase(
        caseId: 'ALPHA',
        caseName: 'Alpha v. State',
        year: 2000,
        themes: const ['equality'],
        subjects: const ['constitution'],
        mainsThemes: const ['Alpha mains theme'],
        answerKeywords: const ['Article 21', 'AlphaKeyword'],
        essayThemes: const ['Alpha essay theme'],
        syllabusAreas: const [UpscSyllabusArea.gs2],
        doctrines: const ['SYNTH_DOCTRINE', 'SECOND_DOCTRINE'],
        articles: const ['Article 21'],
      ),
      syntheticTopicCase(
        caseId: 'BETA',
        caseName: 'Beta v. Union',
        year: 2005,
        themes: const ['reservation'],
        subjects: const ['constitution'],
        mainsThemes: const ['Beta mains theme'],
        syllabusAreas: const [UpscSyllabusArea.gs2, UpscSyllabusArea.gs3],
        doctrines: const ['SYNTH_DOCTRINE'],
        articles: const ['Article 14'],
      ),
      syntheticTopicCase(
        caseId: 'DELTA',
        caseName: 'Delta v. Union',
        year: 1995,
        themes: const ['environment'],
        subjects: const ['environmental law'],
        withIntelligence: false,
      ),
      syntheticTopicCase(
        caseId: 'GAMMA',
        caseName: 'Gamma v. State',
        year: 2010,
        withIntelligence: false,
      ),
    ];

/// The synthetic P14 syllabus configuration used by the P14 unit tests.
TopicSyllabusConfig syntheticTopicConfig() => const TopicSyllabusConfig(
      version: 'test-1',
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
          configVersion: 'test-1',
        ),
        TopicIdentity(
          id: 'topic_sparse',
          name: 'Synthetic Topic Sparse',
          area: UpscSyllabusArea.gs2,
          pedagogicalPath: 'GS Paper II → Synthetic → Sparse',
          mappingKind: TopicMappingKind.pedagogicalMapping,
          configVersion: 'test-1',
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
          caseId: 'ALPHA',
          signalField: TopicSignalField.p3Themes,
          signalValue: 'equality',
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

/// The synthetic doctrine records used by the P14 unit tests.
List<DoctrineKnowledgeObject> syntheticTopicDoctrines() => [
      syntheticTopicDoctrine(
        doctrineId: 'SYNTH_DOCTRINE',
        name: 'Synthetic Doctrine',
        caseNames: const ['Alpha v. State', 'Beta v. Union'],
      ),
      syntheticTopicDoctrine(
        doctrineId: 'SECOND_DOCTRINE',
        name: 'Second Synthetic Doctrine',
        caseNames: const ['Alpha v. State'],
      ),
      syntheticTopicDoctrine(
        doctrineId: 'SPARSE_DOCTRINE',
        name: 'Sparse Synthetic Doctrine',
      ),
    ];

/// Builds the P14 service over the synthetic corpus + config + doctrines.
TopicKnowledgeProductService buildSyntheticTopicService() =>
    TopicKnowledgeProductService(
      cases: syntheticTopicCorpus(),
      doctrines: syntheticTopicDoctrines(),
      config: syntheticTopicConfig(),
    );
