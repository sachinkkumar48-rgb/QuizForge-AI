/// Corpus-level validation orchestration (TITAN-KO-015.0 P7).
///
/// A VALIDATION AND INTEGRITY sprint: this layer orchestrates the existing
/// P3/P4/P5 validators and adds the corpus-level checks that per-record
/// validation cannot express — identity across the whole corpus, evidence and
/// intelligence-evidence resolution, constitutional/act/doctrine reference
/// resolution, precedent-relationship anomalies, graph↔corpus projection
/// equality, and serialization losslessness.
///
/// It deliberately does NOT rebuild the corpus, the graph, or the search
/// engine, and it never fabricates relationships or evidence to satisfy a
/// check. Cross-package resolution reuses the existing GARUDA seeds
/// (garuda_constitution, garuda_doctrine, garuda_acts); references that fall
/// outside a seed's partial coverage surface as INFO, never as invented errors.
library;

import 'package:garuda_acts/garuda_acts.dart' show ActKnowledgeObject, Phase1ActsCorpus;
import 'package:garuda_constitution/garuda_constitution.dart' show ConstitutionSeedData;
import 'package:garuda_doctrine/garuda_doctrine.dart' show DoctrineKnowledgeObject, DoctrineSeedData;

import '../data/case_official_sources.dart';
import '../data/case_seed_data.dart';
import '../domain/entities/case_enums.dart' show PrecedentRelationshipType;
import '../domain/entities/case_knowledge_object.dart';
import '../graph/data/legal_graph_seed.dart';
import '../graph/domain/legal_graph.dart';
import '../graph/domain/legal_graph_edge.dart';
import '../graph/validation/legal_graph_validator.dart';
import '../intelligence/domain/judgment_intelligence.dart';
import '../intelligence/validation/judgment_intelligence_validator.dart';
import '../repositories/case_repository.dart';
import '../repositories/in_memory_case_repository.dart';
import '../search/data/case_search_normalizer.dart';
import '../validators/case_validator.dart';
import 'corpus_validation_models.dart';

/// Orchestrates existing validators plus corpus-level integrity checks over the
/// full landmark corpus. Values are injected at construction (defaulting to the
/// canonical GARUDA seeds) so adversarial tests can inject tampered corpora.
class CorpusValidator {
  final List<CaseKnowledgeObject> cases;
  final List<DoctrineKnowledgeObject> doctrines;
  final List<ActKnowledgeObject> acts;

  /// Optional graph to validate against. When null the canonical graph is
  /// derived deterministically from [cases] + [doctrines] and validated.
  final LegalGraph? graph;

  CorpusValidator({
    List<CaseKnowledgeObject>? cases,
    List<DoctrineKnowledgeObject>? doctrines,
    List<ActKnowledgeObject>? acts,
    this.graph,
  })  : cases = cases ?? CaseSeedData.cases,
        doctrines = doctrines ?? DoctrineSeedData.doctrines,
        acts = acts ?? Phase1ActsCorpus.phase1Acts;

  /// The graph under validation (canonical derivation when none injected).
  LegalGraph get effectiveGraph =>
      graph ?? LegalGraphSeed.fromCorpora(cases: cases, doctrines: doctrines).build();

  /// Runs the full corpus validation and returns a machine-readable report.
  Future<CorpusValidationReport> validate({CaseRepository? repository}) async {
    final issues = <CorpusValidationIssue>[];

    // Reuse the existing P3 per-repository validator (identity, citations,
    // metadata, evidence presence for approved records).
    final caseResult = await CaseValidator.validateRepository(
        repository ?? InMemoryCaseRepository(cases: cases));
    for (final e in caseResult.errors) {
      issues.add(_mapCaseError(e));
    }

    // Reuse the existing P4 evidence-gated intelligence validator.
    final intelResult = JudgmentIntelligenceValidator.validateRepository(cases);
    for (final i in intelResult.issues) {
      issues.add(CorpusValidationIssue(
        code: 'INTEL_${i.code}',
        message: i.message,
        subject: i.caseId,
        severity: i.severity == IntelligenceIssueSeverity.warning
            ? CorpusValidationSeverity.warning
            : CorpusValidationSeverity.error,
        category: CorpusValidationCategory.intelligence,
      ));
    }

    // Corpus-level checks that per-record validation cannot express.
    _checkIdentity(issues);
    _checkEvidenceResolution(issues);
    _checkArticles(issues);
    _checkActs(issues);
    _checkDoctrines(issues);
    _checkPrecedents(issues);
    final graphConsistent = _checkGraph(issues);
    final serializationLossless = _checkSerialization(issues);

    final result = CorpusValidationResult(
      isValid: issues.where((i) => i.isError).isEmpty,
      issues: issues,
    );

    return CorpusValidationReport.fromResult(
      result,
      totalCases: cases.length,
      evidenceCoverage: _evidenceCoverage(),
      graphConsistent: graphConsistent,
      serializationLossless: serializationLossless,
    );
  }

  // -------------------------------------------------------------------------
  // A. Corpus identity
  // -------------------------------------------------------------------------

  void _checkIdentity(List<CorpusValidationIssue> issues) {
    final caseIds = <String>{};
    final objectIds = <String>{};
    final names = <String, String>{};
    final aliases = <String, List<String>>{};

    for (final c in cases) {
      if (!caseIds.add(c.caseId)) {
        issues.add(_issue(
          'CORPUS_DUPLICATE_CASE_ID',
          'Duplicate case ID "${c.caseId}" across the corpus.',
          c.caseId,
          CorpusValidationSeverity.error,
          CorpusValidationCategory.identity,
        ));
      }
      if (!objectIds.add(c.objectId)) {
        issues.add(_issue(
          'CORPUS_DUPLICATE_OBJECT_ID',
          'Duplicate objectId "${c.objectId}" across the corpus.',
          c.caseId,
          CorpusValidationSeverity.error,
          CorpusValidationCategory.identity,
        ));
      }

      final nameKey = CaseSearchNormalizer.normalizeText(c.caseName);
      if (nameKey.isNotEmpty) {
        final owner = names[nameKey];
        if (owner != null) {
          issues.add(_issue(
            'CORPUS_DUPLICATE_CASE_NAME',
            'Canonical case name "$nameKey" is shared by $owner and ${c.caseId}.',
            c.caseId,
            CorpusValidationSeverity.warning,
            CorpusValidationCategory.identity,
          ));
        } else {
          names[nameKey] = c.caseId;
        }
      }

      for (final a in c.aliases) {
        final aliasKey = CaseSearchNormalizer.normalizeText(a);
        if (aliasKey.isEmpty) continue;
        (aliases[aliasKey] ??= []).add(c.caseId);
      }
    }

    for (final entry in aliases.entries) {
      if (entry.value.length > 1) {
        issues.add(_issue(
          'CORPUS_ALIAS_COLLISION',
          'Alias "${entry.key}" is shared by ${entry.value.join(', ')}.',
          entry.value.join(','),
          CorpusValidationSeverity.warning,
          CorpusValidationCategory.identity,
        ));
      }
    }
  }

  // -------------------------------------------------------------------------
  // B. Evidence resolution (case + intelligence)
  // -------------------------------------------------------------------------

  void _checkEvidenceResolution(List<CorpusValidationIssue> issues) {
    for (final c in cases) {
      if (c.evidenceIds.isEmpty) {
        issues.add(_issue(
          'EVIDENCE_MISSING',
          'Case record carries no evidence IDs.',
          c.caseId,
          CorpusValidationSeverity.error,
          CorpusValidationCategory.evidence,
        ));
      } else {
        for (final eid in c.evidenceIds) {
          if (!CaseOfficialSources.isRegisteredEvidence(eid)) {
            issues.add(_issue(
              'EVIDENCE_UNRESOLVED',
              'Evidence ID "$eid" does not resolve against the official source registry.',
              c.caseId,
              CorpusValidationSeverity.error,
              CorpusValidationCategory.evidence,
            ));
          }
        }
      }

      if (c.officialSource.trim().isEmpty) {
        issues.add(_issue(
          'EVIDENCE_OFFICIAL_SOURCE_MISSING',
          'Case record has no officialSource.',
          c.caseId,
          CorpusValidationSeverity.error,
          CorpusValidationCategory.evidence,
        ));
      }

      final intel = c.judgmentIntelligence;
      if (intel != null) {
        final caseEvidence = c.evidenceIds.toSet();
        for (final eid in _intelligenceEvidenceIds(intel)) {
          if (eid.trim().isEmpty) continue; // handled by the P4 validator
          if (!caseEvidence.contains(eid)) {
            issues.add(_issue(
              'INTEL_EVIDENCE_NOT_IN_CASE',
              'Intelligence evidence "$eid" is not among the case evidence IDs.',
              '${c.caseId}:$eid',
              CorpusValidationSeverity.error,
              CorpusValidationCategory.intelligence,
            ));
          }
          if (!CaseOfficialSources.isRegisteredEvidence(eid) &&
              !LegalGraphSeed.isRegisteredEvidence(eid)) {
            issues.add(_issue(
              'INTEL_EVIDENCE_UNRESOLVED',
              'Intelligence evidence "$eid" does not resolve against any registry.',
              '${c.caseId}:$eid',
              CorpusValidationSeverity.error,
              CorpusValidationCategory.intelligence,
            ));
          }
        }
      }
    }
  }

  /// Evidence IDs referenced by a case's Judgment Intelligence components
  /// (mirrors the P4 validator's component list; no new evidence database).
  static List<String> _intelligenceEvidenceIds(JudgmentIntelligence intel) {
    final ids = <String>[];
    if (intel.bench != null) {
      ids.add(intel.bench!.evidence.evidenceId);
    }
    for (final h in intel.holdings) {
      ids.add(h.evidence.evidenceId);
    }
    for (final r in intel.ratios) {
      ids.add(r.evidence.evidenceId);
    }
    if (intel.reasoning != null) {
      ids.add(intel.reasoning!.evidence.evidenceId);
    }
    if (intel.outcome != null) {
      ids.add(intel.outcome!.evidence.evidenceId);
    }
    for (final t in intel.timeline) {
      ids.add(t.evidence.evidenceId);
    }
    return ids;
  }

  double _evidenceCoverage() {
    var verified = 0;
    for (final c in cases) {
      if (c.evidenceIds.isNotEmpty &&
          c.evidenceIds.every(CaseOfficialSources.isRegisteredEvidence)) {
        verified++;
      }
    }
    return cases.isEmpty ? 0.0 : verified / cases.length;
  }

  // -------------------------------------------------------------------------
  // C. Constitutional references
  // -------------------------------------------------------------------------

  late final Set<String> _constitutionArticleKeys = {
    for (final a in ConstitutionSeedData.articles)
      _articleBaseNumber(a.articleNumber),
  };

  void _checkArticles(List<CorpusValidationIssue> issues) {
    for (final c in cases) {
      for (final ref in c.relatedArticles) {
        final base = _articleBaseNumber(ref);
        if (base.isEmpty || !RegExp(r'\d').hasMatch(base)) {
          issues.add(_issue(
            'ARTICLE_FORMAT',
            'Malformed article reference "$ref".',
            '${c.caseId}:$ref',
            CorpusValidationSeverity.error,
            CorpusValidationCategory.article,
          ));
          continue;
        }
        final digits = int.tryParse(base.replaceAll(RegExp(r'[^0-9]'), ''));
        if (digits != null && digits > 395) {
          issues.add(_issue(
            'ARTICLE_RANGE',
            'Article "$ref" is outside the constitutional range (1–395).',
            '${c.caseId}:$ref',
            CorpusValidationSeverity.error,
            CorpusValidationCategory.article,
          ));
          continue;
        }
        if (!_constitutionArticleKeys.contains(base)) {
          issues.add(_issue(
            'ARTICLE_UNRESOLVED',
            'Article "$ref" (base "$base") is not present in the seeded '
                'constitution corpus (partial coverage).',
            '${c.caseId}:$ref',
            CorpusValidationSeverity.info,
            CorpusValidationCategory.article,
          ));
        }
      }
    }
  }

  /// Extracts the base article number of a reference, ignoring clause forms:
  /// `Article 19(1)(a)` → `19`, `Article 323B` → `323b`, `Article 43A` → `43a`.
  static String _articleBaseNumber(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceFirst(RegExp(r'^(article|art\.?)\s*'), '');
    s = s.split('(').first;
    s = s.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return s;
  }

  // -------------------------------------------------------------------------
  // D. Act references
  // -------------------------------------------------------------------------

  late final Set<String> _actKeys = <String>{
    for (final a in acts)
      ...<String>[
        CaseSearchNormalizer.normalizeText(a.metadata.officialName),
        CaseSearchNormalizer.normalizeText(a.metadata.shortTitle),
      ],
  };

  void _checkActs(List<CorpusValidationIssue> issues) {
    for (final c in cases) {
      for (final ref in c.relatedActs) {
        final norm = CaseSearchNormalizer.normalizeText(ref);
        if (norm.isEmpty || !RegExp(r'[a-z]').hasMatch(norm)) {
          issues.add(_issue(
            'ACT_FORMAT',
            'Malformed act reference "$ref".',
            '${c.caseId}:$ref',
            CorpusValidationSeverity.error,
            CorpusValidationCategory.act,
          ));
          continue;
        }
        final resolved = _actKeys.any((k) => k == norm || k.contains(norm));
        if (!resolved) {
          issues.add(_issue(
            'ACT_UNRESOLVED',
            'Act "$ref" is not present in the seeded acts corpus '
                '(Phase-I acts coverage is partial).',
            '${c.caseId}:$ref',
            CorpusValidationSeverity.info,
            CorpusValidationCategory.act,
          ));
        }
      }

      for (final ref in c.sections) {
        final norm = CaseSearchNormalizer.normalizeText(ref);
        if (norm.isEmpty) {
          issues.add(_issue(
            'SECTION_FORMAT',
            'Empty section reference.',
            '${c.caseId}:$ref',
            CorpusValidationSeverity.error,
            CorpusValidationCategory.act,
          ));
        } else if (!RegExp(r'\d').hasMatch(norm)) {
          issues.add(_issue(
            'SECTION_FORMAT',
            'Section reference "$ref" carries no section number.',
            '${c.caseId}:$ref',
            CorpusValidationSeverity.warning,
            CorpusValidationCategory.act,
          ));
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // E. Doctrine references
  // -------------------------------------------------------------------------

  void _checkDoctrines(List<CorpusValidationIssue> issues) {
    final doctrineIds = {for (final d in doctrines) d.doctrineId.toUpperCase()};
    for (final c in cases) {
      for (final d in c.doctrines) {
        if (!doctrineIds.contains(d.toUpperCase())) {
          issues.add(_issue(
            'DOCTRINE_UNRESOLVED',
            'Doctrine ID "$d" does not resolve in garuda_doctrine.',
            '${c.caseId}:$d',
            CorpusValidationSeverity.error,
            CorpusValidationCategory.doctrine,
          ));
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // F. Precedent relationships
  // -------------------------------------------------------------------------

  void _checkPrecedents(List<CorpusValidationIssue> issues) {
    final ids = {for (final c in cases) c.caseId};
    final yearById = {for (final c in cases) c.caseId: c.year};

    final seen = <String>{};
    final outbound = <String, List<(String, PrecedentRelationshipType)>>{};
    final reverse = <String, List<(String, PrecedentRelationshipType)>>{};

    void consider(String sourceId, String targetId, PrecedentRelationshipType type) {
      if (!ids.contains(sourceId)) return;
      if (!ids.contains(targetId)) {
        issues.add(_issue(
          'PRECEDENT_MISSING_TARGET',
          'Relationship $type references unknown target "$targetId".',
          '$sourceId→$targetId',
          CorpusValidationSeverity.error,
          CorpusValidationCategory.precedent,
        ));
        return;
      }
      if (sourceId == targetId) {
        issues.add(_issue(
          'PRECEDENT_SELF_REFERENCE',
          'Self-referential relationship ($sourceId $type $targetId).',
          '$sourceId→$targetId',
          CorpusValidationSeverity.error,
          CorpusValidationCategory.precedent,
        ));
        return;
      }
      final key = '$sourceId|${type.name}|$targetId';
      if (!seen.add(key)) {
        issues.add(_issue(
          'PRECEDENT_DUPLICATE',
          'Duplicate relationship ($sourceId $type $targetId).',
          key,
          CorpusValidationSeverity.error,
          CorpusValidationCategory.precedent,
        ));
      }
      (outbound[sourceId] ??= []).add((targetId, type));
      (reverse[targetId] ??= []).add((sourceId, type));
    }

    for (final c in cases) {
      for (final t in c.precedentsFollowed) {
        consider(c.caseId, t, PrecedentRelationshipType.followed);
      }
      for (final t in c.precedentsOverruled) {
        consider(c.caseId, t, PrecedentRelationshipType.overruled);
      }
      for (final t in c.precedentsDistinguished) {
        consider(c.caseId, t, PrecedentRelationshipType.distinguished);
      }
      for (final t in c.relatedCases) {
        consider(c.caseId, t, PrecedentRelationshipType.related);
      }
      for (final r in c.precedentRelationships) {
        consider(r.sourceCaseId, r.targetCaseId, r.type);
      }
    }

    for (final entry in outbound.entries) {
      final sourceId = entry.key;
      final targets = entry.value;
      for (final (targetId, type) in targets) {
        // A follows B AND A distinguishes B.
        if (type == PrecedentRelationshipType.followed &&
            targets.any((x) =>
                x.$1 == targetId &&
                x.$2 == PrecedentRelationshipType.distinguished)) {
          issues.add(_issue(
            'PRECEDENT_CONTRADICTION',
            '$sourceId both follows and distinguishes $targetId.',
            '$sourceId→$targetId',
            CorpusValidationSeverity.error,
            CorpusValidationCategory.precedent,
          ));
        }
        // A overrules B AND B overrules A.
        if (type == PrecedentRelationshipType.overruled &&
            (reverse[sourceId] ?? const [])
                .any((x) => x.$1 == targetId && x.$2 == PrecedentRelationshipType.overruled)) {
          issues.add(_issue(
            'PRECEDENT_MUTUAL_OVERRULE',
            '$sourceId overrules $targetId and $targetId overrules $sourceId.',
            '$sourceId↔$targetId',
            CorpusValidationSeverity.error,
            CorpusValidationCategory.precedent,
          ));
        }
        // A case cannot overrule a later-decided case.
        if (type == PrecedentRelationshipType.overruled) {
          final sy = yearById[sourceId];
          final ty = yearById[targetId];
          if (sy != null && ty != null && sy < ty) {
            issues.add(_issue(
              'PRECEDENT_TEMPORAL_PARADOX',
              '$sourceId ($sy) cannot overrule $targetId ($ty), which was decided later.',
              '$sourceId→$targetId',
              CorpusValidationSeverity.error,
              CorpusValidationCategory.precedent,
            ));
          }
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // G. Graph ↔ corpus consistency
  // -------------------------------------------------------------------------

  bool _checkGraph(List<CorpusValidationIssue> issues) {
    final derived =
        LegalGraphSeed.fromCorpora(cases: cases, doctrines: doctrines).build();
    final target = effectiveGraph;

    final expectedTriples = {for (final e in derived.edges) e.tripleKey};
    final actualTriples = {for (final e in target.edges) e.tripleKey};

    for (final t in actualTriples.difference(expectedTriples)) {
      issues.add(_issue(
        'GRAPH_FABRICATED_EDGE',
        'Graph edge "$t" is not derivable from the corpus.',
        t,
        CorpusValidationSeverity.error,
        CorpusValidationCategory.graph,
      ));
    }
    for (final t in expectedTriples.difference(actualTriples)) {
      issues.add(_issue(
        'GRAPH_MISSING_EDGE',
        'Corpus relationship "$t" is absent from the graph.',
        t,
        CorpusValidationSeverity.error,
        CorpusValidationCategory.graph,
      ));
    }

    // Case → doctrine role consistency against the doctrine records.
    final roles =
        LegalGraphSeed.doctrineRecordRoles(cases: cases, doctrines: doctrines);
    for (final e in target.edges.whereType<DoctrineGraphEdge>()) {
      final expectedRole = roles['${e.sourceId}|${e.targetId}']?.$1;
      if (expectedRole != null && e.type != expectedRole) {
        issues.add(_issue(
          'GRAPH_DOCTRINE_ROLE_MISMATCH',
          'Doctrine edge "$e" role ${e.type.name} differs from record role '
              '${expectedRole.name}.',
          e.tripleKey,
          CorpusValidationSeverity.error,
          CorpusValidationCategory.graph,
        ));
      }
    }

    // Orphan case nodes (no edges at all). If the corpus intentionally carries
    // no relationships for a case, report it rather than inventing an edge.
    final connected = <String>{};
    for (final e in target.edges) {
      connected.add(e.sourceId);
      connected.add(e.targetId);
    }
    for (final c in cases) {
      if (!connected.contains(c.caseId)) {
        issues.add(_issue(
          'GRAPH_ISOLATED_CASE',
          'Case "${c.caseId}" has no graph edges (intentionally isolated per corpus).',
          c.caseId,
          CorpusValidationSeverity.info,
          CorpusValidationCategory.graph,
        ));
      }
    }

    // Reuse the existing P5 graph validator.
    final graphResult = LegalGraphValidator.validateGraph(target);
    for (final i in graphResult.errors) {
      issues.add(_issue(
        'GRAPH_${i.code.toUpperCase()}',
        i.message,
        i.subject,
        CorpusValidationSeverity.error,
        CorpusValidationCategory.graph,
      ));
    }
    for (final i in graphResult.warnings) {
      issues.add(_issue(
        'GRAPH_${i.code.toUpperCase()}',
        i.message,
        i.subject,
        CorpusValidationSeverity.warning,
        CorpusValidationCategory.graph,
      ));
    }

    return issues.where((i) =>
            i.category == CorpusValidationCategory.graph && i.isError)
        .isEmpty;
  }

  // -------------------------------------------------------------------------
  // H. Serialization losslessness
  // -------------------------------------------------------------------------

  bool _checkSerialization(List<CorpusValidationIssue> issues) {
    var lossless = true;
    for (final c in cases) {
      try {
        final restored = CaseKnowledgeObject.fromJson(c.toJson());
        if (!_deepEquals(restored.toJson(), c.toJson())) {
          issues.add(_issue(
            'SERIALIZATION_MISMATCH',
            'toJson/fromJson round-trip is not lossless.',
            c.caseId,
            CorpusValidationSeverity.error,
            CorpusValidationCategory.serialization,
          ));
          lossless = false;
        }
      } catch (_) {
        issues.add(_issue(
          'SERIALIZATION_ERROR',
          'Serialization round-trip threw.',
          c.caseId,
          CorpusValidationSeverity.error,
          CorpusValidationCategory.serialization,
        ));
        lossless = false;
      }
    }
    return lossless;
  }

  static bool _deepEquals(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final entry in a.entries) {
        if (!b.containsKey(entry.key)) return false;
        if (!_deepEquals(entry.value, b[entry.key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static CorpusValidationIssue _issue(
    String code,
    String message,
    String subject,
    CorpusValidationSeverity severity,
    CorpusValidationCategory category,
  ) =>
      CorpusValidationIssue(
        code: code,
        message: message,
        subject: subject,
        severity: severity,
        category: category,
      );

  static CorpusValidationIssue _mapCaseError(CaseValidationError e) {
    final isIntel = e.code.startsWith('INTEL_');
    final category = isIntel
        ? CorpusValidationCategory.intelligence
        : e.code == 'MISSING_EVIDENCE'
            ? CorpusValidationCategory.evidence
            : CorpusValidationCategory.identity;
    return CorpusValidationIssue(
      code: e.code,
      message: e.message,
      subject: e.caseId,
      severity: CorpusValidationSeverity.error,
      category: category,
    );
  }
}
