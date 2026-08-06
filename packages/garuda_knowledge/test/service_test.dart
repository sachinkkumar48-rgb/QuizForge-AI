import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('Knowledge Services', () {
    late KnowledgeRepository repo;
    late KnowledgeGraphService graphService;
    late KnowledgeTraversalService traversalService;
    late KnowledgeLookupService lookupService;
    late KnowledgeIntegrityService integrityService;
    late KnowledgeVersionService versionService;

    setUp(() async {
      repo = InMemoryKnowledgeRepository();
      graphService = KnowledgeGraphService(repo);
      traversalService = KnowledgeTraversalService(repo);
      lookupService = KnowledgeLookupService(repo);
      integrityService = KnowledgeIntegrityService(repo);
      versionService = KnowledgeVersionService(repo);

      final n1 = KnowledgeObject(
        id: const KnowledgeObjectId('N1'),
        type: KnowledgeObjectType.concept,
        title: 'Fundamental Rights',
        content: 'Part III of Indian Constitution',
        relationships: [
          const KnowledgeRelationship(
            id: 'R1-2',
            sourceId: KnowledgeObjectId('N1'),
            targetId: KnowledgeObjectId('N2'),
            type: RelationshipType.hasChild,
          ),
        ],
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Init',
          author: 'Admin',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'Admin',
        ),
      );

      final n2 = KnowledgeObject(
        id: const KnowledgeObjectId('N2'),
        type: KnowledgeObjectType.constitutionArticle,
        title: 'Article 21',
        content: 'Right to Life and Personal Liberty',
        relationships: [
          const KnowledgeRelationship(
            id: 'R2-3',
            sourceId: KnowledgeObjectId('N2'),
            targetId: KnowledgeObjectId('N3'),
            type: RelationshipType.interprets,
          ),
        ],
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Init',
          author: 'Admin',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'Admin',
        ),
      );

      final n3 = KnowledgeObject(
        id: const KnowledgeObjectId('N3'),
        type: KnowledgeObjectType.caseLaw,
        title: 'Maneka Gandhi Case',
        content: 'Expanded scope of Article 21',
        sources: [
          const KnowledgeSource(sourceId: 'SRC-1', title: 'AIR 1978 SC 597')
        ],
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Init',
          author: 'Admin',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'Admin',
        ),
      );

      await repo.bulkImport([n1, n2, n3]);
    });

    test('KnowledgeGraphService extracts subgraphs correctly', () async {
      final subgraph = await graphService.extractSubgraph(
        const KnowledgeObjectId('N1'),
        maxDepth: 2,
      );
      expect(subgraph.nodes.length, equals(3));
      expect(subgraph.edges.length, equals(2));
    });

    test('KnowledgeTraversalService finds shortest path', () async {
      final path = await traversalService.findShortestPath(
        const KnowledgeObjectId('N1'),
        const KnowledgeObjectId('N3'),
      );
      expect(path, isNotNull);
      expect(path!.nodes.length, equals(3));
      expect(path.nodes.first.value, equals('N1'));
      expect(path.nodes.last.value, equals('N3'));
    });

    test('KnowledgeLookupService returns matching objects', () async {
      final article = await lookupService.getById(const KnowledgeObjectId('N2'));
      expect(article, isNotNull);
      expect(article!.title, equals('Article 21'));

      final cases = await lookupService.getByType(KnowledgeObjectType.caseLaw);
      expect(cases.length, equals(1));
      expect(cases.first.title, equals('Maneka Gandhi Case'));
    });

    test('KnowledgeIntegrityService checks base health', () async {
      final report = await integrityService.checkIntegrity();
      expect(report.isValid, isTrue);
    });

    test('KnowledgeVersionService creates new version snapshot', () async {
      final updated = await versionService.createNewVersion(
        const KnowledgeObjectId('N1'),
        updatedContent: 'Part III - Right to Freedom and Equality',
        commitMessage: 'Content revision',
        author: 'Editor',
      );

      expect(updated.currentVersion.versionNumber, equals(2));
      expect(updated.content, contains('Right to Freedom'));

      final history = await versionService.getVersionHistory(
        const KnowledgeObjectId('N1'),
      );
      expect(history.length, equals(2));
    });
  });
}
