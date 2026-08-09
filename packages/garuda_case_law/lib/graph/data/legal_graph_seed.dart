/// Graph derivation for the Precedent & Doctrine Graph (TITAN-KO-015.0 P5).
///
/// THE GRAPH IS BUILT FROM VERIFIED DATA, NOT FROM ASSUMPTIONS. Every node and
/// edge is derived from the 49-case landmark corpus (`CaseSeedData`) or the
/// canonical `garuda_doctrine` records (`DoctrineSeedData`):
///
/// - case → case edges come from the corpus precedent fields
///   (`precedentsFollowed`, `precedentsOverruled`,
///   `precedentsDistinguished`, `relatedCases`) and any structured
///   `precedentRelationships`.
/// - case → doctrine edges come from the case `doctrines` field (role
///   `engages` unless a more specific role is established) and from the
///   authoritative doctrine-record case references (`originatingCase`,
///   `landmarkCases`, `subsequentCases`, `expandedBy`, `limitedBy`,
///   `distinguishedIn`) resolved against the corpus.
///
/// Nothing is invented to increase density: references that do not resolve to a
/// canonical ID are left absent.
library;

import 'package:garuda_doctrine/garuda_doctrine.dart'
    show DoctrineKnowledgeObject, DoctrineSeedData;

import '../../data/case_official_sources.dart';
import '../../domain/entities/case_enums.dart';
import '../../domain/entities/case_knowledge_object.dart';
import '../../data/case_seed_data.dart';
import '../domain/doctrine_relationship_type.dart';
import '../domain/legal_graph.dart';
import '../domain/legal_graph_edge.dart';
import '../domain/legal_graph_node_ref.dart';
import '../domain/legal_graph_node_type.dart';

/// The seed of the legal graph: the set of canonical nodes and the
/// evidence-backed edges that connect them.
class LegalGraphSeed {
  final List<LegalGraphNodeRef> nodes;
  final List<LegalGraphEdge> edges;

  const LegalGraphSeed({required this.nodes, required this.edges});

  /// Builds the aggregated [LegalGraph], de-duplicating edges and dropping
  /// self-loops.
  LegalGraph build() => LegalGraph(nodes: nodes, edges: edges);

  /// Derives the graph from the default corpora.
  static LegalGraphSeed fromCorpus() => fromCorpora(
        cases: CaseSeedData.cases,
        doctrines: DoctrineSeedData.doctrines,
      );

  /// Derives the graph from explicit corpora (used by tests and other
  /// packages). Unresolvable references are dropped, never guessed.
  static LegalGraphSeed fromCorpora({
    required List<CaseKnowledgeObject> cases,
    required List<DoctrineKnowledgeObject> doctrines,
  }) {
    final caseIds = cases.map((c) => c.caseId).toSet();
    final caseNodes = cases
        .map((c) => LegalGraphNodeRef(
              id: c.caseId,
              name: c.caseName,
              nodeType: LegalGraphNodeType.caseLaw,
              attributes: {'year': c.year, 'citation': c.citation},
            ))
        .toList();

    final doctrineNodes = doctrines
        .map((d) => LegalGraphNodeRef(
              id: d.doctrineId,
              name: d.name,
              nodeType: LegalGraphNodeType.doctrine,
              attributes: {'category': d.category.name},
            ))
        .toList();

    final edges = <LegalGraphEdge>[
      ..._caseCaseEdges(cases, caseIds),
      ..._caseDoctrineEdges(cases, doctrines),
    ];

    return LegalGraphSeed(
      nodes: List.unmodifiable([...caseNodes, ...doctrineNodes]),
      edges: List.unmodifiable(edges),
    );
  }

  // -------------------------------------------------------------------------
  // Case → case edges
  // -------------------------------------------------------------------------

  static List<PrecedentGraphEdge> _caseCaseEdges(
    List<CaseKnowledgeObject> cases,
    Set<String> caseIds,
  ) {
    final edges = <PrecedentGraphEdge>[];

    for (final c in cases) {
      final evidence = _caseEvidence(c.caseId);

      for (final target in c.precedentsFollowed) {
        if (caseIds.contains(target)) {
          edges.add(PrecedentGraphEdge(
            sourceId: c.caseId,
            targetId: target,
            type: PrecedentRelationshipType.followed,
            evidenceIds: evidence,
            provenance: 'corpus:precedentsFollowed',
            verified: true,
          ));
        }
      }
      for (final target in c.precedentsOverruled) {
        if (caseIds.contains(target)) {
          edges.add(PrecedentGraphEdge(
            sourceId: c.caseId,
            targetId: target,
            type: PrecedentRelationshipType.overruled,
            evidenceIds: evidence,
            provenance: 'corpus:precedentsOverruled',
            verified: true,
          ));
        }
      }
      for (final target in c.precedentsDistinguished) {
        if (caseIds.contains(target)) {
          edges.add(PrecedentGraphEdge(
            sourceId: c.caseId,
            targetId: target,
            type: PrecedentRelationshipType.distinguished,
            evidenceIds: evidence,
            provenance: 'corpus:precedentsDistinguished',
            verified: true,
          ));
        }
      }
      for (final target in c.relatedCases) {
        if (caseIds.contains(target)) {
          edges.add(PrecedentGraphEdge(
            sourceId: c.caseId,
            targetId: target,
            type: PrecedentRelationshipType.related,
            evidenceIds: evidence,
            provenance: 'corpus:relatedCases',
            verified: true,
          ));
        }
      }
      for (final r in c.precedentRelationships) {
        final target = r.targetCaseId;
        if (caseIds.contains(target)) {
          edges.add(PrecedentGraphEdge(
            sourceId: r.sourceCaseId,
            targetId: target,
            type: r.type,
            evidenceIds: evidence,
            provenance: 'corpus:precedentRelationships',
            verified: true,
            note: r.note,
          ));
        }
      }
    }
    return edges;
  }

  // -------------------------------------------------------------------------
  // Case → doctrine edges
  // -------------------------------------------------------------------------

  static List<DoctrineGraphEdge> _caseDoctrineEdges(
    List<CaseKnowledgeObject> cases,
    List<DoctrineKnowledgeObject> doctrines,
  ) {
    final roleByPair = doctrineRecordRoles(cases: cases, doctrines: doctrines);

    final edges = <DoctrineGraphEdge>[];
    final covered = <String>{};

    // Case-record doctrine engagements (curated corpus evidence).
    for (final c in cases) {
      for (final did in c.doctrines) {
        final key = '${c.caseId}|$did';
        covered.add(key);
        final role = roleByPair[key];
        edges.add(DoctrineGraphEdge(
          sourceId: c.caseId,
          targetId: did,
          type: role?.$1 ?? DoctrineRelationshipType.engages,
          evidenceIds: _doctrineEvidence(c.caseId, did),
          provenance: role?.$2 ?? 'corpus:doctrines',
          verified: true,
        ));
      }
    }

    // Doctrine-record roles for cases not linked by their own `doctrines` field.
    for (final entry in roleByPair.entries) {
      if (covered.contains(entry.key)) continue;
      final split = entry.key.split('|');
      edges.add(DoctrineGraphEdge(
        sourceId: split[0],
        targetId: split[1],
        type: entry.value.$1,
        evidenceIds: _doctrineEvidence(split[0], split[1]),
        provenance: entry.value.$2,
        verified: true,
      ));
    }

    return edges;
  }

  /// Roles established by the authoritative doctrine records, keyed by
  /// `'$caseId|$doctrineId'`, with the field provenance.
  ///
  /// Precedence: the most specific evidenced role wins (establishes > expands >
  /// limits > distinguishes > applies > follows). Exposed for integrity tests
  /// so the derived doctrine edges can be independently reconstructed.
  static Map<String, (DoctrineRelationshipType, String)> doctrineRecordRoles({
    required List<CaseKnowledgeObject> cases,
    required List<DoctrineKnowledgeObject> doctrines,
  }) {
    final resolver = DoctrineCaseNameResolver(cases);
    final roleByPair = <String, (DoctrineRelationshipType, String)>{};
    for (final d in doctrines) {
      void addRole(String ref, DoctrineRelationshipType type, String field) {
        final cid = resolver.resolveToCaseId(ref);
        if (cid == null) return;
        final key = '$cid|${d.doctrineId}';
        final existing = roleByPair[key];
        if (existing == null || type.specificity > existing.$1.specificity) {
          roleByPair[key] = (type, 'doctrine:${d.doctrineId}.$field');
        }
      }

      addRole(d.originatingCase, DoctrineRelationshipType.establishes,
          'originatingCase');
      for (final ref in d.expandedBy) {
        addRole(ref, DoctrineRelationshipType.expands, 'expandedBy');
      }
      for (final ref in d.limitedBy) {
        addRole(ref, DoctrineRelationshipType.limits, 'limitedBy');
      }
      for (final ref in d.distinguishedIn) {
        addRole(ref, DoctrineRelationshipType.distinguishes, 'distinguishedIn');
      }
      for (final ref in d.landmarkCases) {
        addRole(ref, DoctrineRelationshipType.applies, 'landmarkCases');
      }
      for (final ref in d.subsequentCases) {
        addRole(ref, DoctrineRelationshipType.follows, 'subsequentCases');
      }
    }
    return Map.unmodifiable(roleByPair);
  }

  // -------------------------------------------------------------------------
  // Evidence
  // -------------------------------------------------------------------------

  /// Registered evidence for a case: the official judgment record.
  static List<String> _caseEvidence(String caseId) =>
      [CaseOfficialSources.evidenceIdFor(caseId)];

  /// Evidence for a case→doctrine edge: the official case record plus the
  /// canonical doctrine record reference.
  static List<String> _doctrineEvidence(String caseId, String doctrineId) =>
      [CaseOfficialSources.evidenceIdFor(caseId), 'doctrine:$doctrineId'];

  /// Whether an evidence reference is registered with the graph's evidence
  /// registry (official case records or canonical doctrine records).
  static bool isRegisteredEvidence(String evidenceId) {
    if (CaseOfficialSources.isRegisteredEvidence(evidenceId)) return true;
    if (evidenceId.startsWith('doctrine:')) {
      final id = evidenceId.substring('doctrine:'.length);
      return DoctrineSeedData.doctrines.any((d) => d.doctrineId == id);
    }
    return false;
  }
}

/// Resolves doctrine-record case references against the 49-case corpus.
///
/// Conservative by construction: a reference only resolves when it matches a
/// corpus case unambiguously (exact normalized name/alias, or an exact
/// petitioner-prefix + respondent match). Ambiguous or unresolvable references
/// return null and the relationship is left absent.
class DoctrineCaseNameResolver {
  late final Map<String, String> _exactName;
  late final Map<String, String> _exactAlias;
  late final Map<String, String> _petitionerExact;
  late final Map<String, (String, String)> _petitionerRespondent;

  DoctrineCaseNameResolver(List<CaseKnowledgeObject> cases) {
    final exactName = <String, String>{};
    final exactAlias = <String, String>{};
    final petToRespondent = <String, (String, String)>{};
    final barePetToId = <String, String>{};
    for (final c in cases) {
      exactName[_norm(c.caseName)] = c.caseId;
      for (final a in c.aliases) {
        exactAlias[_norm(a)] = c.caseId;
      }
      final n = _norm(c.caseName);
      final parts = n.split(' v ');
      if (parts.length >= 2) {
        petToRespondent[parts[0]] = (c.caseId, parts.sublist(1).join(' v '));
      } else {
        barePetToId[n] = c.caseId;
      }
    }
    _exactName = Map.unmodifiable(exactName);
    _exactAlias = Map.unmodifiable(exactAlias);
    _petitionerRespondent = Map.unmodifiable(petToRespondent);
    _petitionerExact = Map.unmodifiable(barePetToId);
  }

  /// Returns the canonical case ID a doctrine reference resolves to, or null
  /// when it cannot be established unambiguously.
  String? resolveToCaseId(String reference) {
    final n = _norm(reference);
    if (n.isEmpty) return null;

    if (_exactName.containsKey(n)) return _exactName[n];
    if (_exactAlias.containsKey(n)) return _exactAlias[n];

    final parts = n.split(' v ');
    if (parts.length >= 2) {
      final petitioner = parts[0];
      final respondent = parts.sublist(1).join(' v ');
      final hit = _petitionerRespondent[petitioner];
      if (hit != null && hit.$2 == respondent) return hit.$1;
      // Petitioner-prefix (e.g. 'K.S. Puttaswamy' within 'Justice K.S.
      // Puttaswamy') only when the respondent matches exactly — prevents
      // 'M.C. Mehta v. Kamal Nath' from resolving to the Taj Trapezium case.
      final prefixHits = <String>[];
      for (final entry in _petitionerRespondent.entries) {
        if (entry.key.startsWith(petitioner) && entry.value.$2 == respondent) {
          prefixHits.add(entry.value.$1);
        }
      }
      return prefixHits.length == 1 ? prefixHits.single : null;
    }

    // Bare party reference (e.g. 'I.R. Coelho (extended ...)').
    final bare = _petitionerExact[n];
    if (bare != null) return bare;
    final bareHits = <String>[
      for (final entry in _petitionerRespondent.entries)
        if (entry.key.startsWith(n)) entry.value.$1,
    ];
    return bareHits.length == 1 ? bareHits.single : null;
  }

  static const Map<String, String> _abbreviations = {
    'uoi': 'union of india',
    'uoia': 'union of india',
    'cit': 'commissioner of income tax',
  };

  /// Normalizes a case reference/name to a comparable token string.
  static String _norm(String s) {
    var t = s.toLowerCase();
    t = t.replaceAll(RegExp(r'\([^)]*\)'), ' '); // strip parentheticals
    t = t.replaceAll(' v. ', ' v ').replaceAll(' vs ', ' v ');
    t = t.replaceAll(RegExp(r'\bversus\b'), ' v ');
    t = t.replaceAll(RegExp(r'\d{4}'), ' '); // drop years
    t = t.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    final tokens = t.trim().split(' ').where((w) => w.isNotEmpty).toList();
    final mapped = tokens
        .map((w) => _abbreviations[w] ?? w)
        .join(' ');
    return mapped;
  }
}
