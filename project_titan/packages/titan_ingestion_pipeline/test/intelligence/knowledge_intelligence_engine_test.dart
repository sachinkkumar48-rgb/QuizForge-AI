import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_search/titan_search.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('KnowledgeIntelligenceEngine Integration Tests (K3)', () {
    late KnowledgeIntelligenceEngine engine;
    late GeneratedAssetsRepository assetsRepository;
    late SearchRepository searchRepository;
    late KnowledgeGraphRepository graphRepository;

    setUp(() async {
      final storage = InMemoryStorageService();
      await storage.initialize();

      assetsRepository = GeneratedAssetsRepositoryImpl(storageService: storage);
      searchRepository = SearchRepositoryImpl();
      graphRepository = KnowledgeGraphRepositoryImpl();

      engine = KnowledgeIntelligenceEngine(
        assetsRepository: assetsRepository,
        searchRepository: searchRepository,
        graphRepository: graphRepository,
      );
    });

    test(
        'Consumes ONLY KnowledgeObject to produce complete multi-format learning assets',
        () async {
      final knowledgeObj = KnowledgeObject(
        id: 'ko_polity_100',
        title: 'Preamble to the Constitution',
        source: 'preamble_source.md',
        language: 'en',
        difficulty: 'medium',
        concepts: [
          KnowledgeConcept(
              id: 'c1',
              name: 'Sovereign',
              type: ConceptType.terminology,
              description: 'Independent authority'),
          KnowledgeConcept(
              id: 'c2',
              name: 'Socialist',
              type: ConceptType.terminology,
              description: 'Welfare state model'),
        ],
        glossary: [
          GlossaryItem(
              term: 'Secular', definition: 'Equal respect for all religions'),
        ],
        contentBlocks: const [
          ParagraphBlock(
              id: 'b1',
              text: 'We the people of India having solemnly resolved...'),
        ],
      );

      final assets = await engine.process(knowledgeObj);

      // Verify Output Structure
      expect(assets.id, equals('assets_ko_polity_100'));
      expect(assets.sourceKnowledgeObjectId, equals('ko_polity_100'));
      expect(assets.lessonTitle, equals('Preamble to the Constitution'));

      // Verify Summaries
      expect(assets.summaries.summary30s.isNotEmpty, isTrue);
      expect(assets.summaries.summary5m.isNotEmpty, isTrue);

      // Verify Questions (8 Question types generated)
      expect(assets.questions.length, equals(8));

      // Verify Flashcards
      expect(assets.flashcards.isNotEmpty, isTrue);
      expect(assets.flashcards.first.sourceKnowledgeObjectId,
          equals('ko_polity_100'));

      // Verify Revision Notes
      expect(assets.revisionNotes.onePageNotes.isNotEmpty, isTrue);

      // Verify Mind Map
      expect(assets.mindMap.branches, contains('Sovereign'));

      // Verify AI Tutor Context
      expect(assets.tutorContext.contextPrompt, contains('TITAN AI Mentor'));
      expect(assets.tutorContext.faqs.isNotEmpty, isTrue);

      // Verify Quality Report
      expect(assets.qualityReport.score, greaterThan(0.0));

      // Verify Storage Persistence
      final savedAssets =
          await assetsRepository.getAssetsById('assets_ko_polity_100');
      expect(savedAssets, isNotNull);

      // Verify titan_search Indexing
      final indexedItems = await searchRepository.getIndexItems();
      expect(indexedItems.any((i) => i.contentId == 'ko_polity_100'), isTrue);

      // Verify titan_knowledge_graph Expansion
      final graph = await graphRepository.getGraph();
      expect(graph.nodes.containsKey('node_sum_assets_ko_polity_100'), isTrue);
    });

    test('Throws ArgumentError if raw file string or invalid input is passed',
        () async {
      expect(
        () async => await engine.process('raw_pdf_content_bytes.pdf'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
