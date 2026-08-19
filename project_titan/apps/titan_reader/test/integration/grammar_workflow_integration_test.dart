import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/document_library_repository.dart';
import 'package:titan_reader/src/data/grammar_engine.dart';
import 'package:titan_reader/src/data/reading_position_repository.dart';
import 'package:titan_reader/src/data/spell_checker.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/pdf/pdf_engine_contracts.dart';
import 'package:titan_reader/src/providers/dictionary_providers.dart';
import 'package:titan_reader/src/providers/grammar_providers.dart';
import 'package:titan_reader/src/providers/reader_providers.dart';
import 'package:titan_reader/src/screens/reader_screen.dart';
import 'package:titan_reader/src/services/library_service.dart';
import 'package:titan_reader/src/services/reading_history_service.dart';
import 'package:titan_reader/src/widgets/grammar_panel.dart';
import 'package:titan_storage/titan_storage.dart';

import '../support/fake_pdf_engine.dart';

// "%PDF-" magic header bytes; tests never touch the real file system.
const List<int> pdfHeader = [0x25, 0x50, 0x44, 0x46, 0x2D];
const String fakePdfPath = '/titan/reader/fixtures/sample.pdf';

const NormalizedPageRect selectionRect = NormalizedPageRect(
  left: 0.1,
  top: 0.2,
  right: 0.6,
  bottom: 0.25,
);

/// Stand-in for the bundled WordNet headword index: only the words the
/// test knows about, so the real engine stays deterministic.
class FakeHeadwordIndex implements HeadwordIndex {
  FakeHeadwordIndex(this.words);

  final Set<String> words;

  @override
  Future<Set<String>> loadWords() async => words;
}

void main() {
  testWidgets(
      'mandatory workflow: select broken sentence, review issues, accept '
      'every correction and copy the result', (tester) async {
    // A tall surface keeps every issue card visible inside the sheet.
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    final storage = InMemoryStorageService();
    await storage.initialize();
    final pdfEngine = FakePdfEngine();
    // The production deterministic engine with a scripted word list.
    final grammarEngine = LocalGrammarEngine(
      spellChecker: WordNetSpellChecker(
        index: FakeHeadwordIndex({'the', 'report', 'received'}),
      ),
    );

    final libraryService = LibraryService(
      library: StorageDocumentLibraryRepository(storage),
      positions: StorageReadingPositionRepository(storage),
      history: ReadingHistoryService(storage),
    );
    final document = await libraryService.importFile(
      filePath: fakePdfPath,
      fileName: 'sample.pdf',
      sizeBytes: 1024,
      at: DateTime.utc(2026, 8, 1),
      headerBytes: pdfHeader,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        pdfEngineProvider.overrideWithValue(pdfEngine),
        grammarEngineProvider.overrideWithValue(grammarEngine),
        remoteGrammarSourceProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        home: ReaderScreen(
          documentId: document.id,
          fileExists: (path) => true,
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();

    // Step 1: open PDF, select the incorrect sentence, tap Grammar.
    final handle = pdfEngine.lastHandle!;
    handle.scriptedSelection = const PdfTextSelectionSnapshot(
      text: 'i recieved the the report.',
      fragments: [
        PdfSelectionFragment(pageNumber: 2, rect: selectionRect),
      ],
    );
    handle.lastSettings!.onSelectionAction!('grammar');
    await tester.pump();
    await tester.pumpAndSettle();

    // Step 2: issues are detected by the deterministic engine.
    expect(find.byType(GrammarPanel), findsOneWidget);
    expect(find.text('3 issues found'), findsOneWidget);

    // Issue cards arrive ordered by offset: pronoun, spelling, repeat.
    expect(find.textContaining('The pronoun "I" is always capitalized.'),
        findsOneWidget);
    expect(find.textContaining('Possible spelling mistake.'), findsOneWidget);
    expect(find.textContaining('Repeated word "the".'), findsOneWidget);

    // Step 3: the spelling issue offers vocabulary reuse (§26).
    await tester.tap(find.byKey(const ValueKey('grammar-vocabulary-1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Saved "recieved"'), findsOneWidget);
    final vocabulary =
        ProviderScope.containerOf(tester.element(find.byType(GrammarPanel)))
            .read(vocabularyServiceProvider);
    expect(vocabulary.wordForNormalized('recieved'), isNotNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Step 4: accept every suggestion, one at a time.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('grammar-apply-0-0')));
      await tester.pumpAndSettle();
      // Let each snackbar expire so the next card is unambiguous.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }

    // Step 5: all issues gone; the corrected text is copyable (§18).
    expect(find.byKey(const Key('grammar-no-issues')), findsOneWidget);
    await tester.tap(find.byKey(const Key('grammar-copy-corrected-button')));
    await tester.pumpAndSettle();
    expect(clipboardText, 'I received the report.');

    // Step 6: corrections are Reader-managed records with source context;
    // the PDF file itself was never modified (§16–17).
    final grammarService =
        ProviderScope.containerOf(tester.element(find.byType(GrammarPanel)))
            .read(grammarServiceProvider);
    final corrections = await grammarService.getCorrections();
    expect(corrections, hasLength(3));
    expect(
      corrections.map((c) => c.appliedRuleIds.single).toSet(),
      {'rule.standalone-i', WordNetSpellChecker.ruleId, 'rule.repeated-word'},
    );
    for (final correction in corrections) {
      expect(correction.documentId, document.id);
      expect(correction.pageNumber, 2);
      expect(correction.originalText, 'i recieved the the report.');
    }
  });
}
