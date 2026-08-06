import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('ConceptValidationService Tests', () {
    test('validateConcept detects duplicate concepts', () {
      final now = DateTime.now();
      final c1 = Concept(
        id: 'C1',
        name: 'Federalism',
        description: 'Division of powers',
        subject: 'Polity',
        module: 'Framework',
        topic: 'Federal Structure',
        createdAt: now,
        updatedAt: now,
      );

      final c2 = Concept(
        id: 'C2',
        name: 'Federalism', // Duplicate name in same subject
        description: 'Alternative description',
        subject: 'Polity',
        module: 'Framework',
        topic: 'Federal Structure',
        createdAt: now,
        updatedAt: now,
      );

      final errors = ConceptValidationService.validateConcept(c2, existingConcepts: [c1]);
      expect(errors.any((e) => e.code == ConceptValidationErrorCode.duplicateConcept), isTrue);
    });

    test('validateMapping detects invalid confidence and duplicate mappings', () {
      const m1 = QuestionConceptMapping(
        questionId: 'Q1',
        conceptId: 'C1',
        confidenceScore: 0.85,
        mappingMethod: MappingMethod.manual,
      );

      const m2 = QuestionConceptMapping(
        questionId: 'Q1',
        conceptId: 'C1',
        confidenceScore: 1.5, // Out of bounds (> 1.0)
        mappingMethod: MappingMethod.manual,
      );

      final errors = ConceptValidationService.validateMapping(m2, existingMappings: [m1]);
      expect(errors.any((e) => e.code == ConceptValidationErrorCode.invalidConfidence), isTrue);
      expect(errors.any((e) => e.code == ConceptValidationErrorCode.duplicateMapping), isTrue);
    });

    test('detectCircularRelationships identifies graph cycles', () {
      const rels = [
        ConceptRelationship(
          id: 'R1',
          sourceConceptId: 'C_FUNDAMENTAL_RIGHTS',
          targetConceptId: 'C_WRITS',
          relationshipType: ConceptRelationshipType.prerequisite,
        ),
        ConceptRelationship(
          id: 'R2',
          sourceConceptId: 'C_WRITS',
          targetConceptId: 'C_HABEAS_CORPUS',
          relationshipType: ConceptRelationshipType.prerequisite,
        ),
        ConceptRelationship(
          id: 'R3',
          sourceConceptId: 'C_HABEAS_CORPUS',
          targetConceptId: 'C_FUNDAMENTAL_RIGHTS', // Cycle!
          relationshipType: ConceptRelationshipType.prerequisite,
        ),
      ];

      final errors = ConceptValidationService.detectCircularRelationships(rels);
      expect(errors.any((e) => e.code == ConceptValidationErrorCode.circularRelationship), isTrue);
    });
  });
}
