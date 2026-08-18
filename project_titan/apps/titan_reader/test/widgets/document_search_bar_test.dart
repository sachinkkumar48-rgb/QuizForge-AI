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

  testWidgets('results list expands and shows one row per match',
      (tester) async {
    await tester.pumpWidget(buildSubject());

    handle.matches = const [
      PdfSearchMatch(index: 0, pageNumber: 2, snippet: 'first hit'),
      PdfSearchMatch(index: 1, pageNumber: 9, snippet: 'second hit'),
    ];
    handle.fireSearchChanged();
    await tester.pump();

    await tester.tap(find.byTooltip('Show results list'));
    await tester.pump();

    expect(find.text('first hit'), findsOneWidget);
    expect(find.text('second hit'), findsOneWidget);
    expect(find.text('p.2'), findsOneWidget);
    expect(find.text('p.9'), findsOneWidget);

    // Tapping a result jumps to its page.
    await tester.tap(find.text('second hit'));
    expect(handle.visitedPages, [9]);
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
}
