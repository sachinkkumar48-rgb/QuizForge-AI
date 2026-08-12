import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart'
    show DoctrineKnowledgeObject;

import '../question_product/synthetic_corpus.dart'
    show qaCase, qaDoctrine, qaHolding, qaIssue;

/// Synthetic corpus + doctrine set + topic config for the P16 unit tests
/// (TITAN-KO-015.0 P16).
///
/// A minimal but structurally valid corpus + doctrine set + P14-style syllabus
/// configuration that exercises the navigator's composition and legal-safety
/// behavior precisely. Every relationship the navigator may emit is explicitly
/// seeded so that tests can assert exact provenance, directionality and
/// semantics:
///
/// Cases (P3 corpus; `precedents*` / `relatedCases` / `relatedArticles` /
/// `relatedActs` / `sections` / `doctrines` are the validated relationship
/// fields the P5 graph and P3/P13 provision map read):
///
/// - `ALPHA` (2000) — enriched (issues + holdings → P15 question product).
///   - `relatedCases: [BETA]` → P5 edge ALPHA → BETA (`related`, outgoing).
///   - `doctrines: [SYNTH_DOCTRINE]` → P5 edge ALPHA → SYNTH_DOCTRINE
///     (`engages`).
///   - `relatedArticles: [Article 21]` → P13 provision `article:21`.
///   - topic member of `topic_alpha`.
/// - `BETA` (2005) — enriched.
///   - `precedentsFollowed: [ALPHA]` → P5 edge BETA → ALPHA (`followed`,
///     incoming to ALPHA).
///   - `doctrines: [SYNTH_DOCTRINE]` → P5 edge BETA → SYNTH_DOCTRINE.
///   - `relatedActs: [Representation of the People Act, 1951]` → provision
///     `act:representation of the people act 1951`.
///   - topic member of `topic_alpha`.
/// - `GAMMA` (2010) — enriched.
///   - `precedentsDistinguished: [ALPHA]` → P5 edge GAMMA → ALPHA
///     (`distinguished`, incoming to ALPHA).
///   - `sections: [Section 154 CrPC]` → provision `section:section 154 crpc`.
/// - `DELTA` (1995) — sparse: NO judgment intelligence → no P15 question
///   product (missing product → omitted). It is a member of `topic_sparse`
///   only, so its topic-membership reference exists while its question product
///   does not.
///
/// Doctrines (synthetic):
///
/// - `SYNTH_DOCTRINE` — constituent cases `[ALPHA, BETA]` via their `doctrines`
///   field.
/// - `SECOND_DOCTRINE` — no resolvable case references (overview only).
///
/// P16 topic configuration (synthetic, mirrors P14):
///
/// - `topic_alpha` (GS2) — members `ALPHA`, `BETA`.
/// - `topic_sparse` (GS2) — member `DELTA`.
///
/// Nothing here is new legal data — it is a test-only corpus used to exercise
/// behavior the fully-enriched 49-case production corpus cannot produce.

/// Builds the synthetic corpus cases.
List<CaseKnowledgeObject> navCases() => [
      qaCase(
        caseId: 'ALPHA',
        caseName: 'Alpha Case',
        year: 2000,
        articles: const ['Article 21'],
        relatedCases: const ['BETA'],
        doctrines: const ['SYNTH_DOCTRINE'],
        mainsThemes: const ['Alpha mains theme'],
        syllabusAreas: const [UpscSyllabusArea.gs2],
        issues: [qaIssue('ALPHA-1', 'Alpha issue')],
        holdings: [
          qaHolding('ALPHA-H', 'Alpha holding', principle: 'Alpha principle'),
        ],
      ),
      qaCase(
        caseId: 'BETA',
        caseName: 'Beta Case',
        year: 2005,
        acts: const ['Representation of the People Act, 1951'],
        doctrines: const ['SYNTH_DOCTRINE'],
        mainsThemes: const ['Beta mains theme'],
        syllabusAreas: const [UpscSyllabusArea.gs2],
        issues: [qaIssue('BETA-1', 'Beta issue')],
        holdings: [
          qaHolding('BETA-H', 'Beta holding', principle: 'Beta principle'),
        ],
      ).copyWith(precedentsFollowed: const ['ALPHA']),
      qaCase(
        caseId: 'GAMMA',
        caseName: 'Gamma Case',
        year: 2010,
        mainsThemes: const ['Gamma mains theme'],
        syllabusAreas: const [UpscSyllabusArea.gs2],
        issues: [qaIssue('GAMMA-1', 'Gamma issue')],
        holdings: [
          qaHolding('GAMMA-H', 'Gamma holding', principle: 'Gamma principle'),
        ],
      ).copyWith(
        sections: const ['Section 154 CrPC'],
        precedentsDistinguished: const ['ALPHA'],
      ),
      qaCase(
        caseId: 'DELTA',
        caseName: 'Delta Case',
        year: 1995,
        withIntelligence: false,
      ),
    ];

/// Builds the synthetic doctrine records.
List<DoctrineKnowledgeObject> navDoctrines() => [
      // No originating-case is designated in the record, so every case→doctrine
      // edge keeps the deterministic `engages` role from the case `doctrines`
      // field (the doctrine-record role-override path is exercised by the real
      // production corpus in the corpus tests).
      qaDoctrine(
        doctrineId: 'SYNTH_DOCTRINE',
        name: 'Synthetic Doctrine',
      ),
      qaDoctrine(
        doctrineId: 'SECOND_DOCTRINE',
        name: 'Second Synthetic Doctrine',
      ),
    ];

/// Builds a synthetic P14-style syllabus configuration.
TopicSyllabusConfig navTopicConfig() => const TopicSyllabusConfig(
      version: 'p16-test-v1',
      mappingDeclaration:
          'Test-only pedagogical mapping for P16; not an official UPSC syllabus.',
      topics: [
        TopicIdentity(
          id: 'topic_alpha',
          name: 'Alpha Topic',
          area: UpscSyllabusArea.gs2,
          pedagogicalPath: 'GS Paper II → Test',
          mappingKind: TopicMappingKind.pedagogicalMapping,
          configVersion: 'p16-test-v1',
        ),
        TopicIdentity(
          id: 'topic_sparse',
          name: 'Sparse Topic',
          area: UpscSyllabusArea.gs2,
          pedagogicalPath: 'GS Paper II → Test',
          mappingKind: TopicMappingKind.pedagogicalMapping,
          configVersion: 'p16-test-v1',
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
          signalField: TopicSignalField.p4MainsThemes,
          signalValue: 'Beta mains theme',
        ),
        TopicMembership(
          topicId: 'topic_sparse',
          caseId: 'DELTA',
          signalField: TopicSignalField.p3Themes,
          signalValue: 'Delta theme',
        ),
      ],
      overviews: {
        'topic_alpha': 'Alpha topic editorial overview.',
        'topic_sparse': 'Sparse topic editorial overview.',
      },
    );

/// Builds a P16 navigator over the synthetic corpus + doctrine set + topic
/// config. The topic service must be wired with the synthetic config.
KnowledgeProductNavigatorService buildSyntheticNavigator() {
  final cases = navCases();
  final doctrines = navDoctrines();
  final topicService = TopicKnowledgeProductService(
    cases: cases,
    doctrines: doctrines,
    config: navTopicConfig(),
  );
  return KnowledgeProductNavigatorService(
    cases: cases,
    doctrines: doctrines,
    topicProductService: topicService,
  );
}
