import 'package:garuda_knowledge/garuda_knowledge.dart';
import 'package:test/test.dart';

void main() {
  group('KnowledgeIndex & KnowledgeIndexer', () {
    late KnowledgeIndex index;
    late KnowledgeIndexer indexer;

    final dummyMetadata = KnowledgeMetadata(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'garuda_constitution',
      customAttributes: {
        'subject': 'Polity',
        'topic': 'Fundamental Rights',
        'article_number': '21',
        'act': 'Constitution of India',
        'aliases': ['Right to Life', 'Personal Liberty'],
        'editorial_status': 'published',
        'package_origin': 'garuda_constitution',
      },
    );

    final testObj1 = KnowledgeObject(
      id: const KnowledgeObjectId('const-art-21'),
      type: KnowledgeObjectType.constitutionArticle,
      title: 'Article 21: Protection of Life and Personal Liberty',
      content: 'No person shall be deprived of his life or personal liberty except according to procedure established by law.',
      summary: 'Right to life and liberty',
      currentVersion: KnowledgeVersion(
        versionNumber: 1,
        commitMessage: 'Init',
        author: 'System',
        timestamp: DateTime.now(),
      ),
      tags: const [KnowledgeTag('fundamental-rights'), KnowledgeTag('liberty')],
      metadata: dummyMetadata,
    );

    final testObj2 = KnowledgeObject(
      id: const KnowledgeObjectId('case-maneka-gandhi'),
      type: KnowledgeObjectType.caseLaw,
      title: 'Maneka Gandhi v. Union of India',
      content: 'Expanded Article 21 to include due process of law and personal liberty.',
      summary: 'Landmark Article 21 judgment',
      currentVersion: KnowledgeVersion(
        versionNumber: 1,
        commitMessage: 'Init',
        author: 'System',
        timestamp: DateTime.now(),
      ),
      tags: const [KnowledgeTag('due-process'), KnowledgeTag('liberty')],
      metadata: KnowledgeMetadata(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'garuda_case_law',
        customAttributes: {
          'case_name': 'Maneka Gandhi v. Union of India',
          'article_number': '21',
          'editorial_status': 'verified',
          'package_origin': 'garuda_case_law',
        },
      ),
    );

    setUp(() {
      index = KnowledgeIndex();
      indexer = KnowledgeIndexer(index);
    });

    test('Indexes single object across secondary index fields', () {
      indexer.indexObject(testObj1);

      expect(index.totalIndexedObjects, equals(1));
      expect(index.searchIds('const-art-21').contains('const-art-21'), isTrue);
      expect(index.searchTypes(KnowledgeObjectType.constitutionArticle).contains('const-art-21'), isTrue);
      expect(index.searchTags('liberty').contains('const-art-21'), isTrue);
      expect(index.searchArticles('21').contains('const-art-21'), isTrue);
      expect(index.searchField('subject', 'polity').contains('const-art-21'), isTrue);
      expect(index.searchField('alias', 'Right to Life').contains('const-art-21'), isTrue);
    });

    test('Batch indexing indexes multiple objects efficiently without duplication', () {
      indexer.indexBatch([testObj1, testObj2]);

      expect(index.totalIndexedObjects, equals(2));
      final art21Objs = index.searchArticles('21');
      expect(art21Objs.length, equals(2));
      expect(art21Objs.contains('const-art-21'), isTrue);
      expect(art21Objs.contains('case-maneka-gandhi'), isTrue);
    });

    test('Incremental indexing updates object without duplicate entries', () {
      indexer.indexObject(testObj1);
      expect(index.totalIndexedObjects, equals(1));

      // Re-index updated copy
      final updatedObj = testObj1.copyWith(title: 'Article 21 (Updated Title)');
      indexer.incrementalIndex(updatedObj);

      expect(index.totalIndexedObjects, equals(1));
      expect(index.storedObjects['const-art-21']?.title, equals('Article 21 (Updated Title)'));
    });

    test('Unindexing removes object from all inverted index maps', () {
      indexer.indexBatch([testObj1, testObj2]);
      expect(index.totalIndexedObjects, equals(2));

      indexer.removeObject('const-art-21');
      expect(index.totalIndexedObjects, equals(1));
      expect(index.searchIds('const-art-21').isEmpty, isTrue);
      expect(index.searchArticles('21').contains('const-art-21'), isFalse);
    });
  });
}
