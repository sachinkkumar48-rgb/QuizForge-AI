import '../engine/query_parser.dart';
import '../engine/ranking_engine.dart';
import '../models/search_query.dart';
import '../models/search_result.dart';
import '../repository/search_repository.dart';

/// Clean Architecture Use Case for executing a Knowledge Graph-powered semantic search.
class SearchUseCase {
  final SearchRepository _repository;
  final QueryParser _queryParser;
  final RankingEngine _rankingEngine;

  SearchUseCase({
    required SearchRepository repository,
    QueryParser? queryParser,
    RankingEngine? rankingEngine,
  })  : _repository = repository,
        _queryParser = queryParser ?? QueryParser(),
        _rankingEngine = rankingEngine ?? const RankingEngine();

  /// Executes semantic search against indexed content with ranking.
  Future<List<SearchResult>> execute({
    required SearchQuery query,
    Map<String, double>? userTopicWeights,
    Set<String>? recommendedContentIds,
  }) async {
    if (query.rawQuery.trim().isEmpty) {
      return const [];
    }

    // Save query to history
    await _repository.saveRecentSearch(query.rawQuery);

    // Parse & expand query
    final parsedQuery = _queryParser.parse(query);

    // Fetch candidate index items
    final candidates = await _repository.getIndexItems(scopes: query.scopes);

    // Rank candidate items
    final ranked = _rankingEngine.rank(
      candidates: candidates,
      parsedQuery: parsedQuery,
      userTopicWeights: userTopicWeights,
      recommendedContentIds: recommendedContentIds,
    );

    return ranked.take(query.limit).toList();
  }
}
