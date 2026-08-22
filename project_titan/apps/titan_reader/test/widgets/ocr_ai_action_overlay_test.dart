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
  group('OCR AI Action Overlay Widget Tests', () {
    const testViewportSize = Size(600, 800);

    final sampleResult = OcrResult.success(
      pageNumber: 1,
      blocks: const [
        OcrBlock(
          text: 'Liberty Equality Fraternity',
          boundingBox: NormalizedPageRect(
            left: 0.1,
            top: 0.2,
            right: 0.9,
            bottom: 0.35,
          ),
          confidence: OcrConfidence(0.96),
          lines: [
            OcrLine(
              text: 'Liberty Equality Fraternity',
              boundingBox: NormalizedPageRect(
                left: 0.1,
                top: 0.2,
                right: 0.9,
                bottom: 0.35,
              ),
              confidence: OcrConfidence(0.96),
              words: [
                OcrWord(
                  text: 'Liberty',
                  boundingBox: NormalizedPageRect(
                    left: 0.1,
                    top: 0.2,
                    right: 0.35,
                    bottom: 0.35,
                  ),
                  confidence: OcrConfidence(0.98),
                  wordIndex: 0,
                ),
                OcrWord(
                  text: 'Equality',
                  boundingBox: NormalizedPageRect(
                    left: 0.38,
                    top: 0.2,
                    right: 0.62,
                    bottom: 0.35,
                  ),
                  confidence: OcrConfidence(0.97),
                  wordIndex: 1,
                ),
                OcrWord(
                  text: 'Fraternity',
                  boundingBox: NormalizedPageRect(
                    left: 0.65,
                    top: 0.2,
                    right: 0.9,
                    bottom: 0.35,
                  ),
                  confidence: OcrConfidence(0.95),
                  wordIndex: 2,
                ),
              ],
            ),
          ],
        ),
      ],
      processingDurationMs: 85,
      engineName: 'MockEngine',
      modelIdentifier: 'test-model',
    );

    testWidgets(
        'renders Ask AI Assistant button and triggers callback on tap with unified context',
        (tester) async {
      const selection = OcrTextSelection(
        documentId: 'doc_preamble',
        pageNumber: 1,
        selectedText: 'Liberty Equality Fraternity',
        startOffset: 0,
        endOffset: 27,
        selectedTokenIndices: [0, 1, 2],
        boundingBoxes: [
          NormalizedPageRect(left: 0.1, top: 0.2, right: 0.9, bottom: 0.35),
        ],
      );

      String? triggeredAction;
      UnifiedTextContext? triggeredContext;

      await tester.pumpWidget(MaterialApp(
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
                activeSelection: selection,
                onContextAction: (action, context) {
                  triggeredAction = action;
                  triggeredContext = context;
                },
              ),
            ),
          ),
        ),
      ));

      final aiButton = find.byKey(const Key('ocr-ai-button'));
      expect(aiButton, findsOneWidget);

      await tester.tap(aiButton);
      await tester.pump();

      expect(triggeredAction, 'ai');
      expect(triggeredContext, isNotNull);
      expect(triggeredContext!.selectedText, 'Liberty Equality Fraternity');
      expect(triggeredContext!.isOcr, isTrue);
      expect(triggeredContext!.pageNumber, 1);
      expect(triggeredContext!.documentId, 'doc_preamble');
    });
  });
}
