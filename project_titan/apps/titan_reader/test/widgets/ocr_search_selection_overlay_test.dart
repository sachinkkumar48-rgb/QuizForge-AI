import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_confidence.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_page_state.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_result.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_search_selection.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_text_region.dart';
import 'package:titan_reader/src/widgets/ocr/ocr_overlay_layer.dart';

void main() {
  group('OCR Search & Selection Overlay Widget Tests', () {
    const testViewportSize = Size(600, 800);

    final sampleResult = OcrResult.success(
      pageNumber: 1,
      blocks: const [
        OcrBlock(
          text: 'TITAN READER',
          boundingBox: NormalizedPageRect(
            left: 0.1,
            top: 0.2,
            right: 0.9,
            bottom: 0.4,
          ),
          confidence: OcrConfidence(0.95),
          lines: [
            OcrLine(
              text: 'TITAN READER',
              boundingBox: NormalizedPageRect(
                left: 0.1,
                top: 0.2,
                right: 0.9,
                bottom: 0.4,
              ),
              confidence: OcrConfidence(0.95),
              words: [
                OcrWord(
                  text: 'TITAN',
                  boundingBox: NormalizedPageRect(
                    left: 0.1,
                    top: 0.2,
                    right: 0.45,
                    bottom: 0.4,
                  ),
                  confidence: OcrConfidence(0.98),
                  wordIndex: 0,
                ),
                OcrWord(
                  text: 'READER',
                  boundingBox: NormalizedPageRect(
                    left: 0.5,
                    top: 0.2,
                    right: 0.9,
                    bottom: 0.4,
                  ),
                  confidence: OcrConfidence(0.80),
                  wordIndex: 1,
                ),
              ],
            ),
          ],
        ),
      ],
      processingDurationMs: 100,
      engineName: 'MockEngine',
      modelIdentifier: 'test-model',
    );

    Widget buildTestOverlay({
      List<OcrSearchMatch> searchMatches = const [],
      int? activeSearchMatchIndex,
      OcrTextSelection? activeSelection,
      void Function(OcrWord)? onWordTap,
      void Function(OcrTextSelection?)? onSelectionChanged,
      void Function(OcrTextSelection)? onCopySelection,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: testViewportSize.width,
              height: testViewportSize.height,
              child: OcrOverlayLayer(
                pageNumber: 1,
                viewportSize: testViewportSize,
                result: sampleResult,
                displayMode: OcrOverlayDisplayMode.textAndBoxes,
                searchMatches: searchMatches,
                activeSearchMatchIndex: activeSearchMatchIndex,
                activeSelection: activeSelection,
                onWordTap: onWordTap,
                onSelectionChanged: onSelectionChanged,
                onCopySelection: onCopySelection,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders search match highlight rectangles', (tester) async {
      const searchMatches = [
        OcrSearchMatch(
          index: 0,
          documentId: 'doc_1',
          pageNumber: 1,
          matchedText: 'TITAN',
          snippet: 'TITAN READER',
          startOffset: 0,
          endOffset: 5,
          boundingBoxes: [
            NormalizedPageRect(
              left: 0.1,
              top: 0.2,
              right: 0.45,
              bottom: 0.4,
            ),
          ],
          confidence: 0.98,
        ),
      ];

      await tester.pumpWidget(buildTestOverlay(
        searchMatches: searchMatches,
        activeSearchMatchIndex: 0,
      ));

      expect(find.byKey(const Key('ocr-search-match-0-0')), findsOneWidget);
    });

    testWidgets(
        'renders active text selection highlight and quick-action toolbar',
        (tester) async {
      const selection = OcrTextSelection(
        documentId: 'doc_1',
        pageNumber: 1,
        selectedText: 'TITAN',
        startOffset: 0,
        endOffset: 5,
        selectedTokenIndices: [0],
        boundingBoxes: [
          NormalizedPageRect(
            left: 0.1,
            top: 0.2,
            right: 0.45,
            bottom: 0.4,
          ),
        ],
      );

      await tester.pumpWidget(buildTestOverlay(
        activeSelection: selection,
      ));

      expect(find.byKey(const Key('ocr-selection-box-0')), findsOneWidget);
      expect(find.byKey(const Key('ocr-selection-toolbar')), findsOneWidget);
      expect(find.text('5 ch'), findsOneWidget);
      expect(
          find.byKey(const Key('ocr-copy-selection-button')), findsOneWidget);
      expect(
          find.byKey(const Key('ocr-clear-selection-button')), findsOneWidget);
    });

    testWidgets('tapping word invokes onSelectionChanged with selected token',
        (tester) async {
      OcrTextSelection? capturedSelection;

      await tester.pumpWidget(buildTestOverlay(
        onSelectionChanged: (sel) {
          capturedSelection = sel;
        },
      ));

      // Tap 'TITAN' word
      final titanWordFinder = find.byKey(const Key('ocr-word-0-TITAN'));
      expect(titanWordFinder, findsOneWidget);

      await tester.tap(titanWordFinder);
      await tester.pump();

      expect(capturedSelection, isNotNull);
      expect(capturedSelection!.selectedText, 'TITAN');
      expect(capturedSelection!.selectedTokenIndices, [0]);
    });

    testWidgets('tapping copy button in toolbar fires onCopySelection callback',
        (tester) async {
      const selection = OcrTextSelection(
        documentId: 'doc_1',
        pageNumber: 1,
        selectedText: 'READER',
        startOffset: 6,
        endOffset: 12,
        selectedTokenIndices: [1],
        boundingBoxes: [
          NormalizedPageRect(
            left: 0.5,
            top: 0.2,
            right: 0.9,
            bottom: 0.4,
          ),
        ],
      );

      OcrTextSelection? copiedSelection;

      await tester.pumpWidget(buildTestOverlay(
        activeSelection: selection,
        onCopySelection: (sel) {
          copiedSelection = sel;
        },
      ));

      final copyButton = find.byKey(const Key('ocr-copy-selection-button'));
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
      await tester.pump();

      expect(copiedSelection, isNotNull);
      expect(copiedSelection!.selectedText, 'READER');
    });

    testWidgets(
        'tapping clear button in toolbar invokes onSelectionChanged with null',
        (tester) async {
      const selection = OcrTextSelection(
        documentId: 'doc_1',
        pageNumber: 1,
        selectedText: 'READER',
        startOffset: 6,
        endOffset: 12,
        selectedTokenIndices: [1],
        boundingBoxes: [],
      );

      bool cleared = false;

      await tester.pumpWidget(buildTestOverlay(
        activeSelection: selection,
        onSelectionChanged: (sel) {
          if (sel == null) cleared = true;
        },
      ));

      final clearButton = find.byKey(const Key('ocr-clear-selection-button'));
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pump();

      expect(cleared, isTrue);
    });
  });
}
