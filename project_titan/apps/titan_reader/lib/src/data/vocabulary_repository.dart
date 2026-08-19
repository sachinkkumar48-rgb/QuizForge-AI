import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../domain/entities/vocabulary_word.dart';

/// Repository contract for the user's saved vocabulary.
abstract class VocabularyRepository {
  /// Returns every stored vocabulary word.
  Future<List<VocabularyWord>> loadAll();

  /// Replaces the stored vocabulary list.
  Future<void> saveAll(List<VocabularyWord> words);

  /// Deletes the entire vocabulary. No-op when absent.
  Future<void> clear();
}

/// [VocabularyRepository] backed by the shared TITAN [StorageService].
///
/// Vocabulary is user-global (not per-document), so all words live in one
/// entry inside the Reader-specific `titan.reader.vocabulary` namespace.
class StorageVocabularyRepository implements VocabularyRepository {
  /// Storage namespace used for the saved vocabulary.
  static const String namespace = 'titan.reader.vocabulary';

  final StorageService _storage;

  StorageVocabularyRepository(this._storage);

  StorageKey get _key => const StorageKey('all', namespace: namespace);

  @override
  Future<List<VocabularyWord>> loadAll() async {
    final raw = await _storage.read<String>(_key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Vocabulary store is malformed.');
    }
    return decoded
        .whereType<Map<String, Object?>>()
        .map(VocabularyWord.fromJson)
        .toList();
  }

  @override
  Future<void> saveAll(List<VocabularyWord> words) {
    final payload = jsonEncode(words.map((w) => w.toJson()).toList());
    return _storage.write<String>(_key, payload);
  }

  @override
  Future<void> clear() {
    return _storage.delete(_key);
  }
}
