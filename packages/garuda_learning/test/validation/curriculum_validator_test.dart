import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart' show KnowledgeProductType;
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('CurriculumValidator Tests', () {
    late CurriculumValidator validator;

    setUp(() {
      validator = CurriculumValidator();
    });

    test('Valid seed framework passes validation with zero errors', () {
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final result = validator.validate(framework);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.validatedObjectiveCount, equals(3));
      expect(result.validatedReferenceCount, equals(5));
      expect(result.validatedPrerequisiteCount, equals(2));
    });

    test('Rejects non-existent prerequisite objective reference', () {
      final framework = CurriculumFramework(
        id: 'fw_invalid_prereq',
        title: 'Invalid Prereq Framework',
        description: 'Testing dangling prereq rejection.',
        version: CurriculumVersion(
          version: '1.0.0',
          effectiveDate: '2026-01-01',
          provenance: 'Test',
        ),
        provenance: 'Test',
        domains: [
          CurriculumDomain(
            id: 'domain_1',
            title: 'Domain 1',
            description: 'Desc',
            provenance: 'Test',
            units: [
              CurriculumUnit(
                id: 'unit_1',
                domainId: 'domain_1',
                title: 'Unit 1',
                description: 'Desc',
                provenance: 'Test',
                objectives: [
                  LearningObjective(
                    id: 'lo_bad',
                    unitId: 'unit_1',
                    title: 'Bad Prereq Obj',
                    description: 'Desc',
                    provenance: 'Test',
                    prerequisites: [
                      PrerequisiteRelationship(
                        prerequisiteObjectiveId: 'lo_non_existent',
                        provenance: 'Test Prereq Provenance',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final result = validator.validate(framework);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('non-existent prerequisite')),
          isTrue);
    });

    test('Rejects self-referential prerequisite', () {
      final framework = CurriculumFramework(
        id: 'fw_self_loop',
        title: 'Self Loop Framework',
        description: 'Testing self loop rejection.',
        version: CurriculumVersion(
          version: '1.0.0',
          effectiveDate: '2026-01-01',
          provenance: 'Test',
        ),
        provenance: 'Test',
        domains: [
          CurriculumDomain(
            id: 'domain_1',
            title: 'Domain 1',
            description: 'Desc',
            provenance: 'Test',
            units: [
              CurriculumUnit(
                id: 'unit_1',
                domainId: 'domain_1',
                title: 'Unit 1',
                description: 'Desc',
                provenance: 'Test',
                objectives: [
                  LearningObjective(
                    id: 'lo_self',
                    unitId: 'unit_1',
                    title: 'Self Prereq Obj',
                    description: 'Desc',
                    provenance: 'Test',
                    prerequisites: [
                      PrerequisiteRelationship(
                        prerequisiteObjectiveId: 'lo_self',
                        provenance: 'Self Loop Provenance',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final result = validator.validate(framework);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('self-referential')), isTrue);
    });

    test('Rejects cyclic prerequisite dependency (A -> B -> A)', () {
      final framework = CurriculumFramework(
        id: 'fw_cycle',
        title: 'Cycle Framework',
        description: 'Testing cycle detection.',
        version: CurriculumVersion(
          version: '1.0.0',
          effectiveDate: '2026-01-01',
          provenance: 'Test',
        ),
        provenance: 'Test',
        domains: [
          CurriculumDomain(
            id: 'domain_1',
            title: 'Domain 1',
            description: 'Desc',
            provenance: 'Test',
            units: [
              CurriculumUnit(
                id: 'unit_1',
                domainId: 'domain_1',
                title: 'Unit 1',
                description: 'Desc',
                provenance: 'Test',
                objectives: [
                  LearningObjective(
                    id: 'lo_a',
                    unitId: 'unit_1',
                    title: 'Obj A',
                    description: 'Desc',
                    provenance: 'Test',
                    prerequisites: [
                      PrerequisiteRelationship(
                        prerequisiteObjectiveId: 'lo_b',
                        provenance: 'A depends on B',
                      ),
                    ],
                  ),
                  LearningObjective(
                    id: 'lo_b',
                    unitId: 'unit_1',
                    title: 'Obj B',
                    description: 'Desc',
                    provenance: 'Test',
                    prerequisites: [
                      PrerequisiteRelationship(
                        prerequisiteObjectiveId: 'lo_a',
                        provenance: 'B depends on A',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final result = validator.validate(framework);

      expect(result.isValid, isFalse);
      expect(
          result.errors
              .any((e) => e.contains('Cyclic prerequisite dependency')),
          isTrue);
    });

    test('Rejects missing mandatory product in StaticMasteryCriteria', () {
      final framework = CurriculumFramework(
        id: 'fw_missing_mandatory',
        title: 'Missing Mandatory Product Framework',
        description: 'Testing mandatory product validation.',
        version: CurriculumVersion(
          version: '1.0.0',
          effectiveDate: '2026-01-01',
          provenance: 'Test',
        ),
        provenance: 'Test',
        domains: [
          CurriculumDomain(
            id: 'domain_1',
            title: 'Domain 1',
            description: 'Desc',
            provenance: 'Test',
            units: [
              CurriculumUnit(
                id: 'unit_1',
                domainId: 'domain_1',
                title: 'Unit 1',
                description: 'Desc',
                provenance: 'Test',
                objectives: [
                  LearningObjective(
                    id: 'lo_mandatory',
                    unitId: 'unit_1',
                    title: 'Mandatory Obj',
                    description: 'Desc',
                    provenance: 'Test',
                    masteryCriteria: const StaticMasteryCriteria(
                      minRequiredProducts: 1,
                      mandatoryProductIds: ['missing_product_id'],
                    ),
                    supportedProducts: [
                      KnowledgeProductMapping(
                        productType: KnowledgeProductType.topic,
                        productId: 'topic_different',
                        title: 'Different Topic',
                        provenance: 'P14 Topic Corpus',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final result = validator.validate(framework);

      expect(result.isValid, isFalse);
      expect(
          result.errors
              .any((e) => e.contains('mandatory product "missing_product_id"')),
          isTrue);
    });
  });
}
