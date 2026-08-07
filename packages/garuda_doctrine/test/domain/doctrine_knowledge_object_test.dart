import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart';

void main() {
  group('DoctrineKnowledgeObject Entity & Serialization Tests', () {
    test('Creation of DoctrineKnowledgeObject holds all required fields', () {
      final basicStructure = ConstitutionalDoctrinesPhase1.doctrines.firstWhere((d) => d.doctrineId == 'BASIC_STRUCTURE');

      expect(basicStructure.objectId, equals('KO-DOC-BASIC-STRUCTURE'));
      expect(basicStructure.name, equals('Basic Structure Doctrine'));
      expect(basicStructure.category, equals(DoctrineCategory.amendingPower));
      expect(basicStructure.originatingCase, contains('Kesavananda Bharati'));
      expect(basicStructure.officialDefinition, isNotEmpty);
      expect(basicStructure.relatedArticles, contains('368'));
      expect(basicStructure.pyqIds, isNotEmpty);
    });

    test('DoctrineKnowledgeObject toJson and fromJson round-trip preserves payload', () {
      final eclipse = ConstitutionalDoctrinesPhase1.doctrines.firstWhere((d) => d.doctrineId == 'ECLIPSE');
      final json = eclipse.toJson();
      final restored = DoctrineKnowledgeObject.fromJson(json);

      expect(restored.objectId, equals(eclipse.objectId));
      expect(restored.name, equals(eclipse.name));
      expect(restored.officialDefinition, equals(eclipse.officialDefinition));
      expect(restored.landmarkCases, equals(eclipse.landmarkCases));
      expect(restored.relatedArticles, equals(eclipse.relatedArticles));
    });
  });
}
