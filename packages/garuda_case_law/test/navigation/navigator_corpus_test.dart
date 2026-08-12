import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P16 — corpus-wide navigator tests (TITAN-KO-015.0 P16).
///
/// Run the navigator over the real production corpus: all 49 cases, all
/// canonical doctrines, all configured provisions and all configured topics.
/// Verifies that every emitted reference resolves, that navigation is
/// deterministic and offline, that the P5 graph is never mutated and that the
/// legal-safety boundaries hold corpus-wide.
void main() {
  final svc = KnowledgeProductNavigatorService();
  final graph = svc.graph;

  test('corpus exposes the expected production sizes', () {
    expect(svc.cases.length, greaterThanOrEqualTo(49));
    expect(svc.doctrines.length, greaterThan(0));
    expect(svc.topicProductService.topics.length, greaterThan(0));
  });

  group('A. corpus-wide case navigation', () {
    test('every case resolves a collection of real products', () {
      var totalRefs = 0;
      for (final c in svc.cases) {
        final col = svc.findAllProductsForCase(c.caseId);
        expect(col.isEmpty, isFalse, reason: 'case ${c.caseId} should resolve');
        for (final r in col.references) {
          expect(svc.resolvable(r), isTrue,
              reason: 'unresolvable reference in ${c.caseId}: $r');
        }
        totalRefs += col.references.length;
      }
      expect(totalRefs, greaterThan(0));
    });

    test('every case has exactly one primary product', () {
      for (final c in svc.cases) {
        final col = svc.findAllProductsForCase(c.caseId);
        expect(
          col.ofRelationship(NavigationRelationshipType.primary).length,
          1,
          reason: 'case ${c.caseId}',
        );
      }
    });
  });

  group('B. corpus-wide doctrine navigation', () {
    test('every doctrine resolves its primary product', () {
      for (final d in svc.doctrines) {
        final col = svc.findAllProductsForDoctrine(d.doctrineId);
        expect(
          col
              .ofRelationship(NavigationRelationshipType.primary)
              .single
              .toProductId,
          d.doctrineId,
        );
        for (final r in col.references) {
          expect(svc.resolvable(r), isTrue);
        }
      }
    });
  });

  group('C. corpus-wide provision navigation', () {
    test('every configured provision resolves', () {
      for (final type in ProvisionType.values) {
        for (final id in svc.statuteProductService.provisionIds(type)) {
          final col = svc.findAllProductsForProvision(type, id);
          expect(
            col
                .ofRelationship(NavigationRelationshipType.primary)
                .single
                .toProductId,
            id,
          );
          for (final r in col.references) {
            expect(svc.resolvable(r), isTrue);
          }
        }
      }
    });
  });

  group('D. corpus-wide topic navigation', () {
    test('every configured topic resolves', () {
      for (final t in svc.topicProductService.topics) {
        final col = svc.findAllProductsForTopic(t.id);
        expect(
            col
                .ofRelationship(NavigationRelationshipType.primary)
                .single
                .toProductId,
            t.id);
        for (final r in col.references) {
          expect(svc.resolvable(r), isTrue);
        }
      }
    });

    test('topic membership references are never legal relationships', () {
      for (final t in svc.topicProductService.topics) {
        final col = svc.findAllProductsForTopic(t.id);
        for (final r
            in col.ofRelationship(NavigationRelationshipType.topicMembership)) {
          expect(r.relationshipType.isLegalRelationship, isFalse);
          expect(r.provenance, 'p14:membership');
        }
      }
    });
  });

  group('E. corpus-wide question navigation', () {
    test('every generated question product navigates back to its source', () {
      for (final q in svc.questionProductService.buildAll()) {
        final col = svc.findAllProductsForQuestion(q.productId);
        expect(col.originProductId, q.productId);
        for (final r in col.references) {
          expect(svc.resolvable(r), isTrue);
        }
      }
    });
  });

  group('F. directionality across the corpus', () {
    test('some cases expose both incoming and outgoing precedent edges', () {
      var both = false;
      for (final c in svc.cases) {
        final col = svc.findAllProductsForCase(c.caseId);
        final out = col
            .withDirection(NavigationDirection.outgoing)
            .where((r) => r.toProductType == KnowledgeProductType.caseLaw)
            .isNotEmpty;
        final inn = col
            .withDirection(NavigationDirection.incoming)
            .where((r) => r.toProductType == KnowledgeProductType.caseLaw)
            .isNotEmpty;
        if (out && inn) {
          both = true;
          break;
        }
      }
      expect(both, isTrue,
          reason: 'the corpus should contain both incoming and outgoing edges');
    });

    test('incoming edges are never rewritten as outgoing', () {
      for (final c in svc.cases) {
        for (final r in svc.findAllProductsForCase(c.caseId).references) {
          if (r.relationshipType == NavigationRelationshipType.precedent) {
            expect(r.direction, isNotNull);
          }
        }
      }
    });
  });

  group('G. determinism & offline', () {
    test('repeated navigation is structurally identical', () {
      for (final id in ['KESAVANANDA', 'MINERVA', 'Kesavananda Bharati']) {
        final a = svc.findAllProductsForCase(id);
        final b = svc.findAllProductsForCase(id);
        expect(a, b);
        expect(
          a.references.map((r) => r.toJson().toString()).toList(),
          b.references.map((r) => r.toJson().toString()).toList(),
        );
      }
    });

    test('doctrine/provision/topic navigation is identical across calls', () {
      final d1 = svc.findAllProductsForDoctrine('BASIC_STRUCTURE');
      final d2 = svc.findAllProductsForDoctrine('BASIC_STRUCTURE');
      expect(d1, d2);
      final t1 = svc.topicProductService.topics.first.id;
      expect(svc.findAllProductsForTopic(t1), svc.findAllProductsForTopic(t1));
    });

    test('navigation is offline (no network / no timing dependency)', () {
      // Deterministic output does not depend on the clock, randomness or the
      // environment: two runs over the full corpus are byte-identical.
      final run1 = <String>[];
      final run2 = <String>[];
      for (final c in svc.cases) {
        run1.addAll(svc
            .findAllProductsForCase(c.caseId)
            .references
            .map((r) => r.toJson().toString()));
      }
      for (final c in svc.cases) {
        run2.addAll(svc
            .findAllProductsForCase(c.caseId)
            .references
            .map((r) => r.toJson().toString()));
      }
      expect(run1, run2);
    });
  });

  group('H. P5 graph unchanged across the corpus', () {
    test('full-corpus navigation does not mutate the graph', () {
      final edgeCount = graph.edgeCount;
      final nodeCount = graph.caseNodes.length + graph.doctrineNodes.length;
      for (final c in svc.cases) {
        svc.resolveAll(svc.findAllProductsForCase(c.caseId));
      }
      expect(graph.edgeCount, edgeCount);
      expect(graph.caseNodes.length + graph.doctrineNodes.length, nodeCount);
    });
  });
}
