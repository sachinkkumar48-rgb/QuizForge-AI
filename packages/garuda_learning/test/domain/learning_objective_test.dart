import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart' show KnowledgeProductType;
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('LearningObjective & Value Objects Domain Tests', () {
    test('LearningObjective instantiates correctly with required fields', () {
      final obj = LearningObjective(
        id: 'lo_test_1',
        unitId: 'unit_test',
        title: 'Test Objective Title',
        description: 'Detailed description of objective.',
        bloomLevel: BloomTaxonomyLevel.analyze,
        sequenceIndex: 1,
        provenance: 'P17 Test Suite',
      );

      expect(obj.id, equals('lo_test_1'));
      expect(obj.unitId, equals('unit_test'));
      expect(obj.bloomLevel, equals(BloomTaxonomyLevel.analyze));
      expect(obj.prerequisites, isEmpty);
      expect(obj.supportedProducts, isEmpty);
      expect(obj.masteryCriteria.minRequiredProducts, equals(1));
    });

    test('LearningObjective serialization round-trip (toJson / fromJson)', () {
      final original = LearningObjective(
        id: 'lo_roundtrip',
        unitId: 'unit_fr',
        title: 'Roundtrip Test',
        description: 'Testing serialization fidelity.',
        bloomLevel: BloomTaxonomyLevel.evaluate,
        prerequisites: [
          PrerequisiteRelationship(
            prerequisiteObjectiveId: 'lo_prereq_base',
            provenance: 'Rule 1.1',
            isMandatory: true,
            rationale: 'Base requirement',
          ),
        ],
        supportedProducts: [
          KnowledgeProductMapping(
            productType: KnowledgeProductType.caseLaw,
            productId: 'kesavananda_1973',
            title: 'Kesavananda Case',
            provenance: 'P11 Corpus',
            role: 'leading_case',
          ),
        ],
        masteryCriteria: const StaticMasteryCriteria(
          minRequiredProducts: 1,
          mandatoryProductIds: ['kesavananda_1973'],
          description: 'Requires Kesavananda',
        ),
        sequenceIndex: 3,
        provenance: 'P17 Spec',
      );

      final json = original.toJson();
      final reconstituted = LearningObjective.fromJson(json);

      expect(reconstituted, equals(original));
      expect(reconstituted.prerequisiteIds, contains('lo_prereq_base'));
      expect(reconstituted.supportedProducts.first.productId,
          equals('kesavananda_1973'));
    });

    test('BloomTaxonomyLevelExtension displays correct titles and parses names',
        () {
      expect(BloomTaxonomyLevel.remember.displayTitle, equals('Remember'));
      expect(BloomTaxonomyLevel.analyze.displayTitle, equals('Analyze'));
      expect(BloomTaxonomyLevelExtension.fromName('create'),
          equals(BloomTaxonomyLevel.create));
      expect(BloomTaxonomyLevelExtension.fromName('unknown'),
          equals(BloomTaxonomyLevel.understand));
    });

    test(
        'PrerequisiteRelationship rejects empty objective ID or missing provenance',
        () {
      expect(
        () => PrerequisiteRelationship(
          prerequisiteObjectiveId: '',
          provenance: 'Provenence',
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => PrerequisiteRelationship(
          prerequisiteObjectiveId: 'lo_valid',
          provenance: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('KnowledgeProductMapping enforces provisionType rules', () {
      expect(
        () => KnowledgeProductMapping(
          productType: KnowledgeProductType.provision,
          productId: 'art_21',
          title: 'Article 21',
          provisionType: null, // missing provisionType!
          provenance: 'P13 Corpus',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
