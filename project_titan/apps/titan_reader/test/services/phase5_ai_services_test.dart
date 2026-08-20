import 'package:flutter_test/flutter_test.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_reader/src/data/ai_cache_repository.dart';
import 'package:titan_reader/src/data/ai_config_repository.dart';
import 'package:titan_reader/src/data/ai_conversation_repository.dart';
import 'package:titan_reader/src/data/ai_flashcard_repository.dart';
import 'package:titan_reader/src/data/mock_ai_reading_provider.dart';
import 'package:titan_reader/src/domain/entities/ai_reading_models.dart';
import 'package:titan_reader/src/domain/entities/ai_reading_task.dart';
import 'package:titan_reader/src/services/ai_reading_service.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('Phase 5: Repositories & AIReadingService', () {
    late InMemoryStorageService storage;
    late AIConfigRepository configRepo;
    late AICacheRepository cacheRepo;
    late AIConversationRepository convRepo;
    late AIFlashcardRepository flashcardRepo;
    late MockAIReadingProvider mockProvider;
    late AIReadingService service;

    setUp(() async {
      storage = InMemoryStorageService();
      await storage.initialize();
      configRepo = AIConfigRepository(storage);
      cacheRepo = AICacheRepository(storage);
      convRepo = AIConversationRepository(storage);
      flashcardRepo = AIFlashcardRepository(storage);
      mockProvider = MockAIReadingProvider();

      service = AIReadingService(
        configRepo: configRepo,
        cacheRepo: cacheRepo,
        conversationRepo: convRepo,
        flashcardRepo: flashcardRepo,
        providers: {
          AIProviderType.localOllama: mockProvider,
          AIProviderType.mock: mockProvider,
        },
        initialConfig: const AIConfig(providerType: AIProviderType.mock),
      );
    });

    test('AIConfigRepository saves and loads configuration', () async {
      const config = AIConfig(
        providerType: AIProviderType.openAICompatible,
        activeModelId: 'custom-model',
        temperature: 0.7,
      );

      await configRepo.saveConfig(config);
      final loaded = await configRepo.loadConfig();

      expect(loaded.providerType, AIProviderType.openAICompatible);
      expect(loaded.activeModelId, 'custom-model');
      expect(loaded.temperature, 0.7);
    });

    test(
        'AICacheRepository caches response and returns cached copy on repeat request',
        () async {
      const req = AIReadingRequest(
        task: AIReadingTask.explain,
        text: 'Law of inertia',
      );

      // 1. First execution populates cache
      mockProvider.scriptedResponse = 'Inertia explanation from model.';
      final res1 = await service.processTask(req, useCache: true);
      expect(res1.text, 'Inertia explanation from model.');

      // 2. Change mock response to verify cache hit
      mockProvider.scriptedResponse = 'NEW RESPONSE THAT SHOULD BE CACHED OVER';
      final res2 = await service.processTask(req, useCache: true);
      expect(res2.text, 'Inertia explanation from model.'); // Cache hit!

      // 3. Bypass cache
      final res3 = await service.processTask(req, useCache: false);
      expect(res3.text, 'NEW RESPONSE THAT SHOULD BE CACHED OVER');
    });

    test('RAG retrieval enriches request when contextScope is document',
        () async {
      final chunks = [
        PdfChunk(
          chunkId: 'chunk_law_1',
          documentId: 'doc_contract',
          index: 0,
          text:
              'Force majeure clauses excuse performance in unforeseen catastrophic events.',
          startPage: 8,
          endPage: 8,
          tokenEstimate: 20,
        ),
      ];

      const req = AIReadingRequest(
        task: AIReadingTask.askQuestion,
        text: '',
        userQuestion: 'What does force majeure cover in this contract?',
        contextScope: AIContextScope.document,
      );

      final res = await service.processTask(
        req,
        documentChunks: chunks,
        useCache: false,
      );

      expect(res.sources.isNotEmpty, isTrue);
      expect(res.sources.first.pageNumber, 8);
      expect(res.sources.first.chunkId, 'chunk_law_1');
    });

    test('Conversation management: create, append message, delete', () async {
      final conv = await service.createConversation(
        documentId: 'doc_100',
        title: 'Document Q&A',
        initialUserMessage: 'Hello AI',
      );

      expect(conv.messages.length, 1);
      expect(conv.messages.first.content, 'Hello AI');

      await service.appendMessage(
        documentId: 'doc_100',
        conversationId: conv.id,
        content: 'Hello human reader!',
        isUser: false,
      );

      final list = await service.getConversations('doc_100');
      expect(list.length, 1);
      expect(list.first.messages.length, 2);
      expect(list.first.messages.last.isUser, isFalse);

      await service.deleteConversation('doc_100', conv.id);
      final emptyList = await service.getConversations('doc_100');
      expect(emptyList, isEmpty);
    });

    test('Flashcards management: save, load, delete', () async {
      final cards = [
        AIFlashcard(
          id: 'fc_1',
          front: 'Mitosis',
          back: 'Cell division resulting in two daughter cells.',
          createdAt: DateTime.now(),
        ),
      ];

      await service.saveFlashcards(cards);
      final loaded = await service.getFlashcards();
      expect(loaded.length, 1);
      expect(loaded.first.front, 'Mitosis');

      await service.deleteFlashcard('fc_1');
      final afterDelete = await service.getFlashcards();
      expect(afterDelete, isEmpty);
    });
  });
}
