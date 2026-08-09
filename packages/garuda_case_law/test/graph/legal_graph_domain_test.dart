import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart' show DoctrineSeedData;

/// P5 domain layer: graph construction, node/edge models, de-duplication,
/// self-loop rejection and serialization round-trip (TITAN-KO-015.0 P5).
void main() {
  group('LegalGraph construction', () {
    test('builds 69 nodes from the corpus (49 cases + 20 doctrines)', () {
      final g = LegalGraphSeed.fromCorpus().build();
      expect(g.nodeCount, 69);
      expect(g.caseNodes.length, 49);
      expect(g.doctrineNodes.length, 20);
    });

    test('builds 125 unique edges with no duplicates or self-loops', () {
      final g = LegalGraphSeed.fromCorpus().build();
      expect(g.edgeCount, 125);
      expect(g.duplicateEdgesRejected, 0);
      expect(g.selfLoopsRejected, 0);
    });

    test('node keys are unique across namespaces', () {
      final g = LegalGraphSeed.fromCorpus().build();
      final keys = g.nodes.map((n) => n.nodeKey).toSet();
      expect(keys.length, g.nodeCount);
      expect(g.hasCase('KESAVANANDA'), isTrue);
      expect(g.hasDoctrine('BASIC_STRUCTURE'), isTrue);
      expect(g.hasDoctrine('KESAVANANDA'), isFalse);
      expect(g.hasCase('BASIC_STRUCTURE'), isFalse);
    });

    test('case nodes carry the canonical corpus IDs', () {
      final g = LegalGraphSeed.fromCorpus().build();
      final caseIds = g.caseNodes.map((n) => n.id).toSet();
      final corpusIds = CaseSeedData.cases.map((c) => c.caseId).toSet();
      expect(caseIds, corpusIds);
    });

    test('doctrine nodes carry canonical garuda_doctrine IDs only', () {
      final g = LegalGraphSeed.fromCorpus().build();
      final doctrineIds = g.doctrineNodes.map((n) => n.id).toSet();
      final canonical = DoctrineSeedData.doctrines.map((d) => d.doctrineId).toSet();
      expect(doctrineIds, canonical);
    });
  });

  group('Edge model', () {
    test('edges are typed case-case or case-doctrine', () {
      final g = LegalGraphSeed.fromCorpus().build();
      final caseCase = g.edges.where((e) => e.isCaseCaseEdge).length;
      final caseDoctrine = g.edges.where((e) => e.isCaseDoctrineEdge).length;
      expect(caseCase, 106);
      expect(caseDoctrine, 19);
      expect(caseCase + caseDoctrine, g.edgeCount);
    });

    test('every edge carries evidence, provenance and verification', () {
      final g = LegalGraphSeed.fromCorpus().build();
      for (final e in g.edges) {
        expect(e.evidenceIds, isNotEmpty, reason: e.tripleKey);
        expect(e.provenance, isNotEmpty, reason: e.tripleKey);
        expect(e.confidence, greaterThan(0.0));
        expect(e.confidence, lessThanOrEqualTo(1.0));
        expect(e.verified, isTrue, reason: e.tripleKey);
      }
    });

    test('precedent edges preserve the recorded direction', () {
      final g = LegalGraphSeed.fromCorpus().build();
      // MANEKA_GANDHI overruled AK_GOPALAN (source → target).
      final edges = g.edgesBetween('MANEKA_GANDHI', 'AK_GOPALAN');
      expect(edges, hasLength(1));
      final e = edges.single as PrecedentGraphEdge;
      expect(e.type, PrecedentRelationshipType.overruled);
      expect(e.sourceId, 'MANEKA_GANDHI');
      expect(e.targetId, 'AK_GOPALAN');
    });

    test('hasEdge detects (source, type, target) triples', () {
      final g = LegalGraphSeed.fromCorpus().build();
      expect(g.hasEdge('MINERVA_MILLS', 'followed', 'KESAVANANDA'), isTrue);
      expect(g.hasEdge('KESAVANANDA', 'overruled', 'GOLAKNATH'), isTrue);
      expect(g.hasEdge('MINERVA_MILLS', 'overruled', 'KESAVANANDA'), isFalse);
    });
  });

  group('De-duplication and self-loops', () {
    test('duplicate (source, type, target) edges are rejected at build', () {
      final caseNode = const LegalGraphNodeRef(
          id: 'A', name: 'A', nodeType: LegalGraphNodeType.caseLaw);
      final edge = const PrecedentGraphEdge(
        sourceId: 'A',
        targetId: 'B',
        type: PrecedentRelationshipType.followed,
        provenance: 'corpus:precedentsFollowed',
      );
      final g = LegalGraph(
        nodes: [caseNode, const LegalGraphNodeRef(
            id: 'B', name: 'B', nodeType: LegalGraphNodeType.caseLaw)],
        edges: [edge, edge],
      );
      expect(g.edgeCount, 1);
      expect(g.duplicateEdgesRejected, 1);
    });

    test('self-loops are rejected at build', () {
      final caseNode = const LegalGraphNodeRef(
          id: 'A', name: 'A', nodeType: LegalGraphNodeType.caseLaw);
      final g = LegalGraph(
        nodes: [caseNode],
        edges: [
          const PrecedentGraphEdge(
            sourceId: 'A',
            targetId: 'A',
            type: PrecedentRelationshipType.related,
            provenance: 'corpus:relatedCases',
          ),
        ],
      );
      expect(g.edgeCount, 0);
      expect(g.selfLoopsRejected, 1);
    });

    test('the corpus graph itself rejects no edges', () {
      final g = LegalGraphSeed.fromCorpus().build();
      expect(g.duplicateEdgesRejected, 0);
      expect(g.selfLoopsRejected, 0);
    });
  });

  group('Serialization round-trip', () {
    test('toJson → fromJson preserves nodes and edges', () {
      final original = LegalGraphSeed.fromCorpus().build();
      final restored = LegalGraph.fromJson(original.toJson());

      expect(restored.nodeCount, original.nodeCount);
      expect(restored.edgeCount, original.edgeCount);
      expect(restored.hasCase('KESAVANANDA'), isTrue);
      expect(restored.hasDoctrine('BASIC_STRUCTURE'), isTrue);

      final edges = restored.edges;
      expect(edges.length, original.edges.length);
      for (var i = 0; i < edges.length; i++) {
        final e = edges[i];
        final o = original.edges[i];
        expect(e.tripleKey, o.tripleKey, reason: 'index $i');
        expect(e.evidenceIds, o.evidenceIds);
        expect(e.provenance, o.provenance);
        expect(e.confidence, o.confidence);
        expect(e.verified, o.verified);
      }

      // Concrete types survive the round-trip.
      final doc = restored.edges
          .whereType<DoctrineGraphEdge>()
          .firstWhere((e) => e.sourceId == 'KESAVANANDA');
      expect(doc.type, DoctrineRelationshipType.establishes);
      final prec = restored.edges
          .whereType<PrecedentGraphEdge>()
          .firstWhere((e) => e.tripleKey == 'MINERVA_MILLS|followed|KESAVANANDA');
      expect(prec.type, PrecedentRelationshipType.followed);
    });
  });
}
