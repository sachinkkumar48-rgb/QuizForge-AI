import '../repository/search_repository.dart';

/// Clean Architecture Use Case for fetching auto-completion query suggestions.
class SuggestQueryUseCase {
  final SearchRepository _repository;

  const SuggestQueryUseCase(this._repository);

  /// Retrieves search suggestions based on user input [prefix].
  Future<List<String>> execute(String prefix) {
    return _repository.getQuerySuggestions(prefix);
  }
}
