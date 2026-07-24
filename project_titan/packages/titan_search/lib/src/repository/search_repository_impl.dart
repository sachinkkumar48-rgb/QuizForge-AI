import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../models/search_index.dart';
import '../models/search_scope.dart';
import 'search_repository.dart';

/// Concrete implementation of [SearchRepository] providing offline-first
/// index persistence and search history management.
class SearchRepositoryImpl implements SearchRepository {
  final StorageService? _storageService;
  static const StorageKey _indexKey =
      StorageKey('search_index', namespace: 'search');
  static const StorageKey _historyKey =
      StorageKey('search_history', namespace: 'search');

  final Map<String, SearchIndexItem> _indexMap = {};
  final List<String> _recentSearches = [];

  SearchRepositoryImpl({StorageService? storageService})
      : _storageService = storageService;

  Future<void> _persist() async {
    if (_storageService == null) return;
    try {
      final indexJson =
          jsonEncode(_indexMap.values.map((item) => item.toJson()).toList());
      await _storageService.write<String>(_indexKey, indexJson);

      final historyJson = jsonEncode(_recentSearches);
      await _storageService.write<String>(_historyKey, historyJson);
    } catch (_) {}
  }

  Future<void> _hydrate() async {
    if (_storageService == null) return;
    try {
      final indexJson = await _storageService.read<String>(_indexKey);
      if (indexJson != null && indexJson.isNotEmpty) {
        final List list = jsonDecode(indexJson) as List;
        for (final item in list) {
          final indexItem =
              SearchIndexItem.fromJson(Map<String, dynamic>.from(item as Map));
          _indexMap[indexItem.id] = indexItem;
        }
      }

      final historyJson = await _storageService.read<String>(_historyKey);
      if (historyJson != null && historyJson.isNotEmpty) {
        final List list = jsonDecode(historyJson) as List;
        _recentSearches
          ..clear()
          ..addAll(list.cast<String>());
      }
    } catch (_) {}
  }

  @override
  Future<void> indexItem(SearchIndexItem item) async {
    await _hydrate();
    _indexMap[item.id] = item;
    await _persist();
  }

  @override
  Future<void> indexBatch(List<SearchIndexItem> items) async {
    await _hydrate();
    for (final item in items) {
      _indexMap[item.id] = item;
    }
    await _persist();
  }

  @override
  Future<List<SearchIndexItem>> getIndexItems(
      {Set<SearchScope>? scopes}) async {
    await _hydrate();
    if (scopes == null || scopes.isEmpty) {
      return _indexMap.values.toList();
    }
    return _indexMap.values
        .where((item) => scopes.contains(item.scope))
        .toList();
  }

  @override
  Future<void> saveRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    await _hydrate();
    _recentSearches
        .removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > 30) {
      _recentSearches.removeLast();
    }
    await _persist();
  }

  @override
  Future<List<String>> getRecentSearches({int limit = 10}) async {
    await _hydrate();
    return _recentSearches.take(limit).toList();
  }

  @override
  Future<void> clearRecentSearches() async {
    await _hydrate();
    _recentSearches.clear();
    await _persist();
  }

  @override
  Future<List<String>> getQuerySuggestions(String prefix) async {
    final cleanPrefix = prefix.trim().toLowerCase();
    if (cleanPrefix.isEmpty) return const [];

    await _hydrate();
    final suggestions = <String>{};

    // Check search history first
    for (final h in _recentSearches) {
      if (h.toLowerCase().startsWith(cleanPrefix)) {
        suggestions.add(h);
      }
    }

    // Check titles & tags in index
    for (final item in _indexMap.values) {
      if (item.title.toLowerCase().contains(cleanPrefix)) {
        suggestions.add(item.title);
      }
      for (final tag in item.tags) {
        if (tag.toLowerCase().contains(cleanPrefix)) {
          suggestions.add(tag);
        }
      }
      if (suggestions.length >= 10) break;
    }

    return suggestions.take(10).toList();
  }

  @override
  Future<void> removeIndexedItem(String id) async {
    await _hydrate();
    _indexMap.remove(id);
    await _persist();
  }
}
