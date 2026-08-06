import 'package:garuda_knowledge/garuda_knowledge.dart';
import 'package:test/test.dart';

void main() {
  group('KnowledgeRankingEngine Strategy', () {
    late KnowledgeRankingEngine rankingEngine;

    final exactMatchObj = KnowledgeObject(
      id: const KnowledgeObjectId('obj-exact'),
      type: KnowledgeObjectType.constitutionArticle,
      title: 'Fundamental Rights',
      content: 'Detailed description of fundamental rights.',
      currentVersion: KnowledgeVersion(
        versionNumber: 1,
        commitMessage: 'Init',
        author: 'System',
        timestamp: DateTime.now(),
      ),
      metadata: KnowledgeMetadata(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'System',
        customAttributes: {
          'editorial_status': 'verified',
          'year': 2024,
        },
      ),
    );

    final keywordOnlyObj = KnowledgeObject(
      id: const KnowledgeObjectId('obj-keyword'),
      type: KnowledgeObjectType.constitutionArticle,
      title: 'Article 14 Overview',
      content: 'Mentions fundamental rights in content text body.',
      currentVersion: KnowledgeVersion(
        versionNumber: 1,
        commitMessage: 'Init',
        author: 'System',
        timestamp: DateTime.now(),
      ),
      metadata: KnowledgeMetadata(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'System',
      ),
    );

    setUp(() {
      rankingEngine = KnowledgeRankingEngine();
    });

    test('Ranks exact title match higher than keyword content match', () {
      const query = KnowledgeQuery(rawQuery: 'Fundamental Rights');

      final hit1 = rankingEngine.rank(
        object: exactMatchObj,
        query: query,
        queryTerms: {'fundamental', 'rights'},
      );

      final hit2 = rankingEngine.rank(
        object: keywordOnlyObj,
        query: query,
        queryTerms: {'fundamental', 'rights'},
      );

      expect(hit1.score, greaterThan(hit2.score));
      expect(hit1.matchedFields.contains('title_exact'), isTrue);
      expect(hit1.scoreBreakdown.containsKey('exact_match'), isTrue);
    });

    test('Includes recency and editorial status in total score breakdown', () {
      const query = KnowledgeQuery(rawQuery: 'Fundamental Rights');

      final hit = rankingEngine.rank(
        object: exactMatchObj,
        query: query,
        queryTerms: {'fundamental', 'rights'},
      );

      expect(hit.scoreBreakdown['editorial_confidence'], equals(2.0));
      expect(hit.scoreBreakdown['recency'], equals(2.0));
    });
  });
}
