import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('DeterministicSequenceResolver Tests', () {
    late DeterministicSequenceResolver resolver;

    setUp(() {
      resolver = DeterministicSequenceResolver();
    });

    test('Resolves linear prerequisite sequence correctly', () {
      final obj1 = LearningObjective(
        id: 'lo_1',
        unitId: 'u1',
        title: 'Level 1 Obj',
        description: 'First obj',
        sequenceIndex: 1,
        provenance: 'Test',
      );

      final obj2 = LearningObjective(
        id: 'lo_2',
        unitId: 'u1',
        title: 'Level 2 Obj',
        description: 'Second obj',
        sequenceIndex: 2,
        provenance: 'Test',
        prerequisites: [
          PrerequisiteRelationship(
            prerequisiteObjectiveId: 'lo_1',
            provenance: 'Explicit dependency',
          ),
        ],
      );

      final obj3 = LearningObjective(
        id: 'lo_3',
        unitId: 'u1',
        title: 'Level 3 Obj',
        description: 'Third obj',
        sequenceIndex: 3,
        provenance: 'Test',
        prerequisites: [
          PrerequisiteRelationship(
            prerequisiteObjectiveId: 'lo_2',
            provenance: 'Explicit dependency',
          ),
        ],
      );

      // Pass out of order
      final sequence = resolver.resolveSequence([obj3, obj1, obj2]);

      expect(
          sequence.map((o) => o.id).toList(), equals(['lo_1', 'lo_2', 'lo_3']));
    });

    test(
        'Deterministic tie-breaking sorts by sequenceIndex then ID when no prerequisites exist',
        () {
      final objB = LearningObjective(
        id: 'lo_b',
        unitId: 'u1',
        title: 'Obj B',
        description: 'Desc',
        sequenceIndex: 1,
        provenance: 'Test',
      );

      final objA = LearningObjective(
        id: 'lo_a',
        unitId: 'u1',
        title: 'Obj A',
        description: 'Desc',
        sequenceIndex: 1,
        provenance: 'Test',
      );

      final objC = LearningObjective(
        id: 'lo_c',
        unitId: 'u1',
        title: 'Obj C',
        description: 'Desc',
        sequenceIndex: 2,
        provenance: 'Test',
      );

      final sequence1 = resolver.resolveSequence([objC, objB, objA]);
      final sequence2 = resolver.resolveSequence([objA, objC, objB]);

      expect(sequence1, equals(sequence2));
      expect(sequence1.map((o) => o.id).toList(),
          equals(['lo_a', 'lo_b', 'lo_c']));
    });

    test(
        'Throws StateError when cyclic dependency is encountered during sequence resolution',
        () {
      final objA = LearningObjective(
        id: 'lo_a',
        unitId: 'u1',
        title: 'Obj A',
        description: 'Desc',
        provenance: 'Test',
        prerequisites: [
          PrerequisiteRelationship(
            prerequisiteObjectiveId: 'lo_b',
            provenance: 'Test',
          ),
        ],
      );

      final objB = LearningObjective(
        id: 'lo_b',
        unitId: 'u1',
        title: 'Obj B',
        description: 'Desc',
        provenance: 'Test',
        prerequisites: [
          PrerequisiteRelationship(
            prerequisiteObjectiveId: 'lo_a',
            provenance: 'Test',
          ),
        ],
      );

      expect(
        () => resolver.resolveSequence([objA, objB]),
        throwsStateError,
      );
    });

    test('Throws StateError when prerequisite ID is missing from objective set',
        () {
      final objA = LearningObjective(
        id: 'lo_a',
        unitId: 'u1',
        title: 'Obj A',
        description: 'Desc',
        provenance: 'Test',
        prerequisites: [
          PrerequisiteRelationship(
            prerequisiteObjectiveId: 'lo_missing',
            provenance: 'Test',
          ),
        ],
      );

      expect(
        () => resolver.resolveSequence([objA]),
        throwsStateError,
      );
    });
  });
}
