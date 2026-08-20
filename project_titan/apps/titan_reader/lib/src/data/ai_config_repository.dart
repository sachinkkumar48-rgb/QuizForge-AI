library;

import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../domain/entities/ai_reading_models.dart';

/// Storage repository for user AI configuration and provider settings.
class AIConfigRepository {
  final StorageService _storage;

  static const String namespace = 'titan.reader.ai.config';
  static const String key = 'settings';

  AIConfigRepository(this._storage);

  static StorageKey get _storageKey =>
      const StorageKey(key, namespace: namespace);

  /// Loads stored configuration, falling back to safe default.
  Future<AIConfig> loadConfig() async {
    try {
      final raw = await _storage.read<String>(_storageKey);
      if (raw == null || raw.trim().isEmpty) return const AIConfig();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return AIConfig.fromJson(decoded);
      }
    } catch (_) {}
    return const AIConfig();
  }

  /// Saves updated configuration.
  Future<void> saveConfig(AIConfig config) async {
    final payload = jsonEncode(config.toJson());
    await _storage.write<String>(_storageKey, payload);
  }
}
