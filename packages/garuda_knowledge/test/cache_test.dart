import 'package:garuda_knowledge/garuda_knowledge.dart';
import 'package:test/test.dart';

void main() {
  group('KnowledgeCache Manager & Automatic Invalidation', () {
    late KnowledgeCache cache;
    late KnowledgeQuery query;

    setUp(() {
      cache = KnowledgeCache();
      query = KnowledgeQueryBuilder().query('Article 21').build();
    });

    test('Caches search results and reports cache hit rate correctly', () {
      final mockResult = KnowledgeSearchResult(
        hits: const [],
        totalHits: 0,
        latencyMs: 1.2,
        query: query,
      );

      cache.putQueryResult(query, mockResult);

      final hitResult = cache.getQueryResult(query);
      expect(hitResult, isNotNull);
      expect(hitResult!.isCacheHit, isTrue);
      expect(cache.cacheHitRate, equals(1.0));
    });

    test('Invalidates query cache on pipeline completion trigger', () {
      final mockResult = KnowledgeSearchResult(
        hits: const [],
        totalHits: 0,
        latencyMs: 1.2,
        query: query,
      );

      cache.putQueryResult(query, mockResult);
      expect(cache.totalCachedQueries, equals(1));

      cache.invalidateAll();
      expect(cache.totalCachedQueries, equals(0));
    });
  });
}
