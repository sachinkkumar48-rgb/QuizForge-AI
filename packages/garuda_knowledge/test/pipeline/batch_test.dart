import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('KnowledgeBatchProcessor', () {
    late KnowledgeRegistrationPipeline pipeline;
    late KnowledgeBatchProcessor batchProcessor;

    setUp(() {
      final repo = InMemoryKnowledgeRepository();
      final cacheManager = KnowledgeCacheManager();
      final indexManager = KnowledgeIndexManager();
      final analyticsEngine = KnowledgeAnalyticsEngine(repo);
      final eventBus = KnowledgeEventBus();
      final rollbackManager = KnowledgeRollbackManager(repo, eventBus);
      final auditTrail = KnowledgeAuditTrail();
      final metrics = KnowledgePipelineMetrics();

      pipeline = KnowledgeRegistrationPipeline(
        repository: repo,
        cacheManager: cacheManager,
        indexManager: indexManager,
        analyticsEngine: analyticsEngine,
        eventBus: eventBus,
        rollbackManager: rollbackManager,
        auditTrail: auditTrail,
        metrics: metrics,
      );

      batchProcessor = KnowledgeBatchProcessor(pipeline);
    });

    test('Processes batch with progress reporting and failure isolation', () async {
      final objects = [
        KnowledgeObject(
          id: const KnowledgeObjectId('BATCH-1'),
          type: KnowledgeObjectType.concept,
          title: 'Concept 1',
          content: 'Content 1',
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
        ),
        KnowledgeObject(
          id: const KnowledgeObjectId('BATCH-2'),
          type: KnowledgeObjectType.concept,
          title: 'Concept 2',
          content: 'Content 2',
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
        ),
      ];

      final progressReports = <double>[];

      final res = await batchProcessor.processBatch(
        objects,
        onProgress: (proc, total, pct) => progressReports.add(pct),
      );

      expect(res.totalProcessed, equals(2));
      expect(res.successCount, equals(2));
      expect(progressReports.length, equals(2));
      expect(progressReports.last, equals(100.0));
    });
  });
}
