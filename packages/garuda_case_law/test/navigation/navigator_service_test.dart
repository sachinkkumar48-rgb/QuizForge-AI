import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P16 — navigator service tests (TITAN-KO-015.0 P16).
///
/// Exercise the composition layer over the synthetic corpus: case → products,
/// doctrine → products, provision → products, topic → products, question →
/// source, related-product discovery, incoming/outgoing relationships,
/// empty/missing-product behavior and duplicate suppression. Every reference is
/// verified to resolve to an actual knowledge product.
void main() {
  final svc = buildSyntheticNavigator();

  group('A. case → products', () {
    test(
        'ALPHA resolves its primary, precedents, doctrine, provision, topic '
        'and question products', () {
      final c = svc.findAllProductsForCase('ALPHA');
      expect(c.originProductType, KnowledgeProductType.caseLaw);
      expect(c.originProductId, 'ALPHA');
      expect(c.isEmpty, isFalse);

      // Primary (the case's own P11 explanation).
      final primary =
          c.ofRelationship(NavigationRelationshipType.primary).single;
      expect(primary.toProductType, KnowledgeProductType.caseLaw);
      expect(primary.toProductId, 'ALPHA');
      expect(svc.resolvable(primary), isTrue);

      // Precedent edges: outgoing BETA (related) + incoming BETA (followed) and
      // GAMMA (distinguished).
      final precedents =
          c.ofRelationship(NavigationRelationshipType.precedent).toList();
      final outgoing =
          precedents.where((r) => r.direction == NavigationDirection.outgoing);
      final incoming =
          precedents.where((r) => r.direction == NavigationDirection.incoming);
      expect(outgoing.map((r) => r.toProductId), contains('BETA'));
      expect(
        outgoing.where((r) => r.toProductId == 'BETA').single.specificTypeLabel,
        'related',
      );
      expect(
        incoming.where((r) => r.toProductId == 'BETA').single.specificTypeLabel,
        'followed',
      );
      expect(
        incoming
            .where((r) => r.toProductId == 'GAMMA')
            .single
            .specificTypeLabel,
        'distinguished',
      );

      // Doctrine engaged.
      final doctrine =
          c.ofRelationship(NavigationRelationshipType.engagesDoctrine).single;
      expect(doctrine.toProductType, KnowledgeProductType.doctrine);
      expect(doctrine.toProductId, 'SYNTH_DOCTRINE');
      expect(doctrine.specificTypeLabel, 'engages');
      expect(doctrine.direction, NavigationDirection.outgoing);

      // Provision referenced.
      final provision = c
          .ofRelationship(NavigationRelationshipType.referencesProvision)
          .single;
      expect(provision.toProductType, KnowledgeProductType.provision);
      expect(provision.toProductId, '21');
      expect(provision.provisionType, ProvisionType.article);
      expect(provision.provenance, 'p13:provisionRefMap');

      // Topic membership (pedagogical, non-legal).
      final topic =
          c.ofRelationship(NavigationRelationshipType.topicMembership).single;
      expect(topic.toProductType, KnowledgeProductType.topic);
      expect(topic.toProductId, 'topic_alpha');
      expect(topic.relationshipType.isLegalRelationship, isFalse);

      // Question source.
      final q =
          c.ofRelationship(NavigationRelationshipType.questionSource).single;
      expect(q.toProductType, KnowledgeProductType.question);
      expect(q.toProductId, 'qa:case:ALPHA');

      // Everything resolves.
      expect(svc.resolveAll(c).length, c.references.length);
    });

    test('case aliases and names resolve to the canonical ID', () {
      expect(svc.findAllProductsForCase('Alpha Case').originProductId, 'ALPHA');
      expect(svc.findAllProductsForCase('ALPHA').originProductId, 'ALPHA');
    });

    test('unknown case yields an empty collection (nothing fabricated)', () {
      final c = svc.findAllProductsForCase('NOT_A_CASE');
      expect(c.isEmpty, isTrue);
    });

    test('a sparse case omits its question product but keeps its topic', () {
      final c = svc.findAllProductsForCase('DELTA');
      expect(
          c.ofRelationship(NavigationRelationshipType.questionSource), isEmpty);
      expect(
          c
              .ofRelationship(NavigationRelationshipType.topicMembership)
              .single
              .toProductId,
          'topic_sparse');
      expect(svc.resolveAll(c).length, c.references.length);
    });
  });

  group('B. doctrine → products', () {
    test('SYNTH_DOCTRINE resolves its primary, constituent cases and question',
        () {
      final c = svc.findAllProductsForDoctrine('SYNTH_DOCTRINE');
      expect(c.originProductType, KnowledgeProductType.doctrine);
      expect(c.originProductId, 'SYNTH_DOCTRINE');

      final primary =
          c.ofRelationship(NavigationRelationshipType.primary).single;
      expect(primary.toProductId, 'SYNTH_DOCTRINE');
      expect(svc.resolvable(primary), isTrue);

      final members = c
          .ofRelationship(NavigationRelationshipType.engagesDoctrine)
          .map((r) => r.toProductId)
          .toSet();
      expect(members, {'ALPHA', 'BETA'});
      expect(
        c
            .ofRelationship(NavigationRelationshipType.engagesDoctrine)
            .every((r) => r.direction == NavigationDirection.incoming),
        isTrue,
      );

      final q =
          c.ofRelationship(NavigationRelationshipType.questionSource).single;
      expect(q.toProductId, 'qa:doctrine:SYNTH_DOCTRINE');
      expect(svc.resolveAll(c).length, c.references.length);
    });

    test('a doctrine with no resolvable cases yields only primary + question',
        () {
      final c = svc.findAllProductsForDoctrine('SECOND_DOCTRINE');
      expect(c.ofRelationship(NavigationRelationshipType.engagesDoctrine),
          isEmpty);
      expect(
          c
              .ofRelationship(NavigationRelationshipType.primary)
              .single
              .toProductId,
          'SECOND_DOCTRINE');
      expect(svc.resolveAll(c).length, c.references.length);
    });

    test('unknown doctrine yields an empty collection', () {
      expect(svc.findAllProductsForDoctrine('NOPE').isEmpty, isTrue);
    });
  });

  group('C. provision → products', () {
    test('Article 21 resolves its primary, referencing cases and question', () {
      final c = svc.findAllProductsForProvision(ProvisionType.article, '21');
      expect(c.originProductType, KnowledgeProductType.provision);
      expect(c.originProductId, '21');

      final primary =
          c.ofRelationship(NavigationRelationshipType.primary).single;
      expect(primary.toProductId, '21');
      expect(primary.provisionType, ProvisionType.article);
      expect(svc.resolvable(primary), isTrue);

      final refs = c
          .ofRelationship(NavigationRelationshipType.referencesProvision)
          .map((r) => r.toProductId)
          .toSet();
      expect(refs, {'ALPHA'});
      expect(
        c
            .ofRelationship(NavigationRelationshipType.referencesProvision)
            .single
            .direction,
        NavigationDirection.incoming,
      );

      final q =
          c.ofRelationship(NavigationRelationshipType.questionSource).single;
      expect(q.toProductType, KnowledgeProductType.question);
      expect(svc.resolveAll(c).length, c.references.length);
    });

    test('unknown provision yields an empty collection', () {
      expect(
        svc.findAllProductsForProvision(ProvisionType.article, '999').isEmpty,
        isTrue,
      );
    });
  });

  group('D. topic → products', () {
    test('topic_alpha resolves its primary, member cases and question', () {
      final c = svc.findAllProductsForTopic('topic_alpha');
      expect(c.originProductType, KnowledgeProductType.topic);
      expect(c.originProductId, 'topic_alpha');

      final primary =
          c.ofRelationship(NavigationRelationshipType.primary).single;
      expect(primary.toProductId, 'topic_alpha');
      expect(svc.resolvable(primary), isTrue);

      final members = c
          .ofRelationship(NavigationRelationshipType.topicMembership)
          .map((r) => r.toProductId)
          .toSet();
      expect(members, {'ALPHA', 'BETA'});

      final q =
          c.ofRelationship(NavigationRelationshipType.questionSource).single;
      expect(q.toProductId, 'qa:topic:topic_alpha');
      expect(svc.resolveAll(c).length, c.references.length);
    });

    test('unknown topic yields an empty collection', () {
      expect(svc.findAllProductsForTopic('nope').isEmpty, isTrue);
    });
  });

  group('E. question → source', () {
    test('a case question product navigates back to its case source', () {
      final c = svc.findAllProductsForQuestion('qa:case:ALPHA');
      expect(c.originProductType, KnowledgeProductType.question);
      expect(c.originProductId, 'qa:case:ALPHA');

      final source =
          c.ofRelationship(NavigationRelationshipType.questionSource).single;
      expect(source.toProductType, KnowledgeProductType.caseLaw);
      expect(source.toProductId, 'ALPHA');
      expect(svc.resolvable(source), isTrue);
    });

    test('unknown question product yields an empty collection', () {
      expect(svc.findAllProductsForQuestion('qa:case:UNKNOWN').isEmpty, isTrue);
    });
  });

  group('F. related-product discovery & generalized dispatch', () {
    test('findRelatedProducts drops the primary root', () {
      final all = svc.findAllProductsForCase('ALPHA');
      final related =
          svc.findRelatedProducts(KnowledgeProductType.caseLaw, 'ALPHA');
      expect(
          related.ofRelationship(NavigationRelationshipType.primary), isEmpty);
      expect(related.references.length, all.references.length - 1);
    });

    test('generalized dispatch routes by product type', () {
      expect(
          svc
              .findAllProductsFor(
                  KnowledgeProductType.doctrine, 'SYNTH_DOCTRINE')
              .originProductId,
          'SYNTH_DOCTRINE');
      expect(
        svc
            .findAllProductsFor(KnowledgeProductType.provision, '21',
                provisionType: ProvisionType.article)
            .originProductId,
        '21',
      );
    });

    test('navigateRelationship filters to one relationship kind', () {
      final all = svc.findAllProductsForCase('ALPHA');
      final precedents =
          svc.navigateRelationship(all, NavigationRelationshipType.precedent);
      expect(
        precedents.references.every(
            (r) => r.relationshipType == NavigationRelationshipType.precedent),
        isTrue,
      );
      expect(precedents.length, greaterThan(0));
    });
  });

  group('G. incoming/outgoing are exposed explicitly', () {
    test('ALPHA exposes both incoming and outgoing precedent edges', () {
      final c = svc.findAllProductsForCase('ALPHA');
      final out = c.withDirection(NavigationDirection.outgoing).toList();
      final inn = c.withDirection(NavigationDirection.incoming).toList();
      expect(out.any((r) => r.toProductId == 'BETA'), isTrue);
      expect(inn.map((r) => r.toProductId), containsAll(['BETA', 'GAMMA']));
      // Incoming relationships are never rewritten as outgoing ones.
      expect(
        inn.every((r) => r.direction == NavigationDirection.incoming),
        isTrue,
      );
    });
  });

  group('H. duplicate suppression', () {
    test('navigating twice returns identical (deduplicated) collections', () {
      final a = svc.findAllProductsForCase('ALPHA');
      final b = svc.findAllProductsForCase('ALPHA');
      expect(a, b);
      expect(a.references.length, b.references.length);
      // No two references share the same logical destination + relationship.
      final keys = a.references.map((r) => r.dedupKey).toSet();
      expect(keys.length, a.references.length);
    });
  });

  group('I. product resolution', () {
    test('resolve returns concrete product objects by kind', () {
      final c = svc.findAllProductsForCase('ALPHA');
      for (final r in c.references) {
        final o = svc.resolve(r);
        expect(o, isNotNull, reason: 'every destination must resolve: $r');
        switch (r.toProductType) {
          case KnowledgeProductType.caseLaw:
            expect(o, isA<CaseExplanation>());
          case KnowledgeProductType.doctrine:
            expect(o, isA<DoctrineKnowledgeProduct>());
          case KnowledgeProductType.provision:
            expect(o, isA<StatuteKnowledgeProduct>());
          case KnowledgeProductType.topic:
            expect(o, isA<TopicKnowledgeProduct>());
          case KnowledgeProductType.question:
            expect(o, isA<QuestionKnowledgeProduct>());
        }
      }
    });
  });
}
