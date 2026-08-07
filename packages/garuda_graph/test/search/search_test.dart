import 'package:garuda_graph/garuda_graph.dart';
import 'package:test/test.dart';

void main() {
  group('KnowledgeGraphSearchEngine Tests', () {
    late KnowledgeGraphRepository repository;
    late KnowledgeGraphSearchEngine searchEngine;
    final now = DateTime.now();

    const nodeArticle = KnowledgeNodeRef(id: 'Art-21', name: 'Article 21', nodeType: NodeType.article);
    const nodeCase = KnowledgeNodeRef(id: 'PuttaswamyCase', name: 'Puttaswamy v Union of India', nodeType: NodeType.caseLaw);
    const nodeEvidence = KnowledgeNodeRef(id: 'EV-SC-01', name: 'Privacy Judgment Evidence', nodeType: NodeType.evidence);

    setUp(() async {
      repository = InMemoryKnowledgeGraphRepository();
      searchEngine = KnowledgeGraphSearchEngine(repository);

      await repository.saveLink(KnowledgeLink(
        id: 'link_art_case',
        sourceObject: nodeCase,
        targetObject: nodeArticle,
        relationshipType: KnowledgeRelationshipType.interprets,
        confidenceScore: 0.95,
        createdAt: now,
        updatedAt: now,
      ));

      await repository.saveLink(KnowledgeLink(
        id: 'link_ev_case',
        sourceObject: nodeEvidence,
        targetObject: nodeCase,
        relationshipType: KnowledgeRelationshipType.references,
        confidenceScore: 0.90,
        createdAt: now,
        updatedAt: now,
      ));
    });

    test('findByArticle should find links targeting Article 21', () async {
      final results = await searchEngine.findByArticle('Art-21');
      expect(results.length, equals(1));
      expect(results.first.id, equals('link_art_case'));
    });

    test('findByCase should find links referencing Puttaswamy', () async {
      final results = await searchEngine.findByCase('Puttaswamy');
      expect(results.length, equals(2));
    });
  });
}
