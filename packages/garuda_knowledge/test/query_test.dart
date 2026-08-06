import 'package:garuda_knowledge/garuda_knowledge.dart';
import 'package:test/test.dart';

void main() {
  group('KnowledgeQueryEngine API', () {
    late KnowledgeQueryEngine engine;

    final art21 = KnowledgeObject(
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
      metadata: KnowledgeMetadata(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'garuda_constitution',
        customAttributes: {
          'article_number': '21',
          'act': 'Constitution of India',
          'package_origin': 'garuda_constitution',
        },
      ),
    );

    final kesavananda = KnowledgeObject(
      id: const KnowledgeObjectId('case-kesavananda'),
      type: KnowledgeObjectType.caseLaw,
      title: 'Kesavananda Bharati v. State of Kerala',
      content: 'Established the Basic Structure Doctrine of the Indian Constitution.',
      summary: 'Basic Structure Doctrine landmark case',
      currentVersion: KnowledgeVersion(
        versionNumber: 1,
        commitMessage: 'Init',
        author: 'System',
        timestamp: DateTime.now(),
      ),
      tags: const [KnowledgeTag('basic-structure'), KnowledgeTag('judiciary')],
      relationships: const [
        KnowledgeRelationship(
          id: 'rel-1',
          sourceId: KnowledgeObjectId('case-kesavananda'),
          targetId: KnowledgeObjectId('const-art-21'),
          type: RelationshipType.references,
        ),
      ],
      metadata: KnowledgeMetadata(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'garuda_case_law',
        customAttributes: {
          'case_name': 'Kesavananda Bharati v. State of Kerala',
          'doctrine': 'Basic Structure',
          'package_origin': 'garuda_case_law',
        },
      ),
    );

    setUp(() {
      engine = KnowledgeQueryEngine();
      engine.indexer.indexBatch([art21, kesavananda]);
    });

    test('searchById returns exact matching object', () async {
      final res = await engine.searchById('const-art-21');
      expect(res.hits.length, equals(1));
      expect(res.hits.first.object.id.value, equals('const-art-21'));
    });

    test('searchByType filters by KnowledgeObjectType', () async {
      final res = await engine.searchByType(KnowledgeObjectType.caseLaw);
      expect(res.hits.length, equals(1));
      expect(res.hits.first.object.title, contains('Kesavananda'));
    });

    test('searchByTag finds tagged objects', () async {
      final res = await engine.searchByTag('liberty');
      expect(res.hits.length, equals(1));
      expect(res.hits.first.object.id.value, equals('const-art-21'));
    });

    test('searchByArticle finds constitutional article', () async {
      final res = await engine.searchByArticle('21');
      expect(res.hits.length, equals(1));
      expect(res.hits.first.object.id.value, equals('const-art-21'));
    });

    test('searchByCase finds legal precedent by case name', () async {
      final res = await engine.searchByCase('Kesavananda');
      expect(res.hits.length, equals(1));
      expect(res.hits.first.object.id.value, equals('case-kesavananda'));
    });

    test('searchByRelationship finds objects by relationship type & targetId', () async {
      final res = await engine.searchByRelationship(
        RelationshipType.references,
        targetId: 'const-art-21',
      );
      expect(res.hits.length, equals(1));
      expect(res.hits.first.object.id.value, equals('case-kesavananda'));
    });

    test('searchByConcept searches across all packages', () async {
      final res = await engine.searchByConcept('Basic Structure');
      expect(res.hits.isNotEmpty, isTrue);
      expect(res.hits.first.object.id.value, equals('case-kesavananda'));
    });

    test('QueryBuilder creates fluent custom search query', () async {
      final q = KnowledgeQueryBuilder()
          .query('Liberty')
          .minScore(0.1)
          .limit(10)
          .build();

      final res = await engine.search(q);
      expect(res.hits.isNotEmpty, isTrue);
      expect(res.hits.first.object.content, contains('liberty'));
    });
  });
}
