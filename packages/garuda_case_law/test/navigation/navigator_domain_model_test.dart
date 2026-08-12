import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P16 — domain-model tests (TITAN-KO-015.0 P16).
///
/// Pin the invariants of the navigator's value objects: immutability, equality,
/// serialization round-trips, validation, provenance presence and deterministic
/// ordering / de-duplication of [KnowledgeProductCollection].
void main() {
  group('KnowledgeProductReference — immutability & equality', () {
    test('is immutable', () {
      final r = ref(evidence: const ['e:1']);
      // The value object is not expected to expose mutable state; the evidence
      // list it was given is defensively wrapped on construction.
      expect(r.toProductId, 'KESAVANANDA');
      expect(r.toProductName, 'Kesavananda Bharati');
      expect(r.toProductYear, 1973);
      expect(r.provenance, isNotEmpty);
    });

    test('equal references compare equal; unequal compare unequal', () {
      expect(ref(), ref(), reason: 'identical field values are equal');
      final different = ref(toProductId: 'MINERVA');
      expect(ref() == different, isFalse);
    });

    test('different relationship type changes equality', () {
      final a = ref(relationship: NavigationRelationshipType.primary);
      final b = ref(relationship: NavigationRelationshipType.precedent);
      expect(a == b, isFalse);
    });

    test('different direction changes equality', () {
      final a = ref(direction: NavigationDirection.outgoing);
      final b = ref(direction: NavigationDirection.incoming);
      expect(a == b, isFalse);
    });

    test('hashCode consistent with equality', () {
      expect(ref().hashCode, ref().hashCode);
      expect(ref() == ref(), isTrue);
    });
  });

  group('KnowledgeProductReference — serialization', () {
    test('round-trips through JSON', () {
      final r = ref(
        relationship: NavigationRelationshipType.precedent,
        specificTypeLabel: 'followed',
        direction: NavigationDirection.outgoing,
        evidence: const ['e:followed'],
        provisionType: null,
      );
      final restored = KnowledgeProductReference.fromJson(r.toJson());
      expect(restored, r);
    });

    test('round-trips a provision reference through JSON', () {
      final r = provisionRef();
      final restored = KnowledgeProductReference.fromJson(r.toJson());
      expect(restored, r);
      expect(restored.provisionType, ProvisionType.article);
    });
  });

  group('KnowledgeProductReference — validation', () {
    test('empty destination ID throws', () {
      expect(
        () => ref(toProductId: '  '),
        throwsA(isA<AssertionError>()),
      );
    });

    test('empty provenance throws', () {
      expect(() => ref(provenance: ''), throwsA(isA<AssertionError>()));
    });

    test('provision reference without provisionType throws', () {
      expect(
        () => KnowledgeProductReference(
          originProductType: KnowledgeProductType.caseLaw,
          originProductId: 'ALPHA',
          toProductType: KnowledgeProductType.provision,
          toProductId: '21',
          toProductName: 'Article 21',
          relationshipType: NavigationRelationshipType.referencesProvision,
          provenance: 'p13:provisionRefMap',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('provisionType on a non-provision reference throws', () {
      expect(
        () => ref(provisionType: ProvisionType.article),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('KnowledgeProductReference — provenance', () {
    test('non-primary references carry non-empty provenance and evidence', () {
      final r = ref(
        relationship: NavigationRelationshipType.precedent,
        specificTypeLabel: 'followed',
        evidence: const ['e:followed'],
      );
      expect(r.provenance, isNotEmpty);
      expect(r.evidenceRefs, isNotEmpty);
    });

    test('primary reference provenance names the producing service', () {
      final r = ref(
        relationship: NavigationRelationshipType.primary,
        provenance: 'p16:primary:CaseExplanationService',
      );
      expect(r.provenance, contains('p16:primary'));
    });
  });

  group('KnowledgeProductCollection — de-duplication & ordering', () {
    test('duplicate logical destination + relationship collapses to one', () {
      final c = KnowledgeProductCollection.fromReferences(
        originProductType: KnowledgeProductType.caseLaw,
        originProductId: 'ALPHA',
        refs: [
          ref(toProductId: 'BETA', toName: 'Beta'),
          ref(toProductId: 'BETA', toName: 'Beta'),
        ],
      );
      expect(c.references, hasLength(1));
    });

    test('same destination with different relationship stays distinct', () {
      final c = KnowledgeProductCollection.fromReferences(
        originProductType: KnowledgeProductType.caseLaw,
        originProductId: 'ALPHA',
        refs: [
          ref(
            toProductId: 'BETA',
            toName: 'Beta',
            relationship: NavigationRelationshipType.precedent,
            direction: NavigationDirection.outgoing,
            provenance: 'p5:precedentGraph',
          ),
          ref(
            toProductId: 'BETA',
            toName: 'Beta',
            relationship: NavigationRelationshipType.primary,
            provenance: 'p16:primary',
          ),
        ],
      );
      expect(c.references, hasLength(2));
    });

    test('case references are ordered chronologically by year', () {
      final c = KnowledgeProductCollection.fromReferences(
        originProductType: KnowledgeProductType.caseLaw,
        originProductId: 'ORIGIN',
        refs: [
          ref(toProductId: 'C', toName: 'C', toProductYear: 2010),
          ref(toProductId: 'A', toName: 'A', toProductYear: 1990),
          ref(toProductId: 'B', toName: 'B', toProductYear: 2000),
        ],
      );
      expect(c.references.map((r) => r.toProductYear).toList(),
          [1990, 2000, 2010]);
    });

    test('product kinds group in the fixed type order', () {
      final c = KnowledgeProductCollection.fromReferences(
        originProductType: KnowledgeProductType.caseLaw,
        originProductId: 'ALPHA',
        refs: [
          ref(
            toProductType: KnowledgeProductType.topic,
            toProductId: 't1',
            toName: 'T',
            relationship: NavigationRelationshipType.topicMembership,
            provenance: 'p14:membership',
          ),
          ref(
            toProductType: KnowledgeProductType.question,
            toProductId: 'qa:t1',
            toName: 'T',
            relationship: NavigationRelationshipType.questionSource,
            provenance: 'p15:questionProduct',
          ),
          ref(
            toProductType: KnowledgeProductType.doctrine,
            toProductId: 'd1',
            toName: 'D',
            relationship: NavigationRelationshipType.engagesDoctrine,
            provenance: 'p5:doctrineGraph',
          ),
        ],
      );
      expect(
        c.references.map((r) => r.toProductType).toList(),
        [
          KnowledgeProductType.doctrine,
          KnowledgeProductType.topic,
          KnowledgeProductType.question,
        ],
      );
    });

    test('filters by type, relationship and direction', () {
      final c = KnowledgeProductCollection.fromReferences(
        originProductType: KnowledgeProductType.caseLaw,
        originProductId: 'ALPHA',
        refs: [
          ref(
            toProductId: 'BETA',
            toName: 'Beta',
            relationship: NavigationRelationshipType.precedent,
            direction: NavigationDirection.outgoing,
            provenance: 'p5:precedentGraph',
          ),
          ref(
            toProductId: 'GAMMA',
            toName: 'Gamma',
            relationship: NavigationRelationshipType.precedent,
            direction: NavigationDirection.incoming,
            provenance: 'p5:precedentGraph',
          ),
          ref(
            toProductType: KnowledgeProductType.doctrine,
            toProductId: 'd1',
            toName: 'D',
            relationship: NavigationRelationshipType.engagesDoctrine,
            provenance: 'p5:doctrineGraph',
          ),
        ],
      );
      expect(
          c.ofRelationship(NavigationRelationshipType.precedent), hasLength(2));
      expect(
          c
              .withDirection(NavigationDirection.incoming)
              .map((r) => r.toProductId),
          ['GAMMA']);
      expect(c.ofType(KnowledgeProductType.doctrine), hasLength(1));
    });

    test('is immutable (references list cannot be mutated)', () {
      final c = KnowledgeProductCollection.fromReferences(
        originProductType: KnowledgeProductType.caseLaw,
        originProductId: 'ALPHA',
        refs: [ref()],
      );
      expect(
        () => c.references.add(ref()),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('enums', () {
    test('type display and sort index', () {
      expect(KnowledgeProductType.caseLaw.sortIndex, 0);
      expect(KnowledgeProductTypeExtension.fromName('topic'),
          KnowledgeProductType.topic);
      expect(KnowledgeProductTypeExtension.fromName('bogus'),
          KnowledgeProductType.caseLaw);
    });

    test('legal relationship flag is precise', () {
      expect(NavigationRelationshipType.precedent.isLegalRelationship, isTrue);
      expect(NavigationRelationshipType.engagesDoctrine.isLegalRelationship,
          isTrue);
      expect(NavigationRelationshipType.topicMembership.isLegalRelationship,
          isFalse);
      expect(NavigationRelationshipType.referencesProvision.isLegalRelationship,
          isFalse);
      expect(NavigationRelationshipType.questionSource.isLegalRelationship,
          isFalse);
      expect(NavigationRelationshipType.primary.isLegalRelationship, isFalse);
    });

    test('direction parsing', () {
      expect(NavigationDirectionExtension.fromName('incoming'),
          NavigationDirection.incoming);
      expect(NavigationDirectionExtension.fromName('bogus'),
          NavigationDirection.outgoing);
    });
  });
}

/// A valid case-type reference used across the domain tests.
KnowledgeProductReference ref({
  KnowledgeProductType toProductType = KnowledgeProductType.caseLaw,
  String toProductId = 'KESAVANANDA',
  String toName = 'Kesavananda Bharati',
  int? toProductYear = 1973,
  ProvisionType? provisionType,
  NavigationRelationshipType relationship =
      NavigationRelationshipType.precedent,
  String specificTypeLabel = '',
  NavigationDirection? direction,
  String provenance = 'p5:precedentGraph',
  List<String> evidence = const ['e:1'],
}) =>
    KnowledgeProductReference(
      originProductType: KnowledgeProductType.caseLaw,
      originProductId: 'ORIGIN',
      toProductType: toProductType,
      toProductId: toProductId,
      toProductName: toName,
      toProductYear: toProductYear,
      provisionType: provisionType,
      relationshipType: relationship,
      specificTypeLabel: specificTypeLabel,
      direction: direction,
      provenance: provenance,
      evidenceRefs: evidence,
    );

/// A valid provision-type reference.
KnowledgeProductReference provisionRef({
  ProvisionType type = ProvisionType.article,
  String key = '21',
}) =>
    KnowledgeProductReference(
      originProductType: KnowledgeProductType.caseLaw,
      originProductId: 'ALPHA',
      toProductType: KnowledgeProductType.provision,
      toProductId: key,
      toProductName: 'Article 21',
      provisionType: type,
      relationshipType: NavigationRelationshipType.referencesProvision,
      direction: NavigationDirection.outgoing,
      provenance: 'p13:provisionRefMap',
      evidenceRefs: const ['Article 21'],
    );
