import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_constitution/garuda_constitution.dart';

void main() {
  group('ConstitutionValidator Unit & Integrity Tests', () {
    test('Default Seed Repository passes all validation checks without errors', () async {
      final repo = InMemoryConstitutionRepository();
      final result = await ConstitutionValidator.validateRepository(repo);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('Detects duplicate object IDs', () async {
      final duplicatePart = PartTemplate.create(
        partNumber: 'III',
        title: 'Duplicate Part III',
        officialName: 'PART III',
        description: 'Duplicate',
        articlesRange: const ['Art 12'],
      );

      final repo = InMemoryConstitutionRepository(
        parts: [
          ...ConstitutionSeedData.parts,
          duplicatePart,
        ],
      );

      final result = await ConstitutionValidator.validateRepository(repo);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'DUPLICATE_OBJECT_ID'), isTrue);
    });

    test('Detects missing metadata (empty title or description)', () async {
      final invalidPart = PartTemplate.create(
        partNumber: 'EMPTY',
        title: '',
        officialName: 'EMPTY PART',
        description: '',
        articlesRange: const [],
      );

      final repo = InMemoryConstitutionRepository(parts: [invalidPart]);
      final result = await ConstitutionValidator.validateRepository(repo);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code.startsWith('MISSING_METADATA')), isTrue);
    });

    test('Detects broken references to non-existent Parts or Schedules', () async {
      final brokenPart = PartTemplate.create(
        partNumber: 'TEST',
        title: 'Test Part',
        officialName: 'TEST PART',
        description: 'Test',
        articlesRange: const [],
        relatedSchedules: const ['KO-SCHED-999'], // Non-existent schedule
      );

      final repo = InMemoryConstitutionRepository(
        parts: [brokenPart],
      );

      final result = await ConstitutionValidator.validateRepository(repo);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'BROKEN_SCHEDULE_REFERENCE'), isTrue);
    });

    test('Detects invalid cross references', () async {
      final brokenCrossRefPart = PartTemplate.create(
        partNumber: 'XREF',
        title: 'Cross Ref Part',
        officialName: 'XREF PART',
        description: 'Test cross ref',
        articlesRange: const [],
        crossReferences: const ['KO-INVALID-999'],
      );

      final repo = InMemoryConstitutionRepository(parts: [brokenCrossRefPart]);
      final result = await ConstitutionValidator.validateRepository(repo);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'INVALID_CROSS_REFERENCE'), isTrue);
    });
  });
}
