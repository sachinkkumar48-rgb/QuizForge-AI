import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_search/titan_search.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('Editorial Workflow State Machine Tests', () {
    late EditorialWorkflowEngine engine;
    late EditorialRepository repository;
    late SearchRepository searchRepository;
    late KnowledgeGraphRepository graphRepository;

    setUp(() async {
      final storage = InMemoryStorageService();
      await storage.initialize();
      repository = EditorialRepositoryImpl(storageService: storage);
      searchRepository = SearchRepositoryImpl();
      graphRepository = KnowledgeGraphRepositoryImpl();

      engine = EditorialWorkflowEngine(
        repository: repository,
        searchRepository: searchRepository,
        graphRepository: graphRepository,
      );
    });

    test(
        'Transitions from AI Generated -> Needs Review -> Editor Review -> Published',
        () async {
      final mockAssets = GeneratedKnowledgeAssets(
        id: 'ast_101',
        sourceKnowledgeObjectId: 'ko_101',
        lessonTitle: 'Fundamental Duties',
        summaries: const SummaryBundle(
            summary30s: '30s', summary5m: '5m', detailedSummary: 'Detailed'),
        questions: const [],
        flashcards: const [],
        revisionNotes: GeneratedRevisionNotes(
            sourceKnowledgeObjectId: 'ko_101',
            onePageNotes: 'N',
            lastMinuteNotes: 'L',
            examNotes: 'E'),
        mindMap: MindMapStructure(
            id: 'm1',
            sourceKnowledgeObjectId: 'ko_101',
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
            sourceKnowledgeObjectId: 'ko_101',
            contextPrompt: 'P',
            faqs: const {},
            misconceptions: const [],
            analogies: const [],
            followUpQuestions: const []),
        qualityReport: KnowledgeQualityReport(
            sourceKnowledgeObjectId: 'ko_101',
            score: 85.0,
            completenessScore: 85.0,
            structureScore: 85.0,
            readabilityScore: 85.0,
            metadataScore: 85.0,
            confidenceScore: 90.0),
      );

      final rec = await engine.initializeRecord(
          assets: mockAssets, sourceDocumentId: 'doc_101');
      expect(rec.status, equals(EditorialStatus.aiGenerated));

      final submitted = await engine.submitForReview(rec.id, 'editor_1');
      expect(submitted.status, equals(EditorialStatus.needsReview));

      final claimed = await engine.claimForReview(rec.id, 'editor_1');
      expect(claimed.status, equals(EditorialStatus.editorReview));

      final published = await engine.approveAndPublish(rec.id, 'reviewer_1');
      expect(published.status, equals(EditorialStatus.published));
      expect(published.provenance.reviewerId, equals('reviewer_1'));
    });

    test('Rejection moves asset back to Needs Review with comments', () async {
      final mockAssets = GeneratedKnowledgeAssets(
        id: 'ast_102',
        sourceKnowledgeObjectId: 'ko_102',
        lessonTitle: 'Preamble Principles',
        summaries: const SummaryBundle(
            summary30s: '30s', summary5m: '5m', detailedSummary: 'Detailed'),
        questions: const [],
        flashcards: const [],
        revisionNotes: GeneratedRevisionNotes(
            sourceKnowledgeObjectId: 'ko_102',
            onePageNotes: 'N',
            lastMinuteNotes: 'L',
            examNotes: 'E'),
        mindMap: MindMapStructure(
            id: 'm2',
            sourceKnowledgeObjectId: 'ko_102',
            title: 'T',
            rootNode: const MindMapNode(id: 'r2', label: 'R', level: 0),
            nodes: const [],
            branches: const []),
        objectivesMetadata: LearningObjectivesMetadata(
            learningObjectives: const [],
            prerequisites: const [],
            learningOutcomes: const [],
            bloomTags: const []),
        tutorContext: AITutorContextAsset(
            sourceKnowledgeObjectId: 'ko_102',
            contextPrompt: 'P',
            faqs: const {},
            misconceptions: const [],
            analogies: const [],
            followUpQuestions: const []),
        qualityReport: KnowledgeQualityReport(
            sourceKnowledgeObjectId: 'ko_102',
            score: 80.0,
            completenessScore: 80.0,
            structureScore: 80.0,
            readabilityScore: 80.0,
            metadataScore: 80.0,
            confidenceScore: 85.0),
      );

      final rec = await engine.initializeRecord(
          assets: mockAssets, sourceDocumentId: 'doc_102');
      final rejected = await engine.rejectAsset(
          rec.id, 'reviewer_1', 'Factual correction needed in summary.');

      expect(rejected.status, equals(EditorialStatus.needsReview));
      expect(rejected.comments.length, equals(1));
      expect(rejected.comments.first.commentText,
          contains('Factual correction needed'));
    });

    test('Enforces role permissions and prevents unauthorized publication',
        () async {
      final mockAssets = GeneratedKnowledgeAssets(
        id: 'ast_103',
        sourceKnowledgeObjectId: 'ko_103',
        lessonTitle: 'Directive Principles',
        summaries: const SummaryBundle(
            summary30s: '30s', summary5m: '5m', detailedSummary: 'Detailed'),
        questions: const [],
        flashcards: const [],
        revisionNotes: GeneratedRevisionNotes(
            sourceKnowledgeObjectId: 'ko_103',
            onePageNotes: 'N',
            lastMinuteNotes: 'L',
            examNotes: 'E'),
        mindMap: MindMapStructure(
            id: 'm3',
            sourceKnowledgeObjectId: 'ko_103',
            title: 'T',
            rootNode: const MindMapNode(id: 'r3', label: 'R', level: 0),
            nodes: const [],
            branches: const []),
        objectivesMetadata: LearningObjectivesMetadata(
            learningObjectives: const [],
            prerequisites: const [],
            learningOutcomes: const [],
            bloomTags: const []),
        tutorContext: AITutorContextAsset(
            sourceKnowledgeObjectId: 'ko_103',
            contextPrompt: 'P',
            faqs: const {},
            misconceptions: const [],
            analogies: const [],
            followUpQuestions: const []),
        qualityReport: KnowledgeQualityReport(
            sourceKnowledgeObjectId: 'ko_103',
            score: 80.0,
            completenessScore: 80.0,
            structureScore: 80.0,
            readabilityScore: 80.0,
            metadataScore: 80.0,
            confidenceScore: 85.0),
      );

      final rec = await engine.initializeRecord(
          assets: mockAssets, sourceDocumentId: 'doc_103');

      // Author trying to approve & publish must fail
      expect(
        () async => await engine.approveAndPublish(
          rec.id,
          'author_user',
          role: EditorialRole.author,
        ),
        throwsA(isA<StateError>()),
      );

      // Senior reviewer approving must succeed
      final published = await engine.approveAndPublish(
        rec.id,
        'senior_reviewer_1',
        role: EditorialRole.seniorReviewer,
      );
      expect(published.status, equals(EditorialStatus.published));

      // Attempting to submit a published asset for review must fail
      expect(
        () async => await engine.submitForReview(rec.id, 'author_user'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
