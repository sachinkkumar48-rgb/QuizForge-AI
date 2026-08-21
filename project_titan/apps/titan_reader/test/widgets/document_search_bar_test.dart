import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/pdf/pdf_engine_contracts.dart';
import 'package:titan_reader/src/widgets/document_search_bar.dart';

import '../support/fake_pdf_engine.dart';

void main() {
  late FakeViewerHandle handle;
  var closed = false;

  Widget buildSubject() {
    return MaterialApp(
      home: Scaffold(
        body: DocumentSearchBar(
          handle: handle,
          onClose: () => closed = true,
        ),
      ),
    );
  }

  setUp(() {
    handle = FakeViewerHandle();
    closed = false;
  });

  group('Phase 6D-3: DocumentSearchBar Widget Tests', () {
    testWidgets('debounces query input before starting the engine search',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(find.byType(TextField), 'const');
      // Before the debounce window closes nothing reaches the engine.
      await tester.pump(const Duration(milliseconds: 100));
      expect(handle.searchQueries, isEmpty);

      await tester.pump(kSearchDebounce + const Duration(milliseconds: 50));
      expect(handle.searchQueries, ['const']);

      // Retyping restarts the debounce: only the final query is searched.
      await tester.enterText(find.byType(TextField), 'constitution');
      await tester.pump(kSearchDebounce + const Duration(milliseconds: 50));
      expect(handle.searchQueries, ['const', 'constitution']);
    });

    testWidgets(
        'toggling case-sensitive option immediately starts search with option',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(find.byType(TextField), 'Article');
      await tester.pump(kSearchDebounce + const Duration(milliseconds: 50));
      expect(handle.lastCaseSensitive, isFalse);

      // Toggle case sensitivity
      await tester.tap(find.byKey(const Key('search-case-sensitive-toggle')));
      await tester.pump();

      expect(handle.lastCaseSensitive, isTrue);
    });

    testWidgets(
        'toggling whole-word option immediately starts search with option',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(find.byType(TextField), 'law');
      await tester.pump(kSearchDebounce + const Duration(milliseconds: 50));
      expect(handle.lastWholeWord, isFalse);

      // Toggle whole word
      await tester.tap(find.byKey(const Key('search-whole-word-toggle')));
      await tester.pump();

      expect(handle.lastWholeWord, isTrue);
    });

    testWidgets('shows match progress and navigates between matches',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      handle.matches = const [
        PdfSearchMatch(index: 0, pageNumber: 2, snippet: 'article'),
        PdfSearchMatch(index: 1, pageNumber: 7, snippet: 'article'),
      ];
      handle.currentSearchMatchIndex = 0;
      handle.fireSearchChanged();
      await tester.pump();

      expect(find.text('1 of 2 matches'), findsOneWidget);

      await tester.tap(find.byTooltip('Next match'));
      await tester.tap(find.byTooltip('Previous match'));
      expect(handle.nextMatchCalls, 1);
      expect(handle.previousMatchCalls, 1);
    });

    testWidgets('reports no matches once the search settles empty',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(kSearchDebounce + const Duration(milliseconds: 50));
      handle.fireSearchChanged();
      await tester.pump();

      expect(find.text('No matches for "zzz"'), findsOneWidget);
    });

    testWidgets('reports searching in progress when engine is scanning',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      handle.searching = true;
      await tester.enterText(find.byType(TextField), 'freedom');
      await tester.pump(kSearchDebounce + const Duration(milliseconds: 50));
      handle.fireSearchChanged();
      await tester.pump();

      expect(find.text('Searching document…'), findsOneWidget);
    });

    testWidgets(
        'results list expands and tapping match invokes goToSearchMatch',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      handle.matches = const [
        PdfSearchMatch(
            index: 0, pageNumber: 2, snippet: 'first hit in preamble'),
        PdfSearchMatch(
            index: 1, pageNumber: 9, snippet: 'second hit in article'),
      ];
      handle.fireSearchChanged();
      await tester.pump();

      await tester.tap(find.byTooltip('Show results list'));
      await tester.pump();

      expect(find.text('first hit in preamble'), findsOneWidget);
      expect(find.text('second hit in article'), findsOneWidget);
      expect(find.text('p. 2'), findsOneWidget);
      expect(find.text('p. 9'), findsOneWidget);

      // Tapping a result jumps directly to the match index
      await tester.tap(find.text('second hit in article'));
      await tester.pump();

      expect(handle.visitedMatchIndices, contains(1));
      expect(handle.visitedPages, contains(9));
      expect(handle.currentSearchMatchIndex, 1);
    });

    testWidgets('clearing query text clears active search and resets input',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(find.byType(TextField), 'justice');
      await tester.pump(kSearchDebounce + const Duration(milliseconds: 50));

      final clearButton = find.byTooltip('Clear query');
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pump();

      expect(find.text('justice'), findsNothing);
      expect(handle.clearSearchCalled, isTrue);
    });

    testWidgets('close button invokes onClose and dispose clears the search',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byTooltip('Close search'));
      expect(closed, isTrue);

      // Removing the bar from the tree must clear active match highlights.
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: null)));
      expect(handle.clearSearchCalled, isTrue);
    });
  });
}
