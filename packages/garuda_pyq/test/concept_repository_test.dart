import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('Concept Repositories Tests', () {
    late OfflineConceptRepository conceptRepo;
    late OfflineQuestionConceptRepository mappingRepo;

    setUp(() {
      conceptRepo = OfflineConceptRepository();
      mappingRepo = OfflineQuestionConceptRepository();
    });

    test('OfflineConceptRepository CRUD and relationships', () async {
      final now = DateTime.now();
      final c1 = Concept(
        id: 'C1',
        name: 'Basic Structure Doctrine',
        description: 'Limitation on amending power',
        subject: 'Polity',
        module: 'Constitution',
        topic: 'Amendments',
        createdAt: now,
        updatedAt: now,
      );

      await conceptRepo.saveConcept(c1);
      final fetched = await conceptRepo.getConceptById('C1');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Basic Structure Doctrine'));

      const rel = ConceptRelationship(
        id: 'R1',
        sourceConceptId: 'C1',
        targetConceptId: 'C2',
        relationshipType: ConceptRelationshipType.prerequisite,
      );
      await conceptRepo.saveRelationship(rel);

      final rels = await conceptRepo.getRelationshipsForConcept('C1');
      expect(rels.length, equals(1));
      expect(rels.first.targetConceptId, equals('C2'));
    });

    test('OfflineQuestionConceptRepository CRUD', () async {
      const mapping = QuestionConceptMapping(
        questionId: 'Q100',
        conceptId: 'C1',
        confidenceScore: 0.92,
        mappingMethod: MappingMethod.manual,
      );

      await mappingRepo.saveMapping(mapping);

      final qMappings = await mappingRepo.getMappingsByQuestion('Q100');
      expect(qMappings.length, equals(1));
      expect(qMappings.first.conceptId, equals('C1'));

      final cMappings = await mappingRepo.getMappingsByConcept('C1');
      expect(cMappings.length, equals(1));
      expect(cMappings.first.questionId, equals('Q100'));
    });
  });
}
