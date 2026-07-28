import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_search/titan_search.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('Editorial Version Control & Rollback Tests', () {
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

    test('Creates new version snapshot on inline edit and allows rollback',
        () async {
      final mockAssets = GeneratedKnowledgeAssets(
        id: 'ast_201',
        sourceKnowledgeObjectId: 'ko_201',
        lessonTitle: 'Original Title v1',
        summaries: const SummaryBundle(
            summary30s: '30s',
            summary5m: '5m',
            detailedSummary: 'Original Detailed Text v1'),
        questions: const [],
        flashcards: const [],
        revisionNotes: GeneratedRevisionNotes(
            sourceKnowledgeObjectId: 'ko_201',
            onePageNotes: 'N',
            lastMinuteNotes: 'L',
            examNotes: 'E'),
        mindMap: MindMapStructure(
            id: 'm1',
            sourceKnowledgeObjectId: 'ko_201',
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
            sourceKnowledgeObjectId: 'ko_201',
            contextPrompt: 'P',
            faqs: const {},
            misconceptions: const [],
            analogies: const [],
            followUpQuestions: const []),
        qualityReport: KnowledgeQualityReport(
            sourceKnowledgeObjectId: 'ko_201',
            score: 85.0,
            completenessScore: 85.0,
            structureScore: 85.0,
            readabilityScore: 85.0,
            metadataScore: 85.0,
            confidenceScore: 90.0),
      );

      final rec = await engine.initializeRecord(
          assets: mockAssets, sourceDocumentId: 'doc_201');

      // Edit Content -> Version 1.1.0
      final edited = await engine.updateContent(
        recordId: rec.id,
        newTitle: 'Edited Title v2',
        newDetailedSummary: 'Edited Detailed Text v2',
        changeSummary: 'Updated definitions',
        editorId: 'editor_42',
      );

      expect(edited.versionHistory.length, equals(2));
      expect(edited.assets.lessonTitle, equals('Edited Title v2'));
      expect(edited.assets.summaries.detailedSummary,
          equals('Edited Detailed Text v2'));

      // Rollback to Initial Version v_1_0_0
      final rolledBack =
          await engine.rollbackToVersion(rec.id, 'v_1_0_0', 'editor_42');

      expect(rolledBack.assets.lessonTitle, equals('Original Title v1'));
      expect(rolledBack.assets.summaries.detailedSummary,
          equals('Original Detailed Text v1'));
      expect(rolledBack.versionHistory.length,
          equals(3)); // Adds a rollback version log entry
    });
  });
}
