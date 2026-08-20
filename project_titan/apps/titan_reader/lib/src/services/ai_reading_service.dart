library;

import 'dart:async';

import 'package:titan_pdf/titan_pdf.dart';

import '../data/ai_cache_repository.dart';
import '../data/ai_config_repository.dart';
import '../data/ai_conversation_repository.dart';
import '../data/ai_flashcard_repository.dart';
import '../data/ai_reading_provider.dart';
import '../data/ai_retrieval_engine.dart';
import '../data/gemini_reading_provider.dart';
import '../data/mock_ai_reading_provider.dart';
import '../data/ollama_reading_provider.dart';
import '../data/openai_compatible_reading_provider.dart';
import '../domain/entities/ai_reading_models.dart';
import '../domain/entities/ai_reading_task.dart';

/// Central application service orchestrating AI reading assistance, RAG, caching, and chat.
class AIReadingService {
  final AIConfigRepository _configRepo;
  final AICacheRepository _cacheRepo;
  final AIConversationRepository _conversationRepo;
  final AIFlashcardRepository _flashcardRepo;
  final AIRetrievalEngine _retrievalEngine;

  final Map<AIProviderType, AIReadingProvider> _providers;
  AIConfig _config;

  AIReadingService({
    required AIConfigRepository configRepo,
    required AICacheRepository cacheRepo,
    required AIConversationRepository conversationRepo,
    required AIFlashcardRepository flashcardRepo,
    AIRetrievalEngine? retrievalEngine,
    Map<AIProviderType, AIReadingProvider>? providers,
    AIConfig? initialConfig,
  })  : _configRepo = configRepo,
        _cacheRepo = cacheRepo,
        _conversationRepo = conversationRepo,
        _flashcardRepo = flashcardRepo,
        _retrievalEngine = retrievalEngine ?? const AIRetrievalEngine(),
        _config = initialConfig ?? const AIConfig(),
        _providers = providers ??
            {
              AIProviderType.localOllama: OllamaReadingProvider(),
              AIProviderType.openAICompatible:
                  OpenAICompatibleReadingProvider(),
              AIProviderType.gemini: GeminiReadingProvider(),
              AIProviderType.mock: MockAIReadingProvider(),
            };

  AIConfig get currentConfig => _config;

  /// Loads configuration from persistent storage.
  Future<void> initialize() async {
    _config = await _configRepo.loadConfig();
  }

  /// Updates and persists AI configuration.
  Future<void> updateConfig(AIConfig newConfig) async {
    _config = newConfig;
    await _configRepo.saveConfig(newConfig);
  }

  /// Returns the active AI provider instance.
  AIReadingProvider get activeProvider =>
      _providers[_config.providerType] ??
      _providers[AIProviderType.localOllama]!;

  /// Discovers available models for the current provider.
  Future<List<AIModelInfo>> listAvailableModels() async {
    return activeProvider.listModels();
  }

  /// Executes an AI reading task with optional RAG context and response caching.
  Future<AIReadingResponse> processTask(
    AIReadingRequest request, {
    List<PdfChunk> documentChunks = const [],
    AICancellationToken? cancelToken,
    bool useCache = true,
  }) async {
    // 1. Enrich request with RAG chunks if document-level context is required
    var enrichedRequest = request;
    if (request.contextScope == AIContextScope.document &&
        request.contextChunks.isEmpty &&
        documentChunks.isNotEmpty) {
      final query = request.userQuestion ?? request.text;
      final relevant = _retrievalEngine.retrieveRelevantChunks(
        query: query,
        chunks: documentChunks,
      );
      enrichedRequest = AIReadingRequest(
        task: request.task,
        text: request.text,
        contextScope: request.contextScope,
        documentId: request.documentId,
        documentName: request.documentName,
        pageNumber: request.pageNumber,
        contextChunks: relevant,
        summaryLength: request.summaryLength,
        simplifyLevel: request.simplifyLevel,
        userQuestion: request.userQuestion,
        targetLanguage: request.targetLanguage,
        customInstruction: request.customInstruction,
      );
    }

    // 2. Check Cache
    final cacheKey = AICacheRepository.keyFor(
      providerId: activeProvider.providerId,
      modelId: _config.activeModelId,
      task: enrichedRequest.task,
      text: enrichedRequest.text,
      question: enrichedRequest.userQuestion,
      language: enrichedRequest.targetLanguage,
    );

    if (useCache) {
      final cached = await _cacheRepo.load(cacheKey);
      if (cached != null) return cached;
    }

    // 3. Dispatch to Provider
    final response = await activeProvider.generate(
      enrichedRequest,
      config: _config,
      cancelToken: cancelToken,
    );

    // 4. Save to Cache
    if (useCache) {
      await _cacheRepo.save(cacheKey, response);
    }

    // 5. If response produced flashcards, auto-save them
    if (response.flashcards.isNotEmpty) {
      await _flashcardRepo.saveFlashcards(response.flashcards);
    }

    return response;
  }

  /// Streams an AI reading task response.
  Stream<String> streamTask(
    AIReadingRequest request, {
    List<PdfChunk> documentChunks = const [],
    AICancellationToken? cancelToken,
  }) async* {
    var enrichedRequest = request;
    if (request.contextScope == AIContextScope.document &&
        request.contextChunks.isEmpty &&
        documentChunks.isNotEmpty) {
      final query = request.userQuestion ?? request.text;
      final relevant = _retrievalEngine.retrieveRelevantChunks(
        query: query,
        chunks: documentChunks,
      );
      enrichedRequest = AIReadingRequest(
        task: request.task,
        text: request.text,
        contextScope: request.contextScope,
        documentId: request.documentId,
        documentName: request.documentName,
        pageNumber: request.pageNumber,
        contextChunks: relevant,
        summaryLength: request.summaryLength,
        simplifyLevel: request.simplifyLevel,
        userQuestion: request.userQuestion,
        targetLanguage: request.targetLanguage,
        customInstruction: request.customInstruction,
      );
    }

    final stream = activeProvider.generateStream(
      enrichedRequest,
      config: _config,
      cancelToken: cancelToken,
    );

    await for (final chunk in stream) {
      yield chunk;
    }
  }

  // --- Conversations Management ---

  Future<List<AIReadingConversation>> getConversations(String documentId) {
    return _conversationRepo.loadForDocument(documentId);
  }

  Future<AIReadingConversation> createConversation({
    required String documentId,
    required String title,
    String? initialUserMessage,
  }) async {
    final now = DateTime.now();
    final conversation = AIReadingConversation(
      id: 'conv_${now.microsecondsSinceEpoch}',
      documentId: documentId,
      title: title,
      messages: initialUserMessage != null
          ? [
              AIReadingMessage(
                id: 'msg_${now.microsecondsSinceEpoch}',
                content: initialUserMessage,
                isUser: true,
                timestamp: now,
              ),
            ]
          : const [],
      createdAt: now,
      updatedAt: now,
    );
    await _conversationRepo.saveConversation(conversation);
    return conversation;
  }

  Future<void> appendMessage({
    required String documentId,
    required String conversationId,
    required String content,
    required bool isUser,
    List<SourceReference> sources = const [],
  }) async {
    final list = await _conversationRepo.loadForDocument(documentId);
    final target = list.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => AIReadingConversation(
        id: conversationId,
        documentId: documentId,
        title: 'New Chat',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final now = DateTime.now();
    final message = AIReadingMessage(
      id: 'msg_${now.microsecondsSinceEpoch}',
      content: content,
      isUser: isUser,
      timestamp: now,
      sources: sources,
    );

    final updated = AIReadingConversation(
      id: target.id,
      documentId: target.documentId,
      title: target.title,
      messages: [...target.messages, message],
      createdAt: target.createdAt,
      updatedAt: now,
    );

    await _conversationRepo.saveConversation(updated);
  }

  Future<void> deleteConversation(String documentId, String conversationId) {
    return _conversationRepo.deleteConversation(documentId, conversationId);
  }

  // --- Flashcard Management ---

  Future<List<AIFlashcard>> getFlashcards() => _flashcardRepo.loadAll();

  Future<void> saveFlashcards(List<AIFlashcard> flashcards) =>
      _flashcardRepo.saveFlashcards(flashcards);

  Future<void> deleteFlashcard(String flashcardId) =>
      _flashcardRepo.deleteFlashcard(flashcardId);
}
