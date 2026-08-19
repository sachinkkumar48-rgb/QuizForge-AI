import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/document_library_repository.dart';
import 'package:titan_reader/src/data/grammar_engine.dart';
import 'package:titan_reader/src/data/reading_position_repository.dart';
import 'package:titan_reader/src/domain/entities/grammar_issue.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/pdf/pdf_engine_contracts.dart';
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

class RecordingGrammarEngine implements GrammarEngine {
  RecordingGrammarEngine(this.issuesFor);

  final List<GrammarIssue> Function(String text) issuesFor;
  final List<String> checkedTexts = [];

  @override
  String get engineId => 'fake.engine';

  @override
  String get engineVersion => '1.0.0';

  @override
  Future<List<GrammarIssue>> check(String text,
      {String language = 'en'}) async {
    checkedTexts.add(text);
    return issuesFor(text);
  }
}

void main() {
  late InMemoryStorageService storage;
  late FakePdfEngine engine;
  late RecordingGrammarEngine grammarEngine;

  const GrammarIssue scriptedIssue = GrammarIssue(
    ruleId: 'rule.subject-verb',
    type: GrammarIssueType.grammar,
    severity: GrammarIssueSeverity.warning,
    message: 'Subject-verb agreement.',
    startOffset: 3,
    endOffset: 5,
    originalText: 'go',
    suggestions: [GrammarSuggestion(replacement: 'goes')],
  );

  setUp(() async {
    storage = InMemoryStorageService();
    await storage.initialize();
    engine = FakePdfEngine();
    grammarEngine = RecordingGrammarEngine((_) => const [scriptedIssue]);
  });

  LibraryService service() => LibraryService(
        library: StorageDocumentLibraryRepository(storage),
        positions: StorageReadingPositionRepository(storage),
        history: ReadingHistoryService(storage),
      );

  Widget buildSubject(String documentId) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        pdfEngineProvider.overrideWithValue(engine),
        grammarEngineProvider.overrideWithValue(grammarEngine),
        remoteGrammarSourceProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        home: ReaderScreen(
          documentId: documentId,
          fileExists: (path) => true,
        ),
      ),
    );
  }

  Future<String> importSample(LibraryService libraryService) async {
    final document = await libraryService.importFile(
      filePath: fakePdfPath,
      fileName: 'sample.pdf',
      sizeBytes: 1024,
      at: DateTime.utc(2026, 8, 1),
      headerBytes: pdfHeader,
    );
    return document.id;
  }

  PdfTextSelectionSnapshot selection(String text, {int page = 3}) {
    return PdfTextSelectionSnapshot(
      text: text,
      fragments: [
        PdfSelectionFragment(pageNumber: page, rect: selectionRect),
      ],
    );
  }

  testWidgets('grammar action analyzes the selection in the grammar panel',
      (tester) async {
    final libraryService = service();
    final documentId = await importSample(libraryService);
    await tester.pumpWidget(buildSubject(documentId));
    await tester.pump();
    await tester.pump();

    final handle = engine.lastHandle!;
    handle.scriptedSelection = selection('He go to school.');
    handle.lastSettings!.onSelectionAction!('grammar');
    await tester.pump();
    await tester.pumpAndSettle();

    // The existing Phase 2 selection pipeline was reused (§8): the
    // selection was captured, cleared and handed to the grammar panel.
    expect(handle.clearSelectionCalled, isTrue);
    expect(find.byType(GrammarPanel), findsOneWidget);
    // Only the selected text reaches the engine (§8, §20).
    expect(grammarEngine.checkedTexts, ['He go to school.']);
    expect(find.text('1 issue found'), findsOneWidget);
    expect(find.byKey(const ValueKey('grammar-issue-card-0')), findsOneWidget);
  });

  testWidgets(
      'multi-sentence and multi-paragraph selections are forwarded '
      'verbatim', (tester) async {
    final libraryService = service();
    final documentId = await importSample(libraryService);
    await tester.pumpWidget(buildSubject(documentId));
    await tester.pump();
    await tester.pump();

    const multiParagraph =
        'First sentence ends here.\n\nSecond paragraph has  two spaces.';
    final handle = engine.lastHandle!;
    handle.scriptedSelection = selection(multiParagraph);
    handle.lastSettings!.onSelectionAction!('grammar');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(grammarEngine.checkedTexts, [multiParagraph]);
    expect(find.byType(GrammarPanel), findsOneWidget);
  });

  testWidgets('unicode selections reach the engine without corruption',
      (tester) async {
    final libraryService = service();
    final documentId = await importSample(libraryService);
    await tester.pumpWidget(buildSubject(documentId));
    await tester.pump();
    await tester.pump();

    const unicode = 'Résumé: the the café. ñandú';
    final handle = engine.lastHandle!;
    handle.scriptedSelection = selection(unicode);
    handle.lastSettings!.onSelectionAction!('grammar');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(grammarEngine.checkedTexts, [unicode]);
    expect(find.byType(GrammarPanel), findsOneWidget);
  });

  testWidgets('corrections record the source page of the selection',
      (tester) async {
    final libraryService = service();
    final documentId = await importSample(libraryService);
    await tester.pumpWidget(buildSubject(documentId));
    await tester.pump();
    await tester.pump();

    final handle = engine.lastHandle!;
    // Selection on a different page: page 5.
    handle.scriptedSelection = selection('He go to school.', page: 5);
    handle.lastSettings!.onSelectionAction!('grammar');
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('grammar-apply-0-0')));
    await tester.pumpAndSettle();

    final grammarService =
        ProviderScope.containerOf(tester.element(find.byType(GrammarPanel)))
            .read(grammarServiceProvider);
    final corrections = await grammarService.getCorrections();
    expect(corrections, hasLength(1));
    expect(corrections.single.documentId, documentId);
    expect(corrections.single.pageNumber, 5);
    expect(corrections.single.correctedText, 'He goes to school.');
  });

  testWidgets('empty selections do not open the grammar panel', (tester) async {
    final libraryService = service();
    final documentId = await importSample(libraryService);
    await tester.pumpWidget(buildSubject(documentId));
    await tester.pump();
    await tester.pump();

    final handle = engine.lastHandle!;
    handle.scriptedSelection = selection('   ');
    handle.lastSettings!.onSelectionAction!('grammar');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(GrammarPanel), findsNothing);
    expect(grammarEngine.checkedTexts, isEmpty);
  });

  testWidgets('no selection at all is a no-op', (tester) async {
    final libraryService = service();
    final documentId = await importSample(libraryService);
    await tester.pumpWidget(buildSubject(documentId));
    await tester.pump();
    await tester.pump();

    engine.lastHandle!.lastSettings!.onSelectionAction!('grammar');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(GrammarPanel), findsNothing);
  });
}
