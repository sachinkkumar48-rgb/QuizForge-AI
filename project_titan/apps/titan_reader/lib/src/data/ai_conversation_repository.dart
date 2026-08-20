library;

import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../domain/entities/ai_reading_models.dart';

/// Storage repository for document-scoped AI chat conversations.
class AIConversationRepository {
  final StorageService _storage;

  static const String namespace = 'titan.reader.ai.conversations';

  AIConversationRepository(this._storage);

  static StorageKey _keyForDoc(String documentId) =>
      StorageKey('doc_$documentId', namespace: namespace);

  /// Loads all conversations for a given document.
  Future<List<AIReadingConversation>> loadForDocument(String documentId) async {
    try {
      final raw = await _storage.read<String>(_keyForDoc(documentId));
      if (raw == null || raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, Object?>>()
            .map(AIReadingConversation.fromJson)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Saves or updates a conversation.
  Future<void> saveConversation(AIReadingConversation conversation) async {
    final existing = await loadForDocument(conversation.documentId);
    final updated = <AIReadingConversation>[
      conversation,
      ...existing.where((c) => c.id != conversation.id),
    ];
    final payload = jsonEncode(updated.map((c) => c.toJson()).toList());
    await _storage.write<String>(_keyForDoc(conversation.documentId), payload);
  }

  /// Deletes a specific conversation by ID.
  Future<void> deleteConversation(
      String documentId, String conversationId) async {
    final existing = await loadForDocument(documentId);
    final filtered = existing.where((c) => c.id != conversationId).toList();
    final payload = jsonEncode(filtered.map((c) => c.toJson()).toList());
    await _storage.write<String>(_keyForDoc(documentId), payload);
  }

  /// Clears all conversations for a document (e.g. on document deletion).
  Future<void> clearDocument(String documentId) async {
    await _storage.delete(_keyForDoc(documentId));
  }
}
