import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/knowledge_engine.dart';

void main() {
  group('RelationshipType Enum Tests', () {
    test('contains all required relationship categories', () {
      expect(RelationshipType.values, contains(RelationshipType.relatedTo));
      expect(RelationshipType.values, contains(RelationshipType.explains));
      expect(
          RelationshipType.values, contains(RelationshipType.prerequisiteOf));
      expect(RelationshipType.values, contains(RelationshipType.derivedFrom));
      expect(RelationshipType.values, contains(RelationshipType.appearedIn));
      expect(RelationshipType.values, contains(RelationshipType.references));
      expect(RelationshipType.values, contains(RelationshipType.contradicts));
      expect(RelationshipType.values, contains(RelationshipType.expands));
      expect(RelationshipType.values, contains(RelationshipType.summarizes));
      expect(RelationshipType.values.length, equals(9));
    });

    test('name property returns correct string representation', () {
      expect(RelationshipType.relatedTo.name, equals('relatedTo'));
      expect(RelationshipType.explains.name, equals('explains'));
      expect(RelationshipType.prerequisiteOf.name, equals('prerequisiteOf'));
      expect(RelationshipType.derivedFrom.name, equals('derivedFrom'));
      expect(RelationshipType.appearedIn.name, equals('appearedIn'));
      expect(RelationshipType.references.name, equals('references'));
      expect(RelationshipType.contradicts.name, equals('contradicts'));
      expect(RelationshipType.expands.name, equals('expands'));
      expect(RelationshipType.summarizes.name, equals('summarizes'));
    });
  });
}
