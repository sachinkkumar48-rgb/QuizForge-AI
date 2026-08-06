import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('KnowledgeIngestionService End-to-End Pipeline', () {
    late KnowledgeRepository repository;
    late KnowledgeCacheManager cacheManager;
    late KnowledgeIndexManager indexManager;
    late KnowledgeAnalyticsEngine analyticsEngine;
    late KnowledgeEventBus eventBus;
    late KnowledgeRollbackManager rollbackManager;
    late KnowledgeAuditTrail auditTrail;
    late KnowledgePipelineMetrics metrics;
    late KnowledgeRegistrationPipeline registrationPipeline;
    late KnowledgePublicationService publicationService;
    late KnowledgeIngestionService ingestionService;

    setUp(() {
      repository = InMemoryKnowledgeRepository();
      cacheManager = KnowledgeCacheManager();
      indexManager = KnowledgeIndexManager();
      analyticsEngine = KnowledgeAnalyticsEngine(repository);
      eventBus = KnowledgeEventBus();
      rollbackManager = KnowledgeRollbackManager(repository, eventBus);
      auditTrail = KnowledgeAuditTrail();
      metrics = KnowledgePipelineMetrics();

      registrationPipeline = KnowledgeRegistrationPipeline(
        repository: repository,
        cacheManager: cacheManager,
        indexManager: indexManager,
        analyticsEngine: analyticsEngine,
        eventBus: eventBus,
        rollbackManager: rollbackManager,
        auditTrail: auditTrail,
        metrics: metrics,
      );

      publicationService = KnowledgePublicationService(
        repository: repository,
        auditTrail: auditTrail,
      );

      ingestionService = KnowledgeIngestionService(
        registrationPipeline: registrationPipeline,
        repository: repository,
        indexManager: indexManager,
        publicationService: publicationService,
      );
    });

    test('Successfully ingests single KnowledgeDocument through end-to-end pipeline', () async {
      final document = KnowledgeDocument.create(
        documentId: 'INGEST-001',
        source: const KnowledgeSource(
          sourceId: 'CONSTITUTION_INDIA',
          title: 'Constitution of India',
        ),
        type: KnowledgeDocumentType.constitution,
        title: 'Article 368 - Power of Parliament to Amend Constitution',
        content: 'Notwithstanding anything in this Constitution, Parliament may in exercise of its constituent power amend by way of addition, variation or repeal any provision of this Constitution...',
        publicationDate: DateTime(1950, 1, 26),
        officialUrl: 'https://legislative.gov.in/constitution-of-india',
      );

      final result = await ingestionService.ingestSingle(
        document,
        autoPublicationStatus: KnowledgeEditorialStatus.approved,
      );

      expect(result.isSuccess, isTrue);
      expect(result.createdObject, isNotNull);
      expect(result.createdObject!.id.value, equals('OBJ-INGEST-001'));

      // Verify repository record
      final repoObj = await repository.findById(const KnowledgeObjectId('OBJ-INGEST-001'));
      expect(repoObj, isNotNull);
      expect(repoObj!.title, contains('Article 368'));

      // Verify index searchability
      final keywordIds = indexManager.getIdsByKeyword('parliament');
      expect(keywordIds.contains('OBJ-INGEST-001'), isTrue);

      // Verify editorial queue status
      final pubStatus = publicationService.getStatus('OBJ-INGEST-001');
      expect(pubStatus, equals(KnowledgeEditorialStatus.approved));
    });

    test('Ingests batch of documents and returns complete KnowledgeIngestionReport', () async {
      final doc1 = KnowledgeDocument.create(
        documentId: 'BATCH-001',
        source: const KnowledgeSource(sourceId: 'GAZETTE_GOI', title: 'Gazette'),
        type: KnowledgeDocumentType.gazetteNotification,
        title: 'Digital Personal Data Protection Act 2023',
        content: 'An Act to provide for the processing of digital personal data in a manner that recognises both the right of individuals...',
        publicationDate: DateTime(2023, 8, 11),
      );

      final doc2 = KnowledgeDocument.create(
        documentId: 'BATCH-002',
        source: const KnowledgeSource(sourceId: 'UPSC_QP', title: 'UPSC'),
        type: KnowledgeDocumentType.upscQuestionPaper,
        title: 'UPSC CSE 2023 GS Question 1',
        content: '{"title": "Question 1", "body": "Discuss the significance of the passage of the DPDP Act 2023."}',
        publicationDate: DateTime(2023, 9, 15),
      );

      final report = await ingestionService.ingestBatch([doc1, doc2]);

      expect(report.statistics.totalProcessed, equals(2));
      expect(report.statistics.objectsCreated, equals(2));
      expect(report.statistics.failures, equals(0));
      expect(report.documentResults.length, equals(2));
    });

    test('Rejects duplicate document ingestion in second attempt', () async {
      final doc = KnowledgeDocument.create(
        documentId: 'DUP-TEST-01',
        source: const KnowledgeSource(sourceId: 'PIB_RELEASE', title: 'PIB'),
        type: KnowledgeDocumentType.pibRelease,
        title: 'Cabinet approves National Quantum Mission',
        content: 'The Union Cabinet chaired by Prime Minister approved the National Quantum Mission...',
        publicationDate: DateTime(2023, 4, 19),
      );

      final res1 = await ingestionService.ingestSingle(doc);
      expect(res1.isSuccess, isTrue);

      final res2 = await ingestionService.ingestSingle(doc);
      expect(res2.isSuccess, isFalse);
      expect(res2.message, contains('Validation failed'));
    });
  });
}
