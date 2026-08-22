import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_confidence.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_page_state.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_result.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_search_selection.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_text_region.dart';
import 'package:titan_reader/src/domain/entities/unified_text_context.dart';
import 'package:titan_reader/src/widgets/ocr/ocr_overlay_layer.dart';

void main() {
  group('OCR Language Actions Overlay Widget Tests', () {
    const testViewportSize = Size(600, 800);

    final sampleResult = OcrResult.success(
      pageNumber: 1,
      blocks: const [
        OcrBlock(
          text: 'Democracy in India',
          boundingBox: NormalizedPageRect(
            left: 0.1,
            top: 0.2,
            right: 0.9,
            bottom: 0.4,
          ),
          confidence: OcrConfidence(0.95),
          lines: [
            OcrLine(
              text: 'Democracy in India',
              boundingBox: NormalizedPageRect(
                left: 0.1,
                top: 0.2,
                right: 0.9,
                bottom: 0.4,
              ),
              confidence: OcrConfidence(0.95),
              words: [
                OcrWord(
                  text: 'Democracy',
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
                  text: 'in',
                  boundingBox: NormalizedPageRect(
                    left: 0.47,
                    top: 0.2,
                    right: 0.55,
                    bottom: 0.4,
                  ),
                  confidence: OcrConfidence(0.99),
                  wordIndex: 1,
                ),
                OcrWord(
                  text: 'India',
                  boundingBox: NormalizedPageRect(
                    left: 0.58,
                    top: 0.2,
                    right: 0.85,
                    bottom: 0.4,
                  ),
                  confidence: OcrConfidence(0.96),
                  wordIndex: 2,
                ),
              ],
            ),
          ],
        ),
      ],
      processingDurationMs: 90,
      engineName: 'MockEngine',
      modelIdentifier: 'test-model',
    );

    Widget buildTestOverlay({
      OcrTextSelection? activeSelection,
      void Function(String action, UnifiedTextContext context)? onContextAction,
      void Function(OcrTextSelection?)? onSelectionChanged,
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
                activeSelection: activeSelection,
                onContextAction: onContextAction,
                onSelectionChanged: onSelectionChanged,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
        'renders Dictionary (Define) and Vocabulary buttons for single-word OCR selection',
        (tester) async {
      const singleWordSelection = OcrTextSelection(
        documentId: 'doc_1',
        pageNumber: 1,
        selectedText: 'Democracy',
        startOffset: 0,
        endOffset: 9,
        selectedTokenIndices: [0],
        boundingBoxes: [
          NormalizedPageRect(left: 0.1, top: 0.2, right: 0.45, bottom: 0.4),
        ],
      );

      String? triggeredAction;
      UnifiedTextContext? triggeredContext;

      await tester.pumpWidget(buildTestOverlay(
        activeSelection: singleWordSelection,
        onContextAction: (action, context) {
          triggeredAction = action;
          triggeredContext = context;
        },
      ));

      // Define and Vocabulary buttons must be visible
      final defineButton = find.byKey(const Key('ocr-define-button'));
      final vocabButton = find.byKey(const Key('ocr-vocab-button'));
      final grammarButton = find.byKey(const Key('ocr-grammar-button'));

      expect(defineButton, findsOneWidget);
      expect(vocabButton, findsOneWidget);
      expect(grammarButton, findsNothing);

      // Tap Define button
      await tester.tap(defineButton);
      await tester.pump();

      expect(triggeredAction, 'dictionary');
      expect(triggeredContext, isNotNull);
      expect(triggeredContext!.selectedText, 'Democracy');
      expect(triggeredContext!.isOcr, isTrue);

      // Tap Vocabulary button
      await tester.tap(vocabButton);
      await tester.pump();

      expect(triggeredAction, 'vocabulary');
      expect(triggeredContext!.normalizedWord, 'democracy');
    });

    testWidgets(
        'renders Grammar button and suppresses Define/Vocab for multi-word phrase selection',
        (tester) async {
      const phraseSelection = OcrTextSelection(
        documentId: 'doc_1',
        pageNumber: 1,
        selectedText: 'Democracy in India',
        startOffset: 0,
        endOffset: 18,
        selectedTokenIndices: [0, 1, 2],
        boundingBoxes: [
          NormalizedPageRect(left: 0.1, top: 0.2, right: 0.85, bottom: 0.4),
        ],
      );

      String? triggeredAction;
      UnifiedTextContext? triggeredContext;

      await tester.pumpWidget(buildTestOverlay(
        activeSelection: phraseSelection,
        onContextAction: (action, context) {
          triggeredAction = action;
          triggeredContext = context;
        },
      ));

      // Grammar button must be visible, Define and Vocab hidden
      final grammarButton = find.byKey(const Key('ocr-grammar-button'));
      final defineButton = find.byKey(const Key('ocr-define-button'));
      final vocabButton = find.byKey(const Key('ocr-vocab-button'));

      expect(grammarButton, findsOneWidget);
      expect(defineButton, findsNothing);
      expect(vocabButton, findsNothing);

      // Tap Grammar button
      await tester.tap(grammarButton);
      await tester.pump();

      expect(triggeredAction, 'grammar');
      expect(triggeredContext, isNotNull);
      expect(triggeredContext!.selectedText, 'Democracy in India');
      expect(triggeredContext!.wordCount, 3);
    });
  });
}
