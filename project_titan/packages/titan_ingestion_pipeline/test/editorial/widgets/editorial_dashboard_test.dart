import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_search/titan_search.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('EditorialDashboardScreen Widget Tests', () {
    late EditorialWorkflowEngine engine;

    setUp(() async {
      final storage = InMemoryStorageService();
      await storage.initialize();

      engine = EditorialWorkflowEngine(
        repository: EditorialRepositoryImpl(storageService: storage),
        searchRepository: SearchRepositoryImpl(),
        graphRepository: KnowledgeGraphRepositoryImpl(),
      );

      final mockAssets = GeneratedKnowledgeAssets(
        id: 'ast_501',
        sourceKnowledgeObjectId: 'ko_501',
        lessonTitle: 'Union Executive',
        summaries: const SummaryBundle(
            summary30s: '30s',
            summary5m: '5m',
            detailedSummary: 'Detailed Text'),
        questions: const [],
        flashcards: const [],
        revisionNotes: GeneratedRevisionNotes(
            sourceKnowledgeObjectId: 'ko_501',
            onePageNotes: 'N',
            lastMinuteNotes: 'L',
            examNotes: 'E'),
        mindMap: MindMapStructure(
            id: 'm1',
            sourceKnowledgeObjectId: 'ko_501',
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
            sourceKnowledgeObjectId: 'ko_501',
            contextPrompt: 'P',
            faqs: const {},
            misconceptions: const [],
            analogies: const [],
            followUpQuestions: const []),
        qualityReport: KnowledgeQualityReport(
            sourceKnowledgeObjectId: 'ko_501',
            score: 85.0,
            completenessScore: 85.0,
            structureScore: 85.0,
            readabilityScore: 85.0,
            metadataScore: 85.0,
            confidenceScore: 90.0),
      );

      await engine.initializeRecord(
          assets: mockAssets, sourceDocumentId: 'doc_501');
    });

    testWidgets(
        'Renders Material 3 Dashboard header, metrics, chips, and asset tiles',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EditorialDashboardScreen(
          engine: engine,
          currentUserId: 'user_editor_1',
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Editorial & Knowledge Validation Console'),
          findsOneWidget);
      expect(find.text('Union Executive'), findsOneWidget);
      expect(find.text('Review Queue & Status Filters'), findsOneWidget);
      expect(find.byType(FilterChip), findsWidgets);
    });
  });
}
