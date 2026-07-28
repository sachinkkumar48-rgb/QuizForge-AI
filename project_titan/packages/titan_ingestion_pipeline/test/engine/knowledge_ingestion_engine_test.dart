import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_search/titan_search.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('KnowledgeIngestionEngine Integration Tests', () {
    late KnowledgeIngestionEngine engine;
    late KnowledgeRepository repository;
    late SearchRepository searchRepository;
    late KnowledgeGraphRepository graphRepository;

    setUp(() async {
      final storage = InMemoryStorageService();
      await storage.initialize();
      repository = KnowledgeRepositoryImpl(storageService: storage);
      searchRepository = SearchRepositoryImpl();
      graphRepository = KnowledgeGraphRepositoryImpl();

      engine = KnowledgeIngestionEngine(
        repository: repository,
        searchRepository: searchRepository,
        graphRepository: graphRepository,
      );
    });

    test(
        'Full End-to-End processing of Markdown document into Canonical KnowledgeObject',
        () async {
      final input = RawDocumentInput(
        id: 'doc_polity_01',
        fileName: 'polity_chapter1.md',
        sourceType: IngestionSourceType.markdown,
        rawTextContent: '''
Course: Indian Polity
Module 1: Constitutional Framework
Chapter 1: Historical Background
# Regulating Act of 1773
Page 1 of 100
ALL RIGHTS RESERVED

The Regulating Act of 1773 was passed by the British Parliament.
It established the Supreme Court at Fort William, Calcutta in 1774.
Article 21 was not present back then.
"Governor General" is defined as the head of executive administration.
''',
      );

      final result = await engine.process(input);

      // Verify Knowledge Object properties
      expect(result.knowledgeObject.id, equals('doc_polity_01'));
      expect(result.knowledgeObject.title, equals('Regulating Act of 1773'));
      expect(result.knowledgeObject.course, equals('Indian Polity'));
      expect(result.knowledgeObject.module, equals('Constitutional Framework'));
      expect(result.knowledgeObject.chapter, equals('Historical Background'));
      expect(
          result.knowledgeObject.summary, equals('[K2 Placeholder Summary]'));
      expect(result.knowledgeObject.concepts.isNotEmpty, isTrue);
      expect(
          result.knowledgeObject.glossary
              .any((g) => g.term == 'Governor General'),
          isTrue);

      // Verify Validation Result
      expect(result.validationResult.isValid, isTrue);

      // Verify Repository Persistence
      final savedObj = await repository.getKnowledgeObjectById('doc_polity_01');
      expect(savedObj, isNotNull);
      expect(savedObj!.title, equals('Regulating Act of 1773'));

      // Verify titan_search Indexing
      final indexedItems = await searchRepository.getIndexItems();
      expect(indexedItems.any((r) => r.contentId == 'doc_polity_01'), isTrue);

      // Verify titan_knowledge_graph Node & Edge Builder
      expect(result.knowledgeGraph.nodes.values.first.title,
          equals('Regulating Act of 1773'));
      expect(result.searchIndexed, isTrue);
    });
  });
}
