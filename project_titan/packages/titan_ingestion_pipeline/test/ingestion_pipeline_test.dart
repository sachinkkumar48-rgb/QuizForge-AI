import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_search/titan_search.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('Ingestion Pipeline Unit Tests', () {
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

    test('process raw text document into canonical KnowledgeObject', () async {
      final input = RawDocumentInput(
        id: 'auth_polity_21',
        fileName: 'article_21.txt',
        sourceType: IngestionSourceType.plainText,
        rawTextContent:
            'Article 21 provides protection of life and personal liberty.',
      );

      final result = await engine.process(input);

      expect(result.knowledgeObject.id, equals('auth_polity_21'));
      expect(
          result.knowledgeObject.summary, equals('[K2 Placeholder Summary]'));
      expect(result.knowledgeObject.concepts.isNotEmpty, isTrue);
      expect(result.knowledgeGraph.nodes.length, greaterThanOrEqualTo(1));
      expect(result.searchIndexed, isTrue);
    });
  });
}
