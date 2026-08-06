import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('KnowledgeAnalyticsEngine', () {
    late KnowledgeRepository repo;
    late KnowledgeAnalyticsEngine analyticsEngine;

    setUp(() async {
      repo = InMemoryKnowledgeRepository();
      analyticsEngine = KnowledgeAnalyticsEngine(repo);

      final o1 = KnowledgeObject(
        id: const KnowledgeObjectId('O1'),
        type: KnowledgeObjectType.constitutionArticle,
        title: 'Article 19',
        content: 'Protection of certain rights regarding freedom of speech',
        sources: [const KnowledgeSource(sourceId: 'SRC-1', title: 'Bare Act')],
        relationships: [
          const KnowledgeRelationship(
            id: 'REL-1',
            sourceId: KnowledgeObjectId('O1'),
            targetId: KnowledgeObjectId('O2'),
            type: RelationshipType.relatedTo,
          ),
        ],
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Init',
          author: 'Test',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'Test',
        ),
      );

      final o2 = KnowledgeObject(
        id: const KnowledgeObjectId('O2'),
        type: KnowledgeObjectType.doctrine,
        title: 'Doctrine of Severability',
        content: 'If an offending provision can be severed...',
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Init',
          author: 'Test',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'Test',
        ),
      );

      await repo.bulkImport([o1, o2]);
    });

    test('Generates comprehensive analytics metrics report', () async {
      final report = await analyticsEngine.generateReport();

      expect(report.totalObjects, equals(2));
      expect(report.totalRelationships, equals(1));
      expect(report.evidenceBackedCount, equals(1));
      expect(report.evidenceCoveragePercentage, equals(50.0));
      expect(report.orphanObjectsCount, equals(0)); // O2 is target in REL-1
      expect(report.brokenReferencesCount, equals(0));
    });
  });
}
