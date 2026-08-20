import 'package:flutter_test/flutter_test.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_reader/src/data/ai_cache_repository.dart';
import 'package:titan_reader/src/data/ai_config_repository.dart';
import 'package:titan_reader/src/data/ai_conversation_repository.dart';
import 'package:titan_reader/src/data/ai_flashcard_repository.dart';
import 'package:titan_reader/src/data/mock_ai_reading_provider.dart';
import 'package:titan_reader/src/data/vocabulary_repository.dart';
import 'package:titan_reader/src/domain/entities/ai_reading_models.dart';
import 'package:titan_reader/src/domain/entities/ai_reading_task.dart';
import 'package:titan_reader/src/services/ai_reading_service.dart';
import 'package:titan_reader/src/services/vocabulary_service.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('Phase 5: End-to-End AI Reading Assistant Workflows', () {
    late InMemoryStorageService storage;
    late AIReadingService aiService;
    late VocabularyService vocabService;
    late MockAIReadingProvider mockProvider;

    setUp(() async {
      storage = InMemoryStorageService();
      await storage.initialize();
      mockProvider = MockAIReadingProvider();

      aiService = AIReadingService(
        configRepo: AIConfigRepository(storage),
        cacheRepo: AICacheRepository(storage),
        conversationRepo: AIConversationRepository(storage),
        flashcardRepo: AIFlashcardRepository(storage),
        providers: {
          AIProviderType.localOllama: mockProvider,
          AIProviderType.mock: mockProvider,
        },
        initialConfig: const AIConfig(providerType: AIProviderType.mock),
      );

      vocabService = VocabularyService(
        repository: StorageVocabularyRepository(storage),
      );
      await vocabService.ensureLoaded();
    });

    test('Workflow A: Explain selected text and extract key terms', () async {
      mockProvider.scriptedResponse =
          'Explanation: Quantum electrodynamics describes light and matter interaction.\n\n'
          'Important Terms: Electrodynamics, Photon, Quantum.';

      const req = AIReadingRequest(
        task: AIReadingTask.explain,
        text: 'Quantum electrodynamics is relativistic quantum field theory.',
        documentId: 'doc_physics',
        pageNumber: 23,
      );

      final res = await aiService.processTask(req, useCache: false);
      expect(res.text, contains('Quantum electrodynamics'));
      expect(res.extractedKeyTerms, contains('Photon'));
      expect(res.extractedKeyTerms, contains('Quantum'));
    });

    test('Workflow B: Grounded Document Q&A (Local RAG) with source citations',
        () async {
      final docChunks = [
        PdfChunk(
          chunkId: 'c1',
          documentId: 'doc_law',
          index: 0,
          text:
              'Article 1: Freedom of speech is guaranteed under constitutional law.',
          startPage: 3,
          endPage: 3,
          tokenEstimate: 20,
        ),
        PdfChunk(
          chunkId: 'c2',
          documentId: 'doc_law',
          index: 1,
          text:
              'Article 2: Copyright protection endures for seventy years after the author death.',
          startPage: 12,
          endPage: 12,
          tokenEstimate: 25,
        ),
      ];

      const req = AIReadingRequest(
        task: AIReadingTask.askQuestion,
        text: '',
        userQuestion: 'How long does copyright protection last?',
        contextScope: AIContextScope.document,
        documentId: 'doc_law',
      );

      final res = await aiService.processTask(
        req,
        documentChunks: docChunks,
        useCache: false,
      );

      expect(res.sources.isNotEmpty, isTrue);
      expect(res.sources.first.pageNumber, 12);
      expect(res.sources.first.excerpt, contains('seventy years'));
    });

    test('Workflow C: Offline deterministic execution', () async {
      // Offline mode works without network access
      mockProvider.scriptedResponse = 'Deterministic offline output.';

      const req = AIReadingRequest(
        task: AIReadingTask.simplify,
        text: 'Dense legal prose.',
      );

      final res = await aiService.processTask(req, useCache: true);
      expect(res.text, 'Deterministic offline output.');
    });

    test('Workflow D: Vocabulary save provenance from AI extracted term',
        () async {
      const identifiedTerm = 'photosynthesis';
      await vocabService.saveWord(
        rawWord: identifiedTerm,
        at: DateTime.now(),
        sourceDocumentId: 'doc_biology',
        sourceDocumentName: 'Cellular Biology.pdf',
        sourcePage: 45,
        selectedText: 'Plants utilize photosynthesis to convert light.',
      );

      final entry = vocabService.wordForNormalized(identifiedTerm);
      expect(entry, isNotNull);
      expect(entry!.word, 'photosynthesis');
      expect(entry.sourceDocumentId, 'doc_biology');
      expect(entry.sourceDocumentName, 'Cellular Biology.pdf');
      expect(entry.sourcePage, 45);
    });

    test('Workflow E: Flashcards generation and persistence', () async {
      const req = AIReadingRequest(
        task: AIReadingTask.generateFlashcards,
        text: 'Mitochondria are the powerhouses of the cell.',
        documentId: 'doc_bio',
        pageNumber: 10,
      );

      final res = await aiService.processTask(req, useCache: false);
      expect(res.flashcards.isNotEmpty, isTrue);

      final storedFlashcards = await aiService.getFlashcards();
      expect(storedFlashcards.isNotEmpty, isTrue);
      expect(storedFlashcards.first.front, isNotEmpty);
    });
  });
}
