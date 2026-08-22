import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/dictionary_cache_repository.dart';
import 'package:titan_reader/src/data/dictionary_data_source.dart';
import 'package:titan_reader/src/data/grammar_cache_repository.dart';
import 'package:titan_reader/src/data/grammar_correction_repository.dart';
import 'package:titan_reader/src/data/grammar_engine.dart';
import 'package:titan_reader/src/data/recent_lookup_repository.dart';
import 'package:titan_reader/src/data/spell_checker.dart';
import 'package:titan_reader/src/data/vocabulary_repository.dart';
import 'package:titan_reader/src/domain/dictionary_errors.dart';
import 'package:titan_reader/src/domain/entities/dictionary_entry.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_search_selection.dart';
import 'package:titan_reader/src/domain/entities/unified_text_context.dart';
import 'package:titan_reader/src/pdf/pdf_engine_contracts.dart';
import 'package:titan_reader/src/services/dictionary_service.dart';
import 'package:titan_reader/src/services/grammar_service.dart';
import 'package:titan_reader/src/services/language_services_bridge.dart';
import 'package:titan_reader/src/services/vocabulary_service.dart';
import 'package:titan_storage/titan_storage.dart';

class _FakeHeadwordIndex implements HeadwordIndex {
  final Set<String> words;
  const _FakeHeadwordIndex(this.words);

  @override
  Future<Set<String>> loadWords() async => words;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageServicesBridge Integration Tests', () {
    const bridge = LanguageServicesBridge();
    const docId = 'doc_constitution_01';
    const docName = 'Constitution of India.pdf';

    late InMemoryStorageService storage;
    late DictionaryService dictionaryService;
    late GrammarService grammarService;
    late VocabularyService vocabularyService;

    setUp(() async {
      storage = InMemoryStorageService();
      await storage.initialize();

      // Set up DictionaryService with in-memory local source
      final localDictionary = InMemoryDictionaryDataSource({
        'sovereignty': DictionaryEntry(
          word: 'sovereignty',
          normalizedWord: 'sovereignty',
          senses: const [
            DictionarySense(
              partOfSpeech: 'noun',
              definitions: ['Supreme power or authority.'],
              examples: ['National sovereignty is preserved.'],
            ),
          ],
          source: const DictionarySourceInfo(
            id: 'test-dict',
            attribution: 'Test Dict',
          ),
        ),
      });

      dictionaryService = DictionaryService(
        localSource: localDictionary,
        cache: StorageDictionaryCacheRepository(storage),
        recentLookups: StorageRecentLookupRepository(storage),
      );

      // Set up GrammarService with local rule engine and word index
      final grammarEngine = LocalGrammarEngine(
        spellChecker: WordNetSpellChecker(
          index: const _FakeHeadwordIndex(
              {'this', 'is', 'the', 'end', 'of', 'clause'}),
        ),
      );
      grammarService = GrammarService(
        engine: grammarEngine,
        cache: StorageGrammarCacheRepository(storage),
        corrections: StorageGrammarCorrectionRepository(storage),
        remoteEnabled: false,
      );

      // Set up VocabularyService with storage repository
      vocabularyService = VocabularyService(
        repository: StorageVocabularyRepository(storage),
      );
    });

    test('bridges native selection to dictionary lookup successfully',
        () async {
      const snapshot = PdfTextSelectionSnapshot(
        text: 'Sovereignty',
        fragments: [
          PdfSelectionFragment(
            pageNumber: 1,
            rect: NormalizedPageRect(
                left: 0.1, top: 0.1, right: 0.4, bottom: 0.2),
          ),
        ],
      );

      final context = UnifiedTextContext.fromNativeSnapshot(
        documentId: docId,
        documentName: docName,
        snapshot: snapshot,
      );

      final result =
          await bridge.lookupInDictionary(dictionaryService, context);
      expect(result, isA<DictionaryLookupFound>());
      final found = result as DictionaryLookupFound;
      expect(found.word, 'sovereignty');
      expect(found.entry.senses.first.definitions.first,
          'Supreme power or authority.');
    });

    test('bridges OCR selection to dictionary lookup seamlessly', () async {
      const ocrSelection = OcrTextSelection(
        documentId: docId,
        pageNumber: 3,
        selectedText: 'sovereignty',
        startOffset: 0,
        endOffset: 11,
        selectedTokenIndices: [0],
        boundingBoxes: [
          NormalizedPageRect(left: 0.2, top: 0.2, right: 0.5, bottom: 0.28),
        ],
      );

      final context = UnifiedTextContext.fromOcrSelection(
        selection: ocrSelection,
        documentName: docName,
        confidence: 0.94,
      );

      final result =
          await bridge.lookupInDictionary(dictionaryService, context);
      expect(result, isA<DictionaryLookupFound>());
      final found = result as DictionaryLookupFound;
      expect(found.word, 'sovereignty');
    });

    test('returns not found when multi-word phrase is passed to dictionary',
        () async {
      final context = UnifiedTextContext(
        documentId: docId,
        documentName: docName,
        pageNumber: 2,
        selectedText: 'Supreme Court of India',
        source: TextProvenance.ocr,
        selectionBounds: const [],
        timestamp: DateTime.now(),
      );

      final result =
          await bridge.lookupInDictionary(dictionaryService, context);
      expect(result, isA<DictionaryLookupNotFound>());
    });

    test('bridges multi-word OCR phrase to grammar check engine', () async {
      const phrase = 'This is the the end of the clause.';
      final context = UnifiedTextContext(
        documentId: docId,
        documentName: docName,
        pageNumber: 4,
        selectedText: phrase,
        source: TextProvenance.ocr,
        selectionBounds: const [],
        timestamp: DateTime.now(),
      );

      final outcome = await bridge.checkGrammar(grammarService, context);
      expect(outcome.result.text, phrase);
      expect(outcome.result.issues, isNotEmpty);
      expect(outcome.result.issues.first.ruleId, 'rule.repeated-word');
    });

    test(
        'bridges OCR word selection to vocabulary save with provenance attribution',
        () async {
      const ocrSelection = OcrTextSelection(
        documentId: docId,
        pageNumber: 5,
        selectedText: 'Fraternity',
        startOffset: 0,
        endOffset: 10,
        selectedTokenIndices: [2],
        boundingBoxes: [
          NormalizedPageRect(left: 0.1, top: 0.4, right: 0.4, bottom: 0.48),
        ],
      );

      final context = UnifiedTextContext.fromOcrSelection(
        selection: ocrSelection,
        documentName: docName,
      );

      final saved = await bridge.saveToVocabulary(
        vocabularyService,
        context,
        personalMeaning: 'A sense of common brotherhood.',
      );

      expect(saved, isNotNull);
      expect(saved!.normalizedWord, 'fraternity');
      expect(saved.sourceDocumentId, docId);
      expect(saved.sourceDocumentName, docName);
      expect(saved.sourcePage, 5);
      expect(saved.personalMeaning, 'A sense of common brotherhood.');

      // Verify stored in repository
      final allWords = vocabularyService.words;
      expect(allWords.length, 1);
      expect(allWords.first.word, 'fraternity');
    });

    test('copies UnifiedTextContext safely to system clipboard', () async {
      String? clipboardText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      final context = UnifiedTextContext(
        documentId: docId,
        pageNumber: 1,
        selectedText: 'Liberty of thought and expression',
        source: TextProvenance.ocr,
        selectionBounds: const [],
        timestamp: DateTime.now(),
      );

      final copied = await bridge.copyToClipboard(context);
      expect(copied, isTrue);
      expect(clipboardText, 'Liberty of thought and expression');
    });

    test('copyToClipboard returns false on null or empty context', () async {
      final nullResult = await bridge.copyToClipboard(null);
      expect(nullResult, isFalse);

      final emptyContext = UnifiedTextContext(
        documentId: docId,
        pageNumber: 1,
        selectedText: '',
        source: TextProvenance.nativePdf,
        selectionBounds: const [],
        timestamp: DateTime.now(),
      );

      final emptyResult = await bridge.copyToClipboard(emptyContext);
      expect(emptyResult, isFalse);
    });
  });
}
