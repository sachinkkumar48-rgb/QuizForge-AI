import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P9 — Precedent navigation and citation safety (TITAN-KO-015.0 P9).
///
/// Navigation reads the P5 graph as-is: direct precedent edges, raw
/// incoming/outgoing relationship sets, longest chains, shortest paths and
/// transitive authority ancestors/descendants. P9 never creates graph edges and
/// never reports a precedent relationship as a citation.
void main() {
  final service = CaseDiscoveryService();

  group('A. direct precedent relationships', () {
    test('direct precedents expose the followed edge', () {
      final edges = service.directPrecedents('MINERVA_MILLS');
      expect(edges, hasLength(1));
      expect(edges.single.edgeId, 'e:MINERVA_MILLS|followed|KESAVANANDA');
      expect(edges.single.type, PrecedentRelationshipType.followed);
      expect(edges.single.provenance, 'corpus:precedentsFollowed');
    });

    test('an unknown case yields no direct precedents', () {
      expect(service.directPrecedents('NO_SUCH_CASE'), isEmpty);
    });

    test('relationships between two cases are exposed with their edge ids', () {
      final edges =
          service.relationshipsBetween('MINERVA_MILLS', 'KESAVANANDA');
      final ids = edges.map((e) => e.edgeId).toSet();
      expect(ids, contains('e:MINERVA_MILLS|followed|KESAVANANDA'));
      expect(ids, contains('e:MINERVA_MILLS|related|KESAVANANDA'));
    });

    test('incoming relationships include follow and curated-affinity edges',
        () {
      final edges = service.incomingRelationships('MANEKA_GANDHI');
      final ids = edges.map((e) => e.edgeId).toSet();
      expect(ids, contains('e:DK_BASU|followed|MANEKA_GANDHI'));
      expect(ids, contains('e:HUSSAINARA_KHATOON|followed|MANEKA_GANDHI'));
      expect(ids, contains('e:AK_GOPALAN|related|MANEKA_GANDHI'));
    });

    test('outgoing relationships include overruling edges', () {
      final edges = service.outgoingRelationships('MANEKA_GANDHI');
      final ids = edges.map((e) => e.edgeId).toSet();
      expect(ids, contains('e:MANEKA_GANDHI|overruled|AK_GOPALAN'));
    });
  });

  group('B. ancestor / descendant traversal', () {
    test('ancestors walk authority edges forward transitively', () {
      // MINERVA_MILLS follows KESAVANANDA; nothing MINERVA relies on is itself
      // an authority-reliant chain, so the ancestor set is just KESAVANANDA.
      expect(
          service.ancestors('MINERVA_MILLS').map((n) => n.id), ['KESAVANANDA']);
    });

    test('descendants walk authority edges backward transitively', () {
      final ids = service.descendants('KESAVANANDA').map((n) => n.id).toList();
      expect(ids, ['IR_COELHO', 'L_CHANDRA_KUMAR', 'MINERVA_MILLS']);
    });

    test('ancestors and descendants never include the source case', () {
      for (final id in ['MINERVA_MILLS', 'KESAVANANDA', 'GOLAKNATH']) {
        expect(service.ancestors(id).any((n) => n.id == id), isFalse);
        expect(service.descendants(id).any((n) => n.id == id), isFalse);
      }
    });

    test('a disconnected case has no ancestors or descendants', () {
      expect(service.ancestors('OLGA_TELLIS'), isEmpty);
      expect(service.descendants('OLGA_TELLIS'), isEmpty);
    });

    test('unknown IDs yield empty traversals', () {
      expect(service.ancestors('NO_SUCH_CASE'), isEmpty);
      expect(service.descendants('NO_SUCH_CASE'), isEmpty);
    });
  });

  group('C. chains and path finding', () {
    test('predecessor chain follows the directed precedent chain', () {
      final path = service.predecessorChain('KESAVANANDA');
      expect(path, isNotNull);
      expect(path!.nodeIds, ['KESAVANANDA', 'GOLAKNATH', 'SAJJAN_SINGH']);
    });

    test('successor chain walks backward over reliance edges', () {
      final path = service.successorChain('KESAVANANDA');
      expect(path, isNotNull);
      expect(path!.nodeIds, ['KESAVANANDA', 'IR_COELHO']);
    });

    test('shortest path between two connected cases is found', () {
      final path = service.pathBetween('GOLAKNATH', 'KESAVANANDA');
      expect(path, isNotNull);
      expect(path!.nodeIds, ['GOLAKNATH', 'KESAVANANDA']);
      expect(path.edgeLabels, ['related']);
    });

    test('disconnected cases yield no path', () {
      expect(service.pathBetween('KESAVANANDA', 'MANEKA_GANDHI'), isNull);
    });

    test('unknown or identical endpoints yield no path', () {
      expect(service.pathBetween('NO_SUCH_CASE', 'KESAVANANDA'), isNull);
      expect(service.pathBetween('KESAVANANDA', 'KESAVANANDA'), isNull);
    });

    test('traversal is cycle-safe and deterministic', () {
      // Repeated traversal over a cyclic graph must not hang and must agree.
      final first =
          service.descendants('KESAVANANDA').map((n) => n.id).toList();
      final second =
          service.descendants('KESAVANANDA').map((n) => n.id).toList();
      expect(first, second);
      expect(service.ancestors('KESAVANANDA'), isNotNull);
    });
  });

  group('D. citation safety', () {
    test('the precedent vocabulary contains no citation type', () {
      expect(
        PrecedentRelationshipType.values.any((t) => t.name == 'cites'),
        isFalse,
        reason: 'P9 must never label a relationship as a citation',
      );
    });

    test('precedent edges are never reported as citations', () {
      final edges = service.directPrecedents('MINERVA_MILLS');
      for (final e in edges) {
        expect(e.typeLabel, 'followed');
        expect(e.typeLabel.toLowerCase(), isNot(contains('cites')));
        expect(e.typeLabel.toLowerCase(), isNot(contains('citation')));
      }
      for (final e in service.incomingRelationships('MANEKA_GANDHI')) {
        expect(e.typeLabel.toLowerCase(), isNot(contains('cites')));
        expect(e.typeLabel.toLowerCase(), isNot(contains('citation')));
      }
    });

    test('no discovery reason is ever a citation claim', () {
      final results = service.discoverRelatedCases('MINERVA_MILLS');
      for (final r in results) {
        for (final reason in r.reasons) {
          expect(reason.label.toLowerCase(), isNot(contains('cites')));
          expect(reason.label.toLowerCase(), isNot(contains('citation')));
        }
      }
      // The strongest structural guarantee: there is no citation reason type.
      expect(DiscoveryReasonType.values.map((t) => t.name),
          isNot(contains('citation')));
    });

    test('the corpus citation strings are reporter citations, not edges', () {
      // CaseKnowledgeObject.citations holds reporter references (AIR/SCC/SCR),
      // which P9 must never reinterpret as "cases that cited X".
      final kes = service.cases.firstWhere((c) => c.caseId == 'KESAVANANDA');
      expect(kes.citations, isNotEmpty);
      // P9 exposes no method that answers "who cited X" — the graph edges it
      // returns carry only P5 relationship types.
      expect(kes.citations.every((c) => c.trim().isNotEmpty), isTrue);
    });
  });
}
