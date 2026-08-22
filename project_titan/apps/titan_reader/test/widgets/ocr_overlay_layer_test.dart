import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_confidence.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_error.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_page_state.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_result.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_text_region.dart';
import 'package:titan_reader/src/widgets/ocr/ocr_overlay_layer.dart';

void main() {
  group('OcrOverlayLayer Widget Tests', () {
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
                  confidence: OcrConfidence(0.70), // Medium confidence (Amber)
                  wordIndex: 1,
                ),
              ],
            ),
          ],
        ),
      ],
      processingDurationMs: 150,
      engineName: 'MockEngine',
      modelIdentifier: 'test-model',
    );

    Widget buildOverlay({
      int pageNumber = 1,
      Size viewportSize = testViewportSize,
      OcrResult? result,
      OcrPageState? pageState,
      OcrOverlayDisplayMode displayMode = OcrOverlayDisplayMode.textAndBoxes,
      void Function(OcrWord)? onWordTap,
      void Function(OcrLine)? onLineTap,
      VoidCallback? onRetry,
      VoidCallback? onCancel,
      void Function(OcrOverlayDisplayMode)? onDisplayModeChanged,
      bool showControlBadge = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: viewportSize.width,
            height: viewportSize.height,
            child: OcrOverlayLayer(
              pageNumber: pageNumber,
              viewportSize: viewportSize,
              result: result,
              pageState: pageState,
              displayMode: displayMode,
              onWordTap: onWordTap,
              onLineTap: onLineTap,
              onRetry: onRetry,
              onCancel: onCancel,
              onDisplayModeChanged: onDisplayModeChanged,
              showControlBadge: showControlBadge,
            ),
          ),
        ),
      );
    }

    testWidgets(
        'renders word bounding boxes and text labels in textAndBoxes mode',
        (tester) async {
      await tester.pumpWidget(buildOverlay(
        result: sampleResult,
        displayMode: OcrOverlayDisplayMode.textAndBoxes,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ocr-word-0-TITAN')), findsOneWidget);
      expect(find.byKey(const Key('ocr-word-1-READER')), findsOneWidget);
      expect(find.text('TITAN'), findsOneWidget);
      expect(find.text('READER'), findsOneWidget);
      expect(find.byKey(const Key('ocr-summary-text')), findsOneWidget);
      expect(find.text('OCR: 2 words (84%)'), findsOneWidget);
    });

    testWidgets(
        'renders bounding boxes without text labels in boundingBoxesOnly mode',
        (tester) async {
      await tester.pumpWidget(buildOverlay(
        result: sampleResult,
        displayMode: OcrOverlayDisplayMode.boundingBoxesOnly,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ocr-word-0-TITAN')), findsOneWidget);
      expect(find.byKey(const Key('ocr-word-1-READER')), findsOneWidget);
      // In boundingBoxesOnly mode, the text inside the boxes is not painted
      expect(find.text('TITAN'), findsNothing);
      expect(find.text('READER'), findsNothing);
    });

    testWidgets('renders nothing when displayMode is hidden', (tester) async {
      await tester.pumpWidget(buildOverlay(
        result: sampleResult,
        displayMode: OcrOverlayDisplayMode.hidden,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ocr-word-0-TITAN')), findsNothing);
      expect(find.byKey(const Key('ocr-word-1-READER')), findsNothing);
      expect(find.byKey(const Key('ocr-summary-text')), findsNothing);
    });

    testWidgets('tapping a word box invokes onWordTap callback',
        (tester) async {
      OcrWord? tappedWord;

      await tester.pumpWidget(buildOverlay(
        result: sampleResult,
        onWordTap: (word) => tappedWord = word,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ocr-word-0-TITAN')));
      await tester.pumpAndSettle();

      expect(tappedWord, isNotNull);
      expect(tappedWord?.text, 'TITAN');
      expect(tappedWord?.confidence.value, 0.98);
    });

    testWidgets('renders in-page progress indicator and handles cancel',
        (tester) async {
      var cancelled = false;
      final processingState = OcrPageState.processing(
        documentId: 'doc_1',
        pageNumber: 3,
        progress: 0.6,
      );

      await tester.pumpWidget(buildOverlay(
        pageNumber: 3,
        pageState: processingState,
        onCancel: () => cancelled = true,
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('ocr-progress-card')), findsOneWidget);
      expect(find.byKey(const Key('ocr-progress-spinner')), findsOneWidget);
      expect(find.text('Recognizing page 3 text…'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ocr-cancel-button')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(cancelled, isTrue);
    });

    testWidgets('renders error banner and handles retry action',
        (tester) async {
      var retried = false;
      final errorState = OcrPageState.error(
        documentId: 'doc_1',
        pageNumber: 1,
        errorMessage: 'OCR Engine memory exceeded.',
        errorCode: OcrErrorCode.processingFailure,
      );

      await tester.pumpWidget(buildOverlay(
        pageNumber: 1,
        pageState: errorState,
        onRetry: () => retried = true,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ocr-error-card')), findsOneWidget);
      expect(find.text('OCR Engine memory exceeded.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ocr-retry-button')));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });

    testWidgets(
        'toggles display mode when mode toggle button is tapped in badge',
        (tester) async {
      OcrOverlayDisplayMode? updatedMode;

      await tester.pumpWidget(buildOverlay(
        result: sampleResult,
        displayMode: OcrOverlayDisplayMode.textAndBoxes,
        onDisplayModeChanged: (m) => updatedMode = m,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ocr-mode-toggle-button')));
      await tester.pumpAndSettle();

      expect(updatedMode, OcrOverlayDisplayMode.boundingBoxesOnly);
    });

    testWidgets('transforms normalized coordinates to pixel space accurately',
        (tester) async {
      await tester.pumpWidget(buildOverlay(
        result: sampleResult,
        viewportSize: const Size(1000, 2000),
      ));
      await tester.pumpAndSettle();

      // Word 0: left: 0.1 * 1000 = 100, top: 0.2 * 2000 = 400
      final wordFinder = find.byKey(const Key('ocr-word-0-TITAN'));
      final wordTopLeft = tester.getTopLeft(wordFinder);

      expect(wordTopLeft.dx, closeTo(100.0, 0.1));
      expect(wordTopLeft.dy, closeTo(400.0, 0.1));
    });
  });
}
