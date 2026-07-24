import '../models/search_index.dart';
import '../repository/search_repository.dart';

/// Clean Architecture Use Case for indexing single or batched content items.
class IndexContentUseCase {
  final SearchRepository _repository;

  const IndexContentUseCase(this._repository);

  /// Indexes a single content item.
  Future<void> indexItem(SearchIndexItem item) {
    return _repository.indexItem(item);
  }

  /// Indexes a batch of content items.
  Future<void> indexBatch(List<SearchIndexItem> items) {
    return _repository.indexBatch(items);
  }

  /// Removes an item from the index.
  Future<void> removeItem(String id) {
    return _repository.removeIndexedItem(id);
  }
}
