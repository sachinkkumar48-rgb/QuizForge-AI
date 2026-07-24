import '../models/search_index.dart';
import '../models/search_scope.dart';

/// Abstract repository interface for offline-first indexing, search history,
/// and query autocompletion.
abstract class SearchRepository {
  /// Indexes a single content item for semantic search.
  Future<void> indexItem(SearchIndexItem item);

  /// Indexes a batch of content items.
  Future<void> indexBatch(List<SearchIndexItem> items);

  /// Retrieves index items filtered by [scopes].
  Future<List<SearchIndexItem>> getIndexItems({Set<SearchScope>? scopes});

  /// Saves a search query to search history.
  Future<void> saveRecentSearch(String query);

  /// Retrieves recent search history queries.
  Future<List<String>> getRecentSearches({int limit = 10});

  /// Clears recent search history.
  Future<void> clearRecentSearches();

  /// Retrieves auto-completion query suggestions matching [prefix].
  Future<List<String>> getQuerySuggestions(String prefix);

  /// Removes an indexed item by id.
  Future<void> removeIndexedItem(String id);
}
