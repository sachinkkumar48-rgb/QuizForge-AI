import 'package:garuda_knowledge/garuda_knowledge.dart';
import 'package:test/test.dart';

void main() {
  group('Performance & Memory Efficiency', () {
    late KnowledgeQueryEngine engine;

    setUp(() {
      engine = KnowledgeQueryEngine();
      final batch = <KnowledgeObject>[];

      for (int i = 0; i < 500; i++) {
        batch.add(
          KnowledgeObject(
            id: KnowledgeObjectId('obj-$i'),
            type: KnowledgeObjectType.constitutionArticle,
            title: 'Article $i: Subject Matter and Scope',
            content: 'Content text for article number $i discussing Indian Polity and Governance.',
            summary: 'Summary of article $i',
            currentVersion: KnowledgeVersion(
              versionNumber: 1,
              commitMessage: 'Init',
              author: 'System',
              timestamp: DateTime.now(),
            ),
            tags: [KnowledgeTag('tag-${i % 10}'), const KnowledgeTag('polity')],
            metadata: KnowledgeMetadata(
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              createdBy: 'garuda_constitution',
              customAttributes: {
                'article_number': '$i',
                'package_origin': 'garuda_constitution',
              },
            ),
          ),
        );
      }

      engine.indexer.indexBatch(batch);
    });

    test('Indexes 500 objects and executes sub-10ms search query', () async {
      expect(engine.index.totalIndexedObjects, equals(500));

      final res = await engine.searchByArticle('250');
      expect(res.hits.isNotEmpty, isTrue);
      expect(res.latencyMs, lessThan(100.0)); // High performance requirement
    });
  });
}
