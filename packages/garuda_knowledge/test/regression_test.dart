import 'package:garuda_knowledge/garuda_knowledge.dart';
import 'package:test/test.dart';

void main() {
  group('Cross-Package Regression & Analytics Verification', () {
    late KnowledgeQueryEngine engine;

    setUp(() {
      engine = KnowledgeQueryEngine();

      final constitutionObj = KnowledgeObject(
        id: const KnowledgeObjectId('const-1'),
        type: KnowledgeObjectType.constitutionArticle,
        title: 'Article 14 - Right to Equality',
        content: 'Equality before law and equal protection of laws.',
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Init',
          author: 'System',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'garuda_constitution',
          customAttributes: {'package_origin': 'garuda_constitution'},
        ),
      );

      final caseLawObj = KnowledgeObject(
        id: const KnowledgeObjectId('case-1'),
        type: KnowledgeObjectType.caseLaw,
        title: 'E.P. Royappa v. State of Tamil Nadu',
        content: 'Equality is a dynamic concept with many aspects and dimensions.',
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Init',
          author: 'System',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'garuda_case_law',
          customAttributes: {'package_origin': 'garuda_case_law'},
        ),
      );

      engine.indexer.indexBatch([constitutionObj, caseLawObj]);
    });

    test('Searches across multiple package origins seamlessly', () async {
      final res = await engine.searchByConcept('Equality');
      expect(res.hits.length, equals(2));

      final packages = res.hits.map((h) => h.object.metadata.packageOrigin).toSet();
      expect(packages.contains('garuda_constitution'), isTrue);
      expect(packages.contains('garuda_case_law'), isTrue);
    });

    test('Generates complete search analytics report', () async {
      await engine.searchByConcept('Equality');
      final report = engine.analytics.generateReport();

      expect(report['objectsIndexed'], equals(2));
      expect(report['totalSearchesExecuted'], equals(1));
      expect(report.containsKey('averageSearchLatencyMs'), isTrue);
    });
  });
}
