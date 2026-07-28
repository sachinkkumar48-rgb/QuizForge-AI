import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_search/titan_search.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('Asset Provenance & Lineage Tracking Tests', () {
    late EditorialWorkflowEngine engine;

    setUp(() async {
      final storage = InMemoryStorageService();
      await storage.initialize();

      engine = EditorialWorkflowEngine(
        repository: EditorialRepositoryImpl(storageService: storage),
        searchRepository: SearchRepositoryImpl(),
        graphRepository: KnowledgeGraphRepositoryImpl(),
      );
    });

    test(
        'Stores complete provenance details from KnowledgeObject to Publication',
        () async {
      final mockAssets = GeneratedKnowledgeAssets(
        id: 'ast_301',
        sourceKnowledgeObjectId: 'ko_polity_301',
        lessonTitle: 'Supreme Court Jurisdiction',
        summaries: const SummaryBundle(
            summary30s: '30s', summary5m: '5m', detailedSummary: 'Detailed'),
        questions: const [],
        flashcards: const [],
        revisionNotes: GeneratedRevisionNotes(
            sourceKnowledgeObjectId: 'ko_polity_301',
            onePageNotes: 'N',
            lastMinuteNotes: 'L',
            examNotes: 'E'),
        mindMap: MindMapStructure(
            id: 'm1',
            sourceKnowledgeObjectId: 'ko_polity_301',
            title: 'T',
            rootNode: const MindMapNode(id: 'r1', label: 'R', level: 0),
            nodes: const [],
            branches: const []),
        objectivesMetadata: LearningObjectivesMetadata(
            learningObjectives: const [],
            prerequisites: const [],
            learningOutcomes: const [],
            bloomTags: const []),
        tutorContext: AITutorContextAsset(
            sourceKnowledgeObjectId: 'ko_polity_301',
            contextPrompt: 'P',
            faqs: const {},
            misconceptions: const [],
            analogies: const [],
            followUpQuestions: const []),
        qualityReport: KnowledgeQualityReport(
            sourceKnowledgeObjectId: 'ko_polity_301',
            score: 90.0,
            completenessScore: 90.0,
            structureScore: 90.0,
            readabilityScore: 90.0,
            metadataScore: 90.0,
            confidenceScore: 95.0),
      );

      final record = await engine.initializeRecord(
          assets: mockAssets, sourceDocumentId: 'doc_upsc_polity.pdf');
      await engine.submitForReview(record.id, 'editor_alice');
      final published =
          await engine.approveAndPublish(record.id, 'reviewer_bob');

      final prov = published.provenance;
      expect(prov.knowledgeObjectId, equals('ko_polity_301'));
      expect(prov.sourceDocumentId, equals('doc_upsc_polity.pdf'));
      expect(prov.editorId, equals('editor_alice'));
      expect(prov.reviewerId, equals('reviewer_bob'));
      expect(prov.approvalDate, isNotNull);
      expect(prov.publishedVersion, equals('1.0.0'));
    });
  });
}
