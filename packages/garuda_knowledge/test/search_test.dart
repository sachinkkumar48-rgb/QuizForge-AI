import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('KnowledgeSearchEngine', () {
    late KnowledgeRepository repo;
    late KnowledgeSearchEngine searchEngine;

    setUp(() async {
      repo = InMemoryKnowledgeRepository();
      searchEngine = KnowledgeSearchEngine(repo);

      await repo.create(
        KnowledgeObject(
          id: const KnowledgeObjectId('K1'),
          type: KnowledgeObjectType.constitutionArticle,
          title: 'Article 32 - Constitutional Remedies',
          content: 'Right to move Supreme Court for enforcement of rights.',
          tags: const [KnowledgeTag('Writs'), KnowledgeTag('Judicial Review')],
          currentVersion: KnowledgeVersion(
            versionNumber: 1,
            commitMessage: 'Init',
            author: 'Test',
            timestamp: DateTime.now(),
          ),
          metadata: KnowledgeMetadata(
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'Test',
          ),
        ),
      );

      await repo.create(
        KnowledgeObject(
          id: const KnowledgeObjectId('K2'),
          type: KnowledgeObjectType.pyq,
          title: 'UPSC 2024 Prelims Q15',
          content: 'Which writ is issued to safeguard Personal Liberty?',
          tags: const [KnowledgeTag('Habeas Corpus'), KnowledgeTag('Writs')],
          currentVersion: KnowledgeVersion(
            versionNumber: 1,
            commitMessage: 'Init',
            author: 'Test',
            timestamp: DateTime.now(),
          ),
          metadata: KnowledgeMetadata(
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'Test',
          ),
        ),
      );
    });

    test('Keyword Search ranks relevancy', () async {
      final results = await searchEngine.search(query: 'Supreme Court');
      expect(results.length, equals(1));
      expect(results.first.object.id.value, equals('K1'));
    });

    test('Type and Tag filtered search', () async {
      final writsPyqs = await searchEngine.search(
        type: KnowledgeObjectType.pyq,
        tag: const KnowledgeTag('Writs'),
      );
      expect(writsPyqs.length, equals(1));
      expect(writsPyqs.first.object.title, contains('UPSC 2024'));
    });
  });
}
