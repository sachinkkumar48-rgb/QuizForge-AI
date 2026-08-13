import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('CurriculumFramework & Hierarchy Domain Tests', () {
    test(
        'CurriculumFramework organizes domains, units, and objectives correctly',
        () {
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();

      expect(framework.id, equals('titan_upsc_constitutional_law_framework'));
      expect(framework.domains, isNotEmpty);
      expect(framework.version.version, equals('1.0.0'));
      expect(framework.objectiveCount, greaterThanOrEqualTo(3));
      expect(framework.totalMappingCount, greaterThanOrEqualTo(5));
    });

    test('CurriculumFramework lookup maps resolve entities correctly', () {
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();

      final domain = framework.domainMap['domain_constitutional_foundations'];
      expect(domain, isNotNull);
      expect(domain!.title, contains('Constitutional Foundations'));

      final unit = framework.unitMap['unit_preamble_and_basic_structure'];
      expect(unit, isNotNull);
      expect(unit!.domainId, equals('domain_constitutional_foundations'));

      final obj = framework.objectiveMap['lo_basic_structure_doctrine'];
      expect(obj, isNotNull);
      expect(obj!.unitId, equals('unit_preamble_and_basic_structure'));
      expect(obj.prerequisiteIds, contains('lo_preamble_identity'));
    });

    test('CurriculumFramework serialization round-trip (toJson / fromJson)',
        () {
      final original = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final json = original.toJson();
      final reconstituted = CurriculumFramework.fromJson(json);

      expect(reconstituted, equals(original));
      expect(reconstituted.domains.length, equals(original.domains.length));
      expect(reconstituted.objectiveCount, equals(original.objectiveCount));
    });
  });
}
