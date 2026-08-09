import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart' show DoctrineSeedData;

/// P7.1 — CorpusValidator behavior (TITAN-KO-015.0 P7).
///
/// Each test carries a genuine negative case (a real defect injected into an
/// otherwise-valid corpus) and asserts the specific issue code that must fire.
/// The real corpus must validate 49/49 without any errors.
void main() {
  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  CaseKnowledgeObject makeCase({
    String caseId = 'SYNTH_CASE',
    String? objectId,
    String caseName = 'Synthetic Case v. Union of India',
    int year = 2025,
    String? citation,
    List<String>? evidenceIds,
    List<String> precedentsFollowed = const [],
    List<String> precedentsOverruled = const [],
    List<String> precedentsDistinguished = const [],
    List<String> relatedCases = const [],
    List<String> relatedArticles = const [],
    List<String> relatedActs = const [],
    List<String> sections = const [],
    List<String> doctrines = const [],
    List<String> aliases = const [],
    List<PrecedentRelationship>? precedentRelationships,
    JudgmentIntelligence? judgmentIntelligence,
  }) =>
      CaseKnowledgeObject(
        objectId: objectId ?? 'KO-CASE-$caseId',
        caseId: caseId,
        caseName: caseName,
        citation: citation ?? 'AIR 2025 SC $caseId',
        year: year,
        bench: 'Bench of Five',
        historicalContext: 'Synthetic context.',
        facts: 'Synthetic facts.',
        decision: 'Synthetic decision.',
        constitutionalSignificance: 'Synthetic significance.',
        judgmentDate: DateTime(2025, 1, 1),
        garudaExplanation: 'Synthetic explanation.',
        oneLineSummary: 'Synthetic summary.',
        detailedSummary: 'Synthetic detailed summary.',
        ratioDecidendi: const ['Synthetic ratio.'],
        aliases: aliases,
        evidenceIds: evidenceIds ?? [CaseOfficialSources.evidenceIdFor(caseId)],
        precedentsFollowed: precedentsFollowed,
        precedentsOverruled: precedentsOverruled,
        precedentsDistinguished: precedentsDistinguished,
        relatedCases: relatedCases,
        relatedArticles: relatedArticles,
        relatedActs: relatedActs,
        sections: sections,
        doctrines: doctrines,
        precedentRelationships: precedentRelationships ?? const [],
        judgmentIntelligence: judgmentIntelligence,
      );

  /// A minimal Judgment Intelligence for a synthetic case: reuses an existing
  /// template, retargets it to [caseId], and points EVERY evidenced component
  /// (bench, holdings, ratios, reasoning, outcome, timeline) at [evidenceId].
  JudgmentIntelligence intelWithEvidence(String caseId, String evidenceId) {
    final template = CaseSeedData.cases.first.judgmentIntelligence!.toJson();
    template['caseId'] = caseId;

    void setEvidence(dynamic holder) {
      final map = holder as Map<String, dynamic>;
      final evidence = map['evidence'];
      if (evidence is Map<String, dynamic>) {
        evidence['evidenceId'] = evidenceId;
      }
    }

    if (template['bench'] != null) setEvidence(template['bench']);
    for (final h in template['holdings'] as List) {
      setEvidence(h);
    }
    for (final r in template['ratios'] as List) {
      setEvidence(r);
    }
    if (template['reasoning'] != null) setEvidence(template['reasoning']);
    if (template['outcome'] != null) setEvidence(template['outcome']);
    for (final t in template['timeline'] as List) {
      setEvidence(t);
    }
    return JudgmentIntelligence.fromJson(template);
  }

  final corpus = CaseSeedData.cases;

  CorpusValidator withCases(List<CaseKnowledgeObject> cases) =>
      CorpusValidator(cases: cases);

  List<CorpusValidationIssue> codesWith(
          CorpusValidationReport report, String code) =>
      report.issues.where((i) => i.code == code).toList();

  // -------------------------------------------------------------------------
  // 1. Real corpus passes validation
  // -------------------------------------------------------------------------

  group('1. real 49-case corpus', () {
    test('validates 49/49 with zero errors', () async {
      final report = await CorpusValidator().validate();
      expect(report.totalCases, 49);
      expect(report.validCases, 49);
      expect(report.invalidCases, 0);
      expect(report.isValid, isTrue);
      expect(report.errorCount, 0);
      expect(report.evidenceCoverage, 1.0);
      expect(report.brokenReferenceCount, 0);
      expect(report.graphConsistent, isTrue);
      expect(report.serializationLossless, isTrue);
    });

    test('report is machine-readable JSON', () async {
      final report = await CorpusValidator().validate();
      final json = report.toJson();
      expect(json['totalCases'], 49);
      expect(json['validCases'], 49);
      expect(json['errorCount'], 0);
      expect(json['isValid'], isTrue);
      expect(json['issues'], isA<List<dynamic>>());
      expect(json['evidenceCoverage'], 1.0);
      expect(json['graphConsistent'], isTrue);
      expect(json['serializationLossless'], isTrue);
    });

    test('surfaces the corpus identity warnings it genuinely contains', () async {
      final report = await CorpusValidator().validate();
      expect(codesWith(report, 'CORPUS_DUPLICATE_CASE_NAME'), isNotEmpty);
      expect(codesWith(report, 'CORPUS_ALIAS_COLLISION'), isNotEmpty);
      expect(codesWith(report, 'GRAPH_ISOLATED_CASE'), isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // A. Corpus identity
  // -------------------------------------------------------------------------

  group('A. corpus identity', () {
    test('2. duplicate case ID is detected', () async {
      final dup = makeCase(caseId: 'KESAVANANDA', caseName: 'Second Kesavananda');
      final report = await withCases([...corpus, dup]).validate();
      expect(codesWith(report, 'CORPUS_DUPLICATE_CASE_ID'), isNotEmpty);
    });

    test('3. duplicate canonical case name is detected', () async {
      // Inject a case whose normalized name equals an existing corpus name.
      final named = corpus.first;
      final dup = makeCase(caseId: 'SYNTH_NAMEDUP', caseName: named.caseName);
      final report = await withCases([...corpus, dup]).validate();
      expect(codesWith(report, 'CORPUS_DUPLICATE_CASE_NAME'), isNotEmpty);
    });

    test('4. alias collision is detected', () async {
      // Reuse the alias of an existing corpus case.
      final withAlias = corpus.firstWhere((c) => c.aliases.isNotEmpty);
      final dup = makeCase(
          caseId: 'SYNTH_ALIASDUP', aliases: [withAlias.aliases.first]);
      final report = await withCases([...corpus, dup]).validate();
      expect(codesWith(report, 'CORPUS_ALIAS_COLLISION'), isNotEmpty);
    });

    test('duplicate objectId is detected', () async {
      final dup = makeCase(
          caseId: 'SYNTH_OBJDUP', objectId: corpus.first.objectId);
      final report = await withCases([...corpus, dup]).validate();
      expect(codesWith(report, 'CORPUS_DUPLICATE_OBJECT_ID'), isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // B. Evidence resolution
  // -------------------------------------------------------------------------

  group('B. evidence resolution', () {
    test('5. broken case evidence ID is detected', () async {
      final broken = makeCase(
          caseId: 'SYNTH_BADEVID', evidenceIds: const ['bogus_evidence']);
      final report = await withCases([...corpus, broken]).validate();
      expect(codesWith(report, 'EVIDENCE_UNRESOLVED'), isNotEmpty);
    });

    test('6. broken intelligence evidence ID is detected', () async {
      final bad = makeCase(
          caseId: 'SYNTH_BADINTEL',
          judgmentIntelligence:
              intelWithEvidence('SYNTH_BADINTEL', 'bogus_intel_evidence'));
      final report = await withCases([...corpus, bad]).validate();
      expect(codesWith(report, 'INTEL_EVIDENCE_UNRESOLVED'), isNotEmpty);
    });

    test('7. intelligence evidence not belonging to the case is detected', () async {
      // Registered evidence, but for a different case (KESAVANANDA's record),
      // so it is not among SYNTH_SUBSET's evidence IDs.
      final bad = makeCase(
        caseId: 'SYNTH_SUBSET',
        evidenceIds: [CaseOfficialSources.evidenceIdFor('SYNTH_SUBSET')],
        judgmentIntelligence:
            intelWithEvidence('SYNTH_SUBSET', CaseOfficialSources.evidenceIdFor('KESAVANANDA')),
      );
      final report = await withCases([...corpus, bad]).validate();
      expect(codesWith(report, 'INTEL_EVIDENCE_NOT_IN_CASE'), isNotEmpty);
      // ...while a legitimate cross-reference must NOT fire the check.
      final good = makeCase(
        caseId: 'SYNTH_GOOD',
        judgmentIntelligence:
            intelWithEvidence('SYNTH_GOOD', CaseOfficialSources.evidenceIdFor('SYNTH_GOOD')),
      );
      final reportGood = await withCases([...corpus, good]).validate();
      expect(codesWith(reportGood, 'INTEL_EVIDENCE_NOT_IN_CASE'), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // C. Constitutional references
  // -------------------------------------------------------------------------

  group('C. constitutional references', () {
    test('8. broken article reference is detected', () async {
      final broken = makeCase(caseId: 'SYNTH_BADART', relatedArticles: const ['Article 999']);
      final report = await withCases([...corpus, broken]).validate();
      expect(codesWith(report, 'ARTICLE_RANGE'), isNotEmpty);
    });

    test('malformed article reference is detected', () async {
      final broken =
          makeCase(caseId: 'SYNTH_BADARTFMT', relatedArticles: const ['Article @@']);
      final report = await withCases([...corpus, broken]).validate();
      expect(codesWith(report, 'ARTICLE_FORMAT'), isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // D. Act references
  // -------------------------------------------------------------------------

  group('D. act references', () {
    test('9. broken act reference is detected', () async {
      final broken =
          makeCase(caseId: 'SYNTH_BADACT', relatedActs: const ['@@']);
      final report = await withCases([...corpus, broken]).validate();
      expect(codesWith(report, 'ACT_FORMAT'), isNotEmpty);
    });

    test('empty section reference is detected', () async {
      final broken = makeCase(caseId: 'SYNTH_BADSEC', sections: const ['']);
      final report = await withCases([...corpus, broken]).validate();
      expect(codesWith(report, 'SECTION_FORMAT'), isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // E. Doctrine references
  // -------------------------------------------------------------------------

  group('E. doctrine references', () {
    test('10. broken doctrine reference is detected', () async {
      final broken =
          makeCase(caseId: 'SYNTH_BADDOCT', doctrines: const ['NOT_A_DOCTRINE']);
      final report = await withCases([...corpus, broken]).validate();
      expect(codesWith(report, 'DOCTRINE_UNRESOLVED'), isNotEmpty);
    });

    test('all corpus doctrine IDs resolve', () async {
      final report = await CorpusValidator().validate();
      expect(codesWith(report, 'DOCTRINE_UNRESOLVED'), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // F. Precedent relationships
  // -------------------------------------------------------------------------

  group('F. precedent relationships', () {
    test('11. missing precedent target is detected', () async {
      final broken = makeCase(
          caseId: 'SYNTH_MISSTGT', precedentsFollowed: const ['NOT_A_CASE']);
      final report = await withCases([...corpus, broken]).validate();
      expect(codesWith(report, 'PRECEDENT_MISSING_TARGET'), isNotEmpty);
    });

    test('self-reference is detected', () async {
      final broken = makeCase(
          caseId: 'SYNTH_SELFREF', precedentsFollowed: const ['SYNTH_SELFREF']);
      final report = await withCases([...corpus, broken]).validate();
      expect(codesWith(report, 'PRECEDENT_SELF_REFERENCE'), isNotEmpty);
    });

    test('duplicate relationship is detected', () async {
      final broken = makeCase(
        caseId: 'SYNTH_DUPREL',
        precedentsFollowed: const ['MANEKA_GANDHI'],
        precedentRelationships: const [
          PrecedentRelationship(
            sourceCaseId: 'SYNTH_DUPREL',
            targetCaseId: 'MANEKA_GANDHI',
            type: PrecedentRelationshipType.followed,
          ),
        ],
      );
      final report = await withCases([...corpus, broken]).validate();
      expect(codesWith(report, 'PRECEDENT_DUPLICATE'), isNotEmpty);
    });

    test('12. contradictory follow + distinguish is detected', () async {
      final broken = makeCase(
        caseId: 'SYNTH_CONTRADICT',
        precedentsFollowed: const ['MANEKA_GANDHI'],
        precedentsDistinguished: const ['MANEKA_GANDHI'],
      );
      final report = await withCases([...corpus, broken]).validate();
      expect(codesWith(report, 'PRECEDENT_CONTRADICTION'), isNotEmpty);
    });

    test('mutual overrule is detected', () async {
      final a = makeCase(caseId: 'SYNTH_OVER_A', year: 2001,
          citation: 'AIR 2025 SC 1001', precedentsOverruled: const ['SYNTH_OVER_B']);
      final b = makeCase(caseId: 'SYNTH_OVER_B', year: 2001,
          citation: 'AIR 2025 SC 1002', precedentsOverruled: const ['SYNTH_OVER_A']);
      final report = await withCases([...corpus, a, b]).validate();
      expect(codesWith(report, 'PRECEDENT_MUTUAL_OVERRULE'), isNotEmpty);
    });

    test('13. temporal precedent paradox is detected', () async {
      // 1950 case cannot overrule 1973 KESAVANANDA.
      final broken = makeCase(
          caseId: 'SYNTH_PARADOX', year: 1950, precedentsOverruled: const ['KESAVANANDA']);
      final report = await withCases([...corpus, broken]).validate();
      expect(codesWith(report, 'PRECEDENT_TEMPORAL_PARADOX'), isNotEmpty);
    });

    test('real corpus carries no precedent anomalies', () async {
      final report = await CorpusValidator().validate();
      final anomalyCodes = {
        'PRECEDENT_MISSING_TARGET',
        'PRECEDENT_SELF_REFERENCE',
        'PRECEDENT_DUPLICATE',
        'PRECEDENT_CONTRADICTION',
        'PRECEDENT_MUTUAL_OVERRULE',
        'PRECEDENT_TEMPORAL_PARADOX',
      };
      expect(report.issues.where((i) => anomalyCodes.contains(i.code)), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // G. Graph ↔ corpus consistency
  // -------------------------------------------------------------------------

  group('G. graph ↔ corpus consistency', () {
    LegalGraphSeed seed() => LegalGraphSeed.fromCorpora(
        cases: corpus, doctrines: DoctrineSeedData.doctrines);

    test('14. missing graph edge is detected', () async {
      final canonical = seed().build();
      final removed = canonical.edges.first.tripleKey;
      final trimmed = LegalGraph(
        nodes: canonical.nodes,
        edges: canonical.edges
            .where((e) => e.tripleKey != removed)
            .toList(),
      );
      final report = await CorpusValidator(graph: trimmed).validate();
      expect(codesWith(report, 'GRAPH_MISSING_EDGE'), isNotEmpty);
    });

    test('15. fabricated graph edge is detected', () async {
      final canonical = seed().build();
      final fabricated = PrecedentGraphEdge(
        sourceId: 'MANEKA_GANDHI',
        targetId: 'AK_GOPALAN',
        type: PrecedentRelationshipType.related,
        evidenceIds: [CaseOfficialSources.evidenceIdFor('MANEKA_GANDHI')],
        provenance: 'corpus:relatedCases',
        verified: true,
      );
      final tampered = LegalGraph(
        nodes: canonical.nodes,
        edges: [...canonical.edges, fabricated],
      );
      final report = await CorpusValidator(graph: tampered).validate();
      expect(codesWith(report, 'GRAPH_FABRICATED_EDGE'), isNotEmpty);
    });

    test('16. missing graph edge (reverse projection) is detected', () async {
      // Removing a doctrine edge is also caught as a missing edge.
      final canonical = seed().build();
      final trimmed = LegalGraph(
        nodes: canonical.nodes,
        edges: canonical.edges
            .where((e) => !(e.isCaseDoctrineEdge &&
                e.sourceId == 'KESAVANANDA' &&
                e.targetId == 'BASIC_STRUCTURE'))
            .toList(),
      );
      final report = await CorpusValidator(graph: trimmed).validate();
      expect(codesWith(report, 'GRAPH_MISSING_EDGE'), isNotEmpty);
    });

    test('17. doctrine relationship mismatch is detected', () async {
      final canonical = seed().build();
      final changed = canonical.edges.map((e) {
        if (e is DoctrineGraphEdge &&
            e.sourceId == 'KESAVANANDA' &&
            e.targetId == 'BASIC_STRUCTURE') {
          return DoctrineGraphEdge(
            sourceId: e.sourceId,
            targetId: e.targetId,
            type: DoctrineRelationshipType.follows, // record says establishes
            evidenceIds: e.evidenceIds,
            provenance: e.provenance,
            verified: e.verified,
          );
        }
        return e;
      }).toList();
      final tampered = LegalGraph(nodes: canonical.nodes, edges: changed);
      final report = await CorpusValidator(graph: tampered).validate();
      expect(codesWith(report, 'GRAPH_DOCTRINE_ROLE_MISMATCH'), isNotEmpty);
    });

    test('18. canonical graph is a deterministic projection of the corpus', () async {
      final a = await CorpusValidator().validate();
      final b = await CorpusValidator(graph: seed().build()).validate();
      expect(a.graphConsistent, isTrue);
      expect(b.graphConsistent, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // H. Serialization
  // -------------------------------------------------------------------------

  group('H. serialization', () {
    test('18. serialization round-trip is lossless for the corpus', () async {
      final report = await CorpusValidator().validate();
      expect(report.serializationLossless, isTrue);
      expect(codesWith(report, 'SERIALIZATION_MISMATCH'), isEmpty);
    });

    test('serialization is lossless for an injected case too', () async {
      final injected = makeCase(caseId: 'SYNTH_SER', year: 2024);
      final report = await withCases([...corpus, injected]).validate();
      expect(report.serializationLossless, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // 19. Determinism
  // -------------------------------------------------------------------------

  group('19. determinism', () {
    test('full corpus validation is deterministic across runs', () async {
      final a = await CorpusValidator().validate();
      final b = await CorpusValidator().validate();
      String key(CorpusValidationReport r) =>
          r.issues.map((i) => '${i.code}|${i.subject}|${i.message}').join('\n');
      expect(key(a), key(b));
      expect(a.errorCount, b.errorCount);
      expect(a.warningCount, b.warningCount);
      expect(a.infoCount, b.infoCount);
    });

    test('injected-defect validation is deterministic', () async {
      final broken = makeCase(
          caseId: 'SYNTH_DET', evidenceIds: const ['bogus_det']);
      final a = await withCases([...corpus, broken]).validate();
      final b = await withCases([...corpus, broken]).validate();
      expect(a.issues.map((i) => '${i.code}|${i.subject}'),
          orderedEquals(b.issues.map((i) => '${i.code}|${i.subject}')));
      expect(a.isValid, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Cross-cutting: no fabricated findings
  // -------------------------------------------------------------------------

  group('cross-cutting honesty', () {
    test('validation never flags out-of-corpus scope as an error', () async {
      final report = await CorpusValidator().validate();
      // Only ERROR severity fails; INFO/WARNING document boundaries.
      expect(report.errorCount, 0);
      for (final i in report.issues) {
        if (i.category == CorpusValidationCategory.graph ||
            i.category == CorpusValidationCategory.evidence) {
          expect(i.isError, isFalse);
        }
      }
    });

    test('broken-reference counter counts only unresolved errors', () async {
      final broken = makeCase(
          caseId: 'SYNTH_REF',
          relatedArticles: const ['Article 999'],
          relatedActs: const ['@@'],
          doctrines: const ['NOT_A_DOCTRINE'],
          precedentsFollowed: const ['NOT_A_CASE']);
      final report = await withCases([...corpus, broken]).validate();
      expect(report.brokenReferenceCount, greaterThan(0));
      expect(codesWith(report, 'ARTICLE_RANGE'), isNotEmpty);
      expect(codesWith(report, 'ACT_FORMAT'), isNotEmpty);
      expect(codesWith(report, 'DOCTRINE_UNRESOLVED'), isNotEmpty);
      expect(codesWith(report, 'PRECEDENT_MISSING_TARGET'), isNotEmpty);
    });
  });
}
