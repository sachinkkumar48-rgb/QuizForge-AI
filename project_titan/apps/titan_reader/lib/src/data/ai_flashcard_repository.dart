library;

import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../domain/entities/ai_reading_task.dart';

/// Storage repository for AI-generated study flashcards.
class AIFlashcardRepository {
  final StorageService _storage;

  static const String namespace = 'titan.reader.ai.flashcards';
  static const String key = 'all';

  AIFlashcardRepository(this._storage);

  static StorageKey get _storageKey =>
      const StorageKey(key, namespace: namespace);

  /// Loads all stored flashcards.
  Future<List<AIFlashcard>> loadAll() async {
    try {
      final raw = await _storage.read<String>(_storageKey);
      if (raw == null || raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, Object?>>()
            .map(AIFlashcard.fromJson)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Appends new flashcards to the collection.
  Future<void> saveFlashcards(List<AIFlashcard> flashcards) async {
    final existing = await loadAll();
    final existingIds = existing.map((f) => f.id).toSet();
    final toAdd = flashcards.where((f) => !existingIds.contains(f.id)).toList();
    final combined = [...toAdd, ...existing];
    final payload = jsonEncode(combined.map((f) => f.toJson()).toList());
    await _storage.write<String>(_storageKey, payload);
  }

  /// Deletes a flashcard by ID.
  Future<void> deleteFlashcard(String flashcardId) async {
    final existing = await loadAll();
    final updated = existing.where((f) => f.id != flashcardId).toList();
    final payload = jsonEncode(updated.map((f) => f.toJson()).toList());
    await _storage.write<String>(_storageKey, payload);
  }
}
