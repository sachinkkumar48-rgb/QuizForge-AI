import 'package:flutter_test/flutter_test.dart';
import 'package:titan_search/titan_search.dart';

void main() {
  group('Search Use Cases Tests', () {
    late SearchRepository repository;
    final now = DateTime.now();

    final item = SearchIndexItem(
      id: 'uc_idx_1',
      contentId: 'uc_c1',
      title: 'Supreme Court Judgments',
      content: 'Landmark cases on basic structure doctrine.',
      scope: SearchScope.pyqs,
      tags: const ['judiciary', 'polity'],
      timestamp: now,
    );

    setUp(() {
      repository = SearchRepositoryImpl();
    });

    test('IndexContentUseCase indexes item and removes item', () async {
      final indexUseCase = IndexContentUseCase(repository);
      await indexUseCase.indexItem(item);

      final items = await repository.getIndexItems();
      expect(items.length, 1);

      await indexUseCase.removeItem('uc_idx_1');
      expect(await repository.getIndexItems(), isEmpty);
    });

    test('SearchUseCase executes search and saves query history', () async {
      await repository.indexItem(item);
      final searchUseCase = SearchUseCase(repository: repository);

      final query = SearchQuery(rawQuery: 'Supreme Court');
      final results = await searchUseCase.execute(query: query);

      expect(results.isNotEmpty, isTrue);
      expect(results.first.title, 'Supreme Court Judgments');

      final history = await repository.getRecentSearches();
      expect(history, contains('Supreme Court'));
    });

    test('SuggestQueryUseCase returns autocompletion suggestions', () async {
      await repository.indexItem(item);
      final suggestUseCase = SuggestQueryUseCase(repository);

      final suggestions = await suggestUseCase.execute('Sup');
      expect(suggestions, contains('Supreme Court Judgments'));
    });

    test('RecentSearchesUseCase retrieves and clears search history', () async {
      await repository.saveRecentSearch('Article 370');
      final recentUseCase = RecentSearchesUseCase(repository);

      var history = await recentUseCase.getRecent();
      expect(history, contains('Article 370'));

      await recentUseCase.clearHistory();
      history = await recentUseCase.getRecent();
      expect(history, isEmpty);
    });
  });
}
