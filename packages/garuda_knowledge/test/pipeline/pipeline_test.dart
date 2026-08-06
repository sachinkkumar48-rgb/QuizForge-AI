import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('KnowledgeRegistrationPipeline 12-Stage Execution', () {
    late KnowledgeRepository repo;
    late KnowledgeCacheManager cacheManager;
    late KnowledgeIndexManager indexManager;
    late KnowledgeAnalyticsEngine analyticsEngine;
    late KnowledgeEventBus eventBus;
    late KnowledgeRollbackManager rollbackManager;
    late KnowledgeAuditTrail auditTrail;
    late KnowledgePipelineMetrics metrics;
    late KnowledgeRegistrationPipeline pipeline;

    setUp(() {
      repo = InMemoryKnowledgeRepository();
      cacheManager = KnowledgeCacheManager();
      indexManager = KnowledgeIndexManager();
      analyticsEngine = KnowledgeAnalyticsEngine(repo);
      eventBus = KnowledgeEventBus();
      rollbackManager = KnowledgeRollbackManager(repo, eventBus);
      auditTrail = KnowledgeAuditTrail();
      metrics = KnowledgePipelineMetrics();

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
    });

    test('Successfully registers valid KnowledgeObject through all 12 stages', () async {
      final obj = KnowledgeObject(
        id: const KnowledgeObjectId('PIPE-001'),
        type: KnowledgeObjectType.constitutionArticle,
        title: 'Article 19',
        content: 'Freedom of Speech',
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Initial extract',
          author: 'Test',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'Test',
        ),
      );

      final result = await pipeline.process(obj, packageName: 'garuda_constitution');

      expect(result.isSuccess, isTrue);
      expect(result.completedStage, equals(12));

      final stored = await repo.findById(const KnowledgeObjectId('PIPE-001'));
      expect(stored, isNotNull);
      expect(cacheManager.getLookup('PIPE-001'), isNotNull);
      expect(auditTrail.records.length, equals(1));
      expect(auditTrail.records.first.result, equals('SUCCESS'));
    });

    test('Fails on invalid structure (Stage 2)', () async {
      final obj = KnowledgeObject(
        id: const KnowledgeObjectId('PIPE-BAD-1'),
        type: KnowledgeObjectType.concept,
        title: '',
        content: '',
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

      final result = await pipeline.process(obj);
      expect(result.isSuccess, isFalse);
      expect(result.completedStage, equals(2));
      expect(metrics.validationFailureCount, equals(1));
    });
  });
}
