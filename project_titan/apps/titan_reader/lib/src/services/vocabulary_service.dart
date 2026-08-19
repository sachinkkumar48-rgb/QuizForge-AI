import 'package:flutter/foundation.dart';

import '../data/vocabulary_repository.dart';
import '../domain/entities/vocabulary_word.dart';
import '../domain/word_normalizer.dart';

/// Sort orders available on the vocabulary screen.
enum VocabularySortMode { recent, alphabetical, status }

/// Application service managing the user's saved vocabulary.
///
/// The vocabulary is user-owned data: words survive document deletion and
/// dictionary updates, keep personal notes separate from source-backed
/// definitions and remember where they were encountered.
class VocabularyService {
  VocabularyService({
    required VocabularyRepository repository,
    String Function(String prefix)? idGenerator,
  })  : _repository = repository,
        _idGenerator = idGenerator ?? _defaultIdGenerator;

  final VocabularyRepository _repository;
  final String Function(String prefix) _idGenerator;

  final List<VocabularyWord> _words = [];
  final List<VoidCallback> _listeners = [];
  int _idSequence = 0;
  bool _loaded = false;

  /// Whether [preload] (or [ensureLoaded]) has populated the cache.
  bool get isLoaded => _loaded;

  /// Loads the stored vocabulary into the in-memory cache.
  Future<void> preload() async {
    final stored = List.of(await _repository.loadAll());
    stored.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _words
      ..clear()
      ..addAll(stored);
    _loaded = true;
    _notify();
  }

  /// Loads the vocabulary only when it has not been loaded yet.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await preload();
  }

  /// All words, most recently saved first.
  List<VocabularyWord> get words => List.unmodifiable(_words);

  /// Words in the requested [mode] order.
  List<VocabularyWord> sorted(VocabularySortMode mode) {
    final list = List.of(_words);
    switch (mode) {
      case VocabularySortMode.recent:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case VocabularySortMode.alphabetical:
        list.sort((a, b) => a.normalizedWord.compareTo(b.normalizedWord));
      case VocabularySortMode.status:
        list.sort((a, b) {
          final byStatus = a.status.index.compareTo(b.status.index);
          if (byStatus != 0) return byStatus;
          return a.normalizedWord.compareTo(b.normalizedWord);
        });
    }
    return list;
  }

  /// Words matching [query] in word, personal meaning, personal note or
  /// source document name. Empty query returns all words.
  List<VocabularyWord> search(String query) {
    if (query.trim().isEmpty) return words;
    return _words.where((word) => word.matches(query)).toList();
  }

  /// Finds the word saved for [normalizedWord], if any.
  VocabularyWord? wordForNormalized(String normalizedWord) {
    for (final word in _words) {
      if (word.normalizedWord == normalizedWord) return word;
    }
    return null;
  }

  /// Finds a saved word by [wordId], if any.
  VocabularyWord? wordFor(String wordId) {
    for (final word in _words) {
      if (word.id == wordId) return word;
    }
    return null;
  }

  /// Saves [rawWord] into the vocabulary with its source context.
  ///
  /// Saving the same normalized word twice returns the existing entry
  /// instead of creating a duplicate.
  Future<VocabularyWord> saveWord({
    required String rawWord,
    required DateTime at,
    String? dictionarySourceId,
    String? sourceDocumentId,
    String? sourceDocumentName,
    int? sourcePage,
    String? selectedText,
  }) async {
    final normalized = WordNormalizer.normalizeWord(rawWord);
    final display = normalized ?? rawWord.trim();
    final existing = normalized == null ? null : wordForNormalized(normalized);
    if (existing != null) return existing;
    final word = VocabularyWord(
      id: nextId(),
      word: display,
      normalizedWord: normalized ?? display.toLowerCase(),
      dictionarySourceId: dictionarySourceId,
      sourceDocumentId: sourceDocumentId,
      sourceDocumentName: sourceDocumentName,
      sourcePage: sourcePage,
      selectedText: selectedText,
      createdAt: at,
      updatedAt: at,
    );
    _words.add(word);
    await _persist();
    return word;
  }

  /// Updates the personal meaning/note of the word identified by [wordId].
  /// Returns the updated word, or null when not found.
  Future<VocabularyWord?> updateWord({
    required String wordId,
    required DateTime at,
    String? personalMeaning,
    String? personalNote,
  }) async {
    final index = _words.indexWhere((w) => w.id == wordId);
    if (index < 0) return null;
    final previous = _words[index];
    final updated = previous.copyWith(
      personalMeaning: personalMeaning,
      personalNote: personalNote,
      updatedAt: at,
    );
    if (updated == previous) return previous;
    _words[index] = updated;
    await _persist();
    return updated;
  }

  /// Changes the mastery status of the word identified by [wordId].
  /// Returns the updated word, or null when not found.
  Future<VocabularyWord?> changeStatus({
    required String wordId,
    required VocabularyMasteryStatus status,
    required DateTime at,
  }) async {
    final index = _words.indexWhere((w) => w.id == wordId);
    if (index < 0) return null;
    final previous = _words[index];
    if (previous.status == status) return previous;
    final updated = previous.copyWith(status: status, updatedAt: at);
    _words[index] = updated;
    await _persist();
    return updated;
  }

  /// Removes the word identified by [wordId]. Returns the removed word, or
  /// null when not found.
  Future<VocabularyWord?> removeWord({required String wordId}) async {
    final index = _words.indexWhere((w) => w.id == wordId);
    if (index < 0) return null;
    final removed = _words.removeAt(index);
    await _persist();
    return removed;
  }

  /// Generates a new unique vocabulary word id.
  String nextId() => _idGenerator('vocab_${_idSequence++}');

  void addListener(VoidCallback listener) => _listeners.add(listener);

  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  Future<void> _persist() async {
    await _repository.saveAll(List.unmodifiable(_words));
    _notify();
  }

  void _notify() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  static String _defaultIdGenerator(String seed) =>
      'vocab_${DateTime.now().microsecondsSinceEpoch}_$seed';
}
