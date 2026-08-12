import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P16 — legal-safety tests (TITAN-KO-015.0 P16).
///
/// P16 is a composition/read/navigation layer, not a legal reasoning engine.
/// These tests pin that: every navigation edge traces to an actual validated
/// source; no generic "similar"/"related"/"connected" edge is invented;
/// relationship semantics are preserved verbatim; directional edges keep their
/// direction; P14 topic membership is never confused with legal precedent;
/// provision association is sourced from the P13 map (not a fabricated P5
/// edge); provenance is always present; no unsupported legal conclusion is
/// generated; and the P5 graph is never mutated.
void main() {
  final svc = buildSyntheticNavigator();
  final graph = svc.graph;

  group('A. no fabricated relationships', () {
    test('every emitted relationship kind is a known concrete kind', () {
      final valid = NavigationRelationshipType.values.toSet();
      for (final originId in const ['ALPHA', 'BETA', 'GAMMA', 'DELTA']) {
        final c = svc.findAllProductsForCase(originId);
        for (final r in c.references) {
          expect(valid.contains(r.relationshipType), isTrue,
              reason: 'unknown relationship: ${r.relationshipType}');
        }
      }
    });

    test('no reference claims a legal-similarity relationship', () {
      for (final id in const ['ALPHA', 'BETA', 'GAMMA']) {
        for (final r in svc.findAllProductsForCase(id).references) {
          expect(
            ['similar', 'connected', 'vaguely-related', 'best-match']
                .contains(r.relationshipType.name),
            isFalse,
          );
          expect(r.relationshipType.name, isNot('related'),
              reason: 'precedent "related" must be a typed P5 label, not a '
                  'generic edge');
        }
      }
    });

    test('every non-primary reference carries provenance and evidence', () {
      for (final id in const ['ALPHA', 'BETA', 'GAMMA']) {
        for (final r in svc.findAllProductsForCase(id).references) {
          if (r.relationshipType == NavigationRelationshipType.primary) {
            continue;
          }
          expect(r.provenance.trim(), isNotEmpty);
          expect(r.evidenceRefs, isNotEmpty,
              reason: 'edge with no evidence cannot be explained: $r');
        }
      }
    });

    test('provision association is sourced from the P13 map, never a P5 edge',
        () {
      for (final id in const ['ALPHA', 'BETA', 'GAMMA']) {
        for (final r in svc
            .findAllProductsForCase(id)
            .ofRelationship(NavigationRelationshipType.referencesProvision)) {
          expect(r.provenance, 'p13:provisionRefMap');
          expect(r.direction, NavigationDirection.outgoing);
        }
      }
    });

    test('every destination ID is a real corpus / validated identifier', () {
      final validCases = {'ALPHA', 'BETA', 'GAMMA', 'DELTA'};
      final validDoctrines = {'SYNTH_DOCTRINE', 'SECOND_DOCTRINE'};
      final validProvisions = {
        '21',
        'representation of the people act 1951',
        'section 154 crpc'
      };
      final validTopics = {'topic_alpha', 'topic_sparse'};
      for (final id in const ['ALPHA', 'BETA', 'GAMMA', 'DELTA']) {
        for (final r in svc.findAllProductsForCase(id).references) {
          switch (r.toProductType) {
            case KnowledgeProductType.caseLaw:
              expect(validCases.contains(r.toProductId), isTrue);
            case KnowledgeProductType.doctrine:
              expect(validDoctrines.contains(r.toProductId), isTrue);
            case KnowledgeProductType.provision:
              expect(validProvisions.contains(r.toProductId), isTrue);
            case KnowledgeProductType.topic:
              expect(validTopics.contains(r.toProductId), isTrue);
            case KnowledgeProductType.question:
              expect(r.toProductId, startsWith('qa:'));
          }
        }
      }
    });
  });

  group('B. semantics preserved', () {
    test('P5 precedent type labels survive verbatim', () {
      final c = svc.findAllProductsForCase('ALPHA');
      final labels = c
          .ofRelationship(NavigationRelationshipType.precedent)
          .map((r) => '${r.toProductId}:${r.specificTypeLabel}')
          .toSet();
      expect(labels, {
        'BETA:related', // ALPHA -> BETA (outgoing, related)
        'BETA:followed', // BETA -> ALPHA (incoming, followed)
        'GAMMA:distinguished', // GAMMA -> ALPHA (incoming, distinguished)
      });
    });

    test('directional precedent edges are not made symmetric', () {
      final alpha = svc.findAllProductsForCase('ALPHA');
      final beta = svc.findAllProductsForCase('BETA');
      // ALPHA → BETA (outgoing) is `related` (from ALPHA.relatedCases); the
      // BETA → ALPHA edge (incoming to ALPHA) is `followed`. They are distinct
      // directional edges and are never conflated.
      final alphaOutToBeta = alpha
          .ofRelationship(NavigationRelationshipType.precedent)
          .where((r) =>
              r.toProductId == 'BETA' &&
              r.direction == NavigationDirection.outgoing);
      expect(
          alphaOutToBeta.map((r) => r.specificTypeLabel).toSet(), {'related'});
      // BETA → ALPHA (outgoing from BETA) is `followed`.
      final betaOutToAlpha = beta
          .ofRelationship(NavigationRelationshipType.precedent)
          .where((r) =>
              r.toProductId == 'ALPHA' &&
              r.direction == NavigationDirection.outgoing);
      expect(
          betaOutToAlpha.map((r) => r.specificTypeLabel).toSet(), {'followed'});
    });

    test('doctrine roles are preserved verbatim', () {
      final c = svc.findAllProductsForCase('ALPHA');
      final d =
          c.ofRelationship(NavigationRelationshipType.engagesDoctrine).single;
      expect(d.specificTypeLabel, 'engages');
      expect(d.direction, NavigationDirection.outgoing);
    });

    test('topic membership is never a legal relationship', () {
      for (final id in const ['ALPHA', 'BETA', 'DELTA']) {
        for (final r in svc
            .findAllProductsForCase(id)
            .ofRelationship(NavigationRelationshipType.topicMembership)) {
          expect(r.relationshipType.isLegalRelationship, isFalse);
          expect(
              r.relationshipType, isNot(NavigationRelationshipType.precedent));
        }
      }
    });

    test('topic membership carries the P14 provenance, not a P5 edge id', () {
      final c = svc.findAllProductsForCase('ALPHA');
      final t =
          c.ofRelationship(NavigationRelationshipType.topicMembership).single;
      expect(t.provenance, 'p14:membership');
      expect(t.evidenceRefs, isNotEmpty);
      expect(t.evidenceRefs.first, contains('p4:mainsThemes'));
    });
  });

  group('C. no unsupported legal conclusions', () {
    test('navigating never produces a similarity/importance/current-law claim',
        () {
      final out = StringBuffer();
      for (final id in const ['ALPHA', 'BETA', 'GAMMA', 'DELTA']) {
        final c = svc.findAllProductsForCase(id);
        for (final r in c.references) {
          out.write('${r.toProductName} ');
        }
      }
      final text = out.toString().toLowerCase();
      expect(text.contains('similar'), isFalse);
      expect(text.contains('most important'), isFalse);
      expect(text.contains('current law is'), isFalse);
      expect(text.contains('overrules by analogy'), isFalse);
    });

    test('reference ordering carries no editorial importance', () {
      // The collection exposes no score / rank / relevance field.
      for (final id in const ['ALPHA', 'BETA', 'GAMMA']) {
        for (final r in svc.findAllProductsForCase(id).references) {
          expect(r.toJson().containsKey('score'), isFalse);
          expect(r.toJson().containsKey('relevance'), isFalse);
          expect(r.toJson().containsKey('authority'), isFalse);
        }
      }
    });
  });

  group('D. provenance completeness', () {
    test('every reference carries a non-empty explainable provenance', () {
      for (final id in const ['ALPHA', 'BETA', 'GAMMA', 'DELTA']) {
        for (final r in svc.findAllProductsForCase(id).references) {
          expect(r.provenance.trim(), isNotEmpty);
        }
      }
    });

    test('reference provenance records the exact origin field', () {
      final c = svc.findAllProductsForCase('ALPHA');
      final precedent = c
          .ofRelationship(NavigationRelationshipType.precedent)
          .where((r) => r.toProductId == 'GAMMA')
          .single;
      expect(precedent.provenance, 'corpus:precedentsDistinguished');
      final doctrine =
          c.ofRelationship(NavigationRelationshipType.engagesDoctrine).single;
      expect(doctrine.provenance, 'corpus:doctrines');
    });
  });

  group('E. P5 graph unchanged', () {
    test('navigation never mutates the graph', () {
      final before = graph.edgeCount;
      final beforeNodes = graph.caseNodes.length + graph.doctrineNodes.length;
      for (final id in const ['ALPHA', 'BETA', 'GAMMA', 'DELTA']) {
        svc.findAllProductsForCase(id);
        svc.resolveAll(svc.findAllProductsForCase(id));
      }
      expect(graph.edgeCount, before);
      expect(graph.caseNodes.length + graph.doctrineNodes.length, beforeNodes);
    });
  });

  group('F. missing data → omission, never fabrication', () {
    test('sparse case yields no question product and no fabricated edges', () {
      final c = svc.findAllProductsForCase('DELTA');
      expect(
          c.ofRelationship(NavigationRelationshipType.questionSource), isEmpty);
      // DELTA has no doctrines, provisions or precedent edges seeded, so none
      // may appear.
      expect(c.ofRelationship(NavigationRelationshipType.engagesDoctrine),
          isEmpty);
      expect(c.ofRelationship(NavigationRelationshipType.referencesProvision),
          isEmpty);
      expect(c.ofRelationship(NavigationRelationshipType.precedent), isEmpty);
    });

    test('an unresolved destination is never returned', () {
      // Every returned reference resolves to a real product.
      for (final id in const ['ALPHA', 'BETA', 'GAMMA', 'DELTA']) {
        for (final r in svc.findAllProductsForCase(id).references) {
          expect(svc.resolvable(r), isTrue);
        }
      }
    });
  });
}
