library;

import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../domain/ai_reading_prompt_builder.dart';
import '../domain/entities/ai_reading_models.dart';
import '../domain/entities/ai_reading_task.dart';

/// Storage repository for caching deterministic AI reading responses.
class AICacheRepository {
  final StorageService _storage;

  static const String namespace = 'titan.reader.ai.cache';

  AICacheRepository(this._storage);

  /// Computes a deterministic cache key.
  static String keyFor({
    required String providerId,
    required String modelId,
    required AIReadingTask task,
    required String text,
    String? question,
    String? language,
  }) {
    final combined = StringBuffer()
      ..write(providerId)
      ..write(':')
      ..write(modelId)
      ..write(':')
      ..write(task.name)
      ..write(':')
      ..write(language ?? 'en')
      ..write(':')
      ..write(question ?? '')
      ..write(':')
      ..write(AIReadingPromptBuilder.version)
      ..write(':')
      ..write(text);
    final hash = _djb2(combined.toString());
    return 'ai_$hash';
  }

  /// Loads cached response, returns null if absent or corrupted.
  Future<AIReadingResponse?> load(String key) async {
    try {
      final storageKey = StorageKey(key, namespace: namespace);
      final raw = await _storage.read<String>(storageKey);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return AIReadingResponse.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  /// Stores an AI response in cache.
  Future<void> save(String key, AIReadingResponse response) async {
    final storageKey = StorageKey(key, namespace: namespace);
    final payload = jsonEncode(response.toJson());
    await _storage.write<String>(storageKey, payload);
  }

  /// DJB2 string hash for deterministic short cache keys.
  static String _djb2(String input) {
    var hash = 5381;
    final bytes = utf8.encode(input);
    for (final b in bytes) {
      hash = ((hash << 5) + hash + b) & 0x7fffffff;
    }
    return hash.toRadixString(16);
  }
}
