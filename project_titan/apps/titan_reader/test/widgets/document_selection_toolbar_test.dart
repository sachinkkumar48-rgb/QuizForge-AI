import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/reader_annotation.dart';
import 'package:titan_reader/src/pdf/pdf_engine_contracts.dart';
import 'package:titan_reader/src/widgets/document_selection_toolbar.dart';

import '../support/fake_pdf_engine.dart';

void main() {
  group('Phase 6D-4: DocumentSelectionToolbar Widget Tests', () {
    late FakeViewerHandle handle;

    setUp(() {
      handle = FakeViewerHandle();
      handle.scriptedSelection = const PdfTextSelectionSnapshot(
        text: 'Quantum Computing Fundamentals',
        fragments: [
          PdfSelectionFragment(
            pageNumber: 1,
            rect: NormalizedPageRect(
              left: 0.1,
              top: 0.2,
              right: 0.5,
              bottom: 0.25,
            ),
          ),
        ],
      );
    });

    testWidgets('renders snippet, character count, and core action buttons',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentSelectionToolbar(
              handle: handle,
              onAction: (_, {color}) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quantum Computing Fundamentals'), findsOneWidget);
      expect(find.text('30 ch'), findsOneWidget);
      expect(find.byKey(const Key('selection-copy-button')), findsOneWidget);
      expect(find.byKey(const Key('selection-color-button')), findsOneWidget);
      expect(
          find.byKey(const Key('selection-underline-button')), findsOneWidget);
      expect(find.byKey(const Key('selection-strikethrough-button')),
          findsOneWidget);
      expect(find.byKey(const Key('selection-note-button')), findsOneWidget);
      expect(find.byKey(const Key('selection-search-button')), findsOneWidget);
      expect(
          find.byKey(const Key('selection-dictionary-button')), findsOneWidget);
      expect(find.byKey(const Key('selection-grammar-button')), findsOneWidget);
      expect(find.byKey(const Key('selection-ai-button')), findsOneWidget);
      expect(find.byKey(const Key('selection-close-button')), findsOneWidget);
    });

    testWidgets('triggers copy action on tap', (tester) async {
      String? triggeredAction;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentSelectionToolbar(
              handle: handle,
              onAction: (action, {color}) => triggeredAction = action,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('selection-copy-button')));
      await tester.pumpAndSettle();

      expect(triggeredAction, 'copy');
    });

    testWidgets(
        'triggers underline, strikethrough, note, search, dictionary, grammar actions',
        (tester) async {
      final actions = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentSelectionToolbar(
              handle: handle,
              onAction: (action, {color}) => actions.add(action),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('selection-underline-button')));
      await tester.tap(find.byKey(const Key('selection-strikethrough-button')));
      await tester.tap(find.byKey(const Key('selection-note-button')));
      await tester.tap(find.byKey(const Key('selection-search-button')));
      await tester.tap(find.byKey(const Key('selection-dictionary-button')));
      await tester.tap(find.byKey(const Key('selection-grammar-button')));
      await tester.pumpAndSettle();

      expect(actions, [
        'underline',
        'strikethrough',
        'note',
        'search',
        'dictionary',
        'grammar',
      ]);
    });

    testWidgets(
        'color picker popup changes active color and triggers highlight',
        (tester) async {
      String? triggeredAction;
      ReaderAnnotationColor? chosenColor;
      ReaderAnnotationColor? changedColor;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentSelectionToolbar(
              handle: handle,
              activeColor: ReaderAnnotationColor.yellow,
              onColorChanged: (c) => changedColor = c,
              onAction: (action, {color}) {
                triggeredAction = action;
                chosenColor = color;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap color popup button
      await tester.tap(find.byKey(const Key('selection-color-button')));
      await tester.pumpAndSettle();

      // Tap Green option
      await tester.tap(find.text('Green'));
      await tester.pumpAndSettle();

      expect(triggeredAction, 'highlight');
      expect(chosenColor, ReaderAnnotationColor.green);
      expect(changedColor, ReaderAnnotationColor.green);
    });

    testWidgets('AI popup menu triggers specific AI reading tasks',
        (tester) async {
      String? triggeredAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentSelectionToolbar(
              handle: handle,
              onAction: (action, {color}) => triggeredAction = action,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open AI menu
      await tester.tap(find.byKey(const Key('selection-ai-button')));
      await tester.pumpAndSettle();

      // Tap Explain
      await tester.tap(find.text('Explain'));
      await tester.pumpAndSettle();

      expect(triggeredAction, 'explain');

      // Open AI menu again and tap Summarize
      await tester.tap(find.byKey(const Key('selection-ai-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Summarize'));
      await tester.pumpAndSettle();

      expect(triggeredAction, 'summarize');
    });

    testWidgets(
        'close button clears handle selection and invokes onClose callback',
        (tester) async {
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentSelectionToolbar(
              handle: handle,
              onAction: (_, {color}) {},
              onClose: () => closed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('selection-close-button')));
      await tester.pumpAndSettle();

      expect(handle.clearSelectionCalled, isTrue);
      expect(closed, isTrue);
    });

    testWidgets('updates displayed snippet dynamically when selection changes',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentSelectionToolbar(
              handle: handle,
              onAction: (_, {color}) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quantum Computing Fundamentals'), findsOneWidget);

      // Simulate selection update
      handle.scriptedSelection = const PdfTextSelectionSnapshot(
        text: 'Updated Selected Text Passage',
        fragments: [],
      );
      handle.fireSelectionChanged();
      await tester.pumpAndSettle();

      expect(find.text('Updated Selected Text Passage'), findsOneWidget);
      expect(find.text('29 ch'), findsOneWidget);
    });
  });
}
