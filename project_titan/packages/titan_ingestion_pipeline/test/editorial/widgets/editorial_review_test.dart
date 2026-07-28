import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_search/titan_search.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('EditorialReviewScreen Widget Tests', () {
    late EditorialWorkflowEngine engine;
    late EditorialAssetRecord record;

    setUp(() async {
      final storage = InMemoryStorageService();
      await storage.initialize();

      engine = EditorialWorkflowEngine(
        repository: EditorialRepositoryImpl(storageService: storage),
        searchRepository: SearchRepositoryImpl(),
        graphRepository: KnowledgeGraphRepositoryImpl(),
      );

      final mockAssets = GeneratedKnowledgeAssets(
        id: 'ast_601',
        sourceKnowledgeObjectId: 'ko_601',
        lessonTitle: 'State Legislature',
        summaries: const SummaryBundle(
            summary30s: '30s',
            summary5m: '5m',
            detailedSummary: 'Detailed Text for State Leg'),
        questions: const [],
        flashcards: const [],
        revisionNotes: GeneratedRevisionNotes(
            sourceKnowledgeObjectId: 'ko_601',
            onePageNotes: 'N',
            lastMinuteNotes: 'L',
            examNotes: 'E'),
        mindMap: MindMapStructure(
            id: 'm1',
            sourceKnowledgeObjectId: 'ko_601',
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
            sourceKnowledgeObjectId: 'ko_601',
            contextPrompt: 'P',
            faqs: const {},
            misconceptions: const [],
            analogies: const [],
            followUpQuestions: const []),
        qualityReport: KnowledgeQualityReport(
            sourceKnowledgeObjectId: 'ko_601',
            score: 85.0,
            completenessScore: 85.0,
            structureScore: 85.0,
            readabilityScore: 85.0,
            metadataScore: 85.0,
            confidenceScore: 90.0),
      );

      record = await engine.initializeRecord(
          assets: mockAssets, sourceDocumentId: 'doc_601');
    });

    testWidgets('Renders Tabs, Edit fields, Diff view, and Action Buttons',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EditorialReviewScreen(
          record: record,
          engine: engine,
          currentUserId: 'user_editor_1',
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Review: State Legislature'), findsOneWidget);
      expect(find.text('Inline Edit & Diff'), findsOneWidget);
      expect(find.text('9 Asset Breakdown'), findsOneWidget);
      expect(find.text('Quality Validation'), findsOneWidget);
      expect(find.text('Version Control'), findsOneWidget);
      expect(find.text('Provenance & Audit'), findsOneWidget);

      expect(find.text('Approve & Publish'), findsOneWidget);
      expect(find.text('Reject Asset'), findsOneWidget);
    });
  });
}
