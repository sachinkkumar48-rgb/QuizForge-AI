import 'package:flutter_test/flutter_test.dart';
import 'package:titan_storage/titan_storage.dart';
import 'package:titan_search/titan_search.dart';

void main() {
  group('SearchRepositoryImpl Tests', () {
    late SearchRepository repository;
    final now = DateTime.now();

    final item = SearchIndexItem(
      id: 'repo_1',
      contentId: 'c_repo1',
      title: 'Preamble of Constitution',
      content: 'We the people of India...',
      scope: SearchScope.notes,
      tags: const ['polity', 'preamble'],
      timestamp: now,
    );

    setUp(() {
      repository = SearchRepositoryImpl();
    });

    test('Indexes item and retrieves by scope filter', () async {
      await repository.indexItem(item);

      final all = await repository.getIndexItems();
      expect(all.length, 1);

      final filtered =
          await repository.getIndexItems(scopes: {SearchScope.notes});
      expect(filtered.length, 1);

      final emptyScope =
          await repository.getIndexItems(scopes: {SearchScope.pdf});
      expect(emptyScope, isEmpty);
    });

    test('Saves search history and returns recent queries', () async {
      await repository.saveRecentSearch('Polity');
      await repository.saveRecentSearch('Economy');
      await repository.saveRecentSearch('Polity'); // Deduplication check

      final history = await repository.getRecentSearches();
      expect(history.length, 2);
      expect(history.first, 'Polity');

      await repository.clearRecentSearches();
      expect(await repository.getRecentSearches(), isEmpty);
    });

    test('Provides query suggestions based on prefix', () async {
      await repository.indexItem(item);
      await repository.saveRecentSearch('Preamble Notes');

      final suggestions = await repository.getQuerySuggestions('Pre');
      expect(suggestions, contains('Preamble Notes'));
      expect(suggestions, contains('Preamble of Constitution'));
    });

    test('Persists data backed by InMemoryStorageService', () async {
      final storage = InMemoryStorageService();
      await storage.initialize();

      final repo1 = SearchRepositoryImpl(storageService: storage);
      await repo1.indexItem(item);
      await repo1.saveRecentSearch('History');

      final repo2 = SearchRepositoryImpl(storageService: storage);
      final items = await repo2.getIndexItems();
      final history = await repo2.getRecentSearches();

      expect(items.length, 1);
      expect(history.first, 'History');
    });
  });
}
