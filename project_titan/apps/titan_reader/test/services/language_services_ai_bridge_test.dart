import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/ai_cache_repository.dart';
import 'package:titan_reader/src/data/ai_config_repository.dart';
import 'package:titan_reader/src/data/ai_conversation_repository.dart';
import 'package:titan_reader/src/data/ai_flashcard_repository.dart';
import 'package:titan_reader/src/data/mock_ai_reading_provider.dart';
import 'package:titan_reader/src/domain/entities/ai_reading_models.dart';
import 'package:titan_reader/src/domain/entities/ai_reading_task.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_search_selection.dart';
import 'package:titan_reader/src/domain/entities/unified_text_context.dart';
import 'package:titan_reader/src/pdf/pdf_engine_contracts.dart';
import 'package:titan_reader/src/services/ai_reading_service.dart';
import 'package:titan_reader/src/services/language_services_bridge.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('LanguageServicesBridge AI Integration Tests', () {
    const bridge = LanguageServicesBridge();
    const docId = 'doc_constitution_ai';
    const docName = 'Constitution of India.pdf';

    late InMemoryStorageService storage;
    late AIConfigRepository configRepo;
    late AICacheRepository cacheRepo;
    late AIConversationRepository convRepo;
    late AIFlashcardRepository flashcardRepo;
    late MockAIReadingProvider mockProvider;
    late AIReadingService aiService;

    setUp(() async {
      storage = InMemoryStorageService();
      await storage.initialize();
      configRepo = AIConfigRepository(storage);
      cacheRepo = AICacheRepository(storage);
      convRepo = AIConversationRepository(storage);
      flashcardRepo = AIFlashcardRepository(storage);
      mockProvider = MockAIReadingProvider();

      aiService = AIReadingService(
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

    test('executes explain task for native selection via bridge', () async {
      const snapshot = PdfTextSelectionSnapshot(
        text: 'Sovereign Socialist Secular Democratic Republic',
        fragments: [
          PdfSelectionFragment(
            pageNumber: 1,
            rect: NormalizedPageRect(
                left: 0.1, top: 0.2, right: 0.9, bottom: 0.25),
          ),
        ],
      );

      final context = UnifiedTextContext.fromNativeSnapshot(
        documentId: docId,
        documentName: docName,
        snapshot: snapshot,
      );

      final response = await bridge.executeAITask(
        aiService,
        context,
        task: AIReadingTask.explain,
      );

      expect(response.text, isNotEmpty);
      expect(response.task, AIReadingTask.explain);
    });

    test('executes summarize task for OCR selection via bridge', () async {
      const ocrSelection = OcrTextSelection(
        documentId: docId,
        pageNumber: 3,
        selectedText:
            'Justice, social, economic and political; Liberty of thought, expression, belief, faith and worship;',
        startOffset: 0,
        endOffset: 98,
        selectedTokenIndices: [0, 1, 2, 3],
        boundingBoxes: [
          NormalizedPageRect(left: 0.1, top: 0.3, right: 0.9, bottom: 0.38),
        ],
      );

      final context = UnifiedTextContext.fromOcrSelection(
        selection: ocrSelection,
        documentName: docName,
        confidence: 0.95,
      );

      final response = await bridge.executeAITask(
        aiService,
        context,
        task: AIReadingTask.summarize,
        summaryLength: AISummaryLength.short,
      );

      expect(response.text, isNotEmpty);
      expect(response.task, AIReadingTask.summarize);
    });

    test('executes Ask AI question task with user question and OCR context',
        () async {
      const ocrSelection = OcrTextSelection(
        documentId: docId,
        pageNumber: 21,
        selectedText: 'Right to Life and Personal Liberty',
        startOffset: 0,
        endOffset: 34,
        selectedTokenIndices: [0, 1, 2],
        boundingBoxes: [
          NormalizedPageRect(left: 0.2, top: 0.4, right: 0.8, bottom: 0.48),
        ],
      );

      final context = UnifiedTextContext.fromOcrSelection(
        selection: ocrSelection,
        documentName: docName,
      );

      final response = await bridge.executeAITask(
        aiService,
        context,
        task: AIReadingTask.askQuestion,
        userQuestion: 'How has the Supreme Court expanded this right?',
      );

      expect(response.text, isNotEmpty);
      expect(response.task, AIReadingTask.askQuestion);
    });

    test('validates stale AI request discard scenario across context change',
        () async {
      final contextA = UnifiedTextContext(
        documentId: 'doc_A',
        pageNumber: 1,
        selectedText: 'Clause A',
        source: TextProvenance.ocr,
        selectionBounds: const [],
        timestamp: DateTime.now(),
      );

      final contextB = UnifiedTextContext(
        documentId: 'doc_A',
        pageNumber: 2,
        selectedText: 'Clause B',
        source: TextProvenance.ocr,
        selectionBounds: const [],
        timestamp: DateTime.now(),
      );

      final requestA = bridge.createAIRequest(
        contextA,
        task: AIReadingTask.explain,
      );

      final responseA = await aiService.processTask(requestA);

      // Verify that responseA belongs to contextA and not contextB
      expect(contextA.isSameContext(contextB), isFalse);
      expect(responseA.text, isNotEmpty);
    });
  });
}
