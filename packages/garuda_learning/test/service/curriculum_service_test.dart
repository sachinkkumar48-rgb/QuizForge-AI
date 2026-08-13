import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('CurriculumService Integration & Service Tests', () {
    late CurriculumService service;

    setUp(() {
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      service = CurriculumService(framework: framework);
    });

    test('CurriculumService initializes and validates framework successfully',
        () {
      expect(service.versionString, equals('1.0.0'));
      final validationResult = service.validateFramework();
      expect(validationResult.isValid, isTrue);
    });

    test('getObjectiveById resolves objective correctly', () {
      final obj = service.getObjectiveById('lo_basic_structure_doctrine');
      expect(obj, isNotNull);
      expect(obj!.title, contains('Basic Structure Doctrine'));
      expect(obj.unitId, equals('unit_preamble_and_basic_structure'));
    });

    test(
        'getPrerequisiteClosure returns transitive prerequisites in deterministic order',
        () {
      final closure =
          service.getPrerequisiteClosure('lo_article_21_foundations');

      // lo_article_21_foundations depends on lo_basic_structure_doctrine, which depends on lo_preamble_identity
      expect(
          closure.map((o) => o.id).toList(),
          equals([
            'lo_preamble_identity',
            'lo_basic_structure_doctrine',
          ]));
    });

    test(
        'getDeterministicSequence returns full framework sequence respecting explicit prerequisites',
        () {
      final sequence = service.getDeterministicSequence();

      expect(sequence.length, equals(3));
      expect(
          sequence.map((o) => o.id).toList(),
          equals([
            'lo_preamble_identity',
            'lo_basic_structure_doctrine',
            'lo_article_21_foundations',
          ]));
    });

    test('getDeterministicSequence scoped to unit returns unit sequence', () {
      final sequence = service.getDeterministicSequence(
        unitId: 'unit_preamble_and_basic_structure',
      );

      expect(sequence.length, equals(2));
      expect(
          sequence.map((o) => o.id).toList(),
          equals([
            'lo_preamble_identity',
            'lo_basic_structure_doctrine',
          ]));
    });
  });
}
