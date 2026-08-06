import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('Package Adapters Data Extraction', () {
    test('ConstitutionPackageAdapter extracts valid objects and capabilities', () async {
      final adapter = ConstitutionPackageAdapter();
      expect(adapter.packageName, equals('garuda_constitution'));
      expect(adapter.capabilities.first.id, equals('cap_constitution_articles'));

      final objs = await adapter.extractObjects();
      expect(objs.length, equals(2));
      expect(objs.first.title, contains('Article 14'));

      final rels = await adapter.extractRelationships();
      expect(rels.length, equals(1));
    });

    test('CaseLawPackageAdapter extracts precedent and evidence links', () async {
      final adapter = CaseLawPackageAdapter();
      final objs = await adapter.extractObjects();
      final evs = await adapter.extractEvidenceReferences();

      expect(objs.first.title, contains('Kesavananda'));
      expect(evs.first.evidenceId, equals('EVD-JUDGMENT-1973'));
    });
  });
}
