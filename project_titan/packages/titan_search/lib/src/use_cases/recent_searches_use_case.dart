import '../repository/search_repository.dart';

/// Clean Architecture Use Case for managing recent search history.
class RecentSearchesUseCase {
  final SearchRepository _repository;

  const RecentSearchesUseCase(this._repository);

  /// Retrieves recent search history queries.
  Future<List<String>> getRecent({int limit = 10}) {
    return _repository.getRecentSearches(limit: limit);
  }

  /// Clears recent search history.
  Future<void> clearHistory() {
    return _repository.clearRecentSearches();
  }
}
