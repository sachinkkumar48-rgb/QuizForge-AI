import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_search/titan_search.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('Editorial Quality Score Tests', () {
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

    test('Computes multi-dimensional EditorialQualityScore', () async {
      final mockAssets = GeneratedKnowledgeAssets(
        id: 'ast_401',
        sourceKnowledgeObjectId: 'ko_401',
        lessonTitle: 'Election Commission',
        summaries: const SummaryBundle(
            summary30s: '30s', summary5m: '5m', detailedSummary: 'Detailed'),
        questions: const [],
        flashcards: const [],
        revisionNotes: GeneratedRevisionNotes(
            sourceKnowledgeObjectId: 'ko_401',
            onePageNotes: 'N',
            lastMinuteNotes: 'L',
            examNotes: 'E'),
        mindMap: MindMapStructure(
            id: 'm1',
            sourceKnowledgeObjectId: 'ko_401',
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
            sourceKnowledgeObjectId: 'ko_401',
            contextPrompt: 'P',
            faqs: const {},
            misconceptions: const [],
            analogies: const [],
            followUpQuestions: const []),
        qualityReport: KnowledgeQualityReport(
            sourceKnowledgeObjectId: 'ko_401',
            score: 88.0,
            completenessScore: 90.0,
            structureScore: 85.0,
            readabilityScore: 88.0,
            metadataScore: 90.0,
            confidenceScore: 92.0),
      );

      final rec = await engine.initializeRecord(
          assets: mockAssets, sourceDocumentId: 'doc_401');
      expect(rec.qualityScore.overallScore, greaterThan(70.0));
      expect(rec.qualityScore.overallScore, lessThanOrEqualTo(100.0));
    });
  });
}
