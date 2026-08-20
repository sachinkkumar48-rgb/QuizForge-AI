library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_cache_repository.dart';
import '../data/ai_config_repository.dart';
import '../data/ai_conversation_repository.dart';
import '../data/ai_flashcard_repository.dart';
import '../domain/entities/ai_reading_models.dart';
import '../domain/entities/ai_reading_task.dart';
import '../services/ai_reading_service.dart';
import 'reader_providers.dart';

/// Repository for AI assistant configuration.
final aiConfigRepositoryProvider = Provider<AIConfigRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AIConfigRepository(storage);
});

/// Repository for AI response caching.
final aiCacheRepositoryProvider = Provider<AICacheRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AICacheRepository(storage);
});

/// Repository for document-scoped AI conversations.
final aiConversationRepositoryProvider =
    Provider<AIConversationRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AIConversationRepository(storage);
});

/// Repository for AI-generated flashcards.
final aiFlashcardRepositoryProvider = Provider<AIFlashcardRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AIFlashcardRepository(storage);
});

/// AI Reading Service singleton.
final aiReadingServiceProvider = Provider<AIReadingService>((ref) {
  final configRepo = ref.watch(aiConfigRepositoryProvider);
  final cacheRepo = ref.watch(aiCacheRepositoryProvider);
  final convRepo = ref.watch(aiConversationRepositoryProvider);
  final flashcardRepo = ref.watch(aiFlashcardRepositoryProvider);

  final service = AIReadingService(
    configRepo: configRepo,
    cacheRepo: cacheRepo,
    conversationRepo: convRepo,
    flashcardRepo: flashcardRepo,
  );

  return service;
});

/// Reactive AI configuration state.
final aiConfigStateProvider =
    StateNotifierProvider<AIConfigNotifier, AIConfig>((ref) {
  final service = ref.watch(aiReadingServiceProvider);
  return AIConfigNotifier(service);
});

class AIConfigNotifier extends StateNotifier<AIConfig> {
  final AIReadingService _service;

  AIConfigNotifier(this._service) : super(_service.currentConfig) {
    _load();
  }

  Future<void> _load() async {
    await _service.initialize();
    state = _service.currentConfig;
  }

  Future<void> update(AIConfig config) async {
    await _service.updateConfig(config);
    state = config;
  }
}

/// Available models for currently selected provider.
final aiAvailableModelsProvider =
    FutureProvider.autoDispose<List<AIModelInfo>>((ref) async {
  final service = ref.watch(aiReadingServiceProvider);
  ref.watch(aiConfigStateProvider); // reload when config changes
  return service.listAvailableModels();
});

/// All conversations for a specific document.
final aiConversationsProvider = FutureProvider.autoDispose
    .family<List<AIReadingConversation>, String>((ref, documentId) async {
  final service = ref.watch(aiReadingServiceProvider);
  return service.getConversations(documentId);
});

/// All saved flashcards.
final aiSavedFlashcardsProvider =
    FutureProvider.autoDispose<List<AIFlashcard>>((ref) async {
  final service = ref.watch(aiReadingServiceProvider);
  return service.getFlashcards();
});
