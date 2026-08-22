import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_confidence.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_result.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_search_selection.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_text_region.dart';
import 'package:titan_reader/src/providers/ocr_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OCR Selection & Clipboard Tests', () {
    const docId = 'doc_test_select';

    final sampleResult = OcrResult.success(
      pageNumber: 2,
      blocks: const [
        OcrBlock(
          text: 'Right to Equality',
          boundingBox: NormalizedPageRect(
            left: 0.1,
            top: 0.2,
            right: 0.8,
            bottom: 0.35,
          ),
          confidence: OcrConfidence(0.96),
          lines: [
            OcrLine(
              text: 'Right to Equality',
              boundingBox: NormalizedPageRect(
                left: 0.1,
                top: 0.2,
                right: 0.8,
                bottom: 0.35,
              ),
              confidence: OcrConfidence(0.96),
              words: [
                OcrWord(
                  text: 'Right',
                  boundingBox: NormalizedPageRect(
                    left: 0.1,
                    top: 0.2,
                    right: 0.3,
                    bottom: 0.35,
                  ),
                  confidence: OcrConfidence(0.98),
                  wordIndex: 0,
                ),
                OcrWord(
                  text: 'to',
                  boundingBox: NormalizedPageRect(
                    left: 0.32,
                    top: 0.2,
                    right: 0.45,
                    bottom: 0.35,
                  ),
                  confidence: OcrConfidence(0.99),
                  wordIndex: 1,
                ),
                OcrWord(
                  text: 'Equality',
                  boundingBox: NormalizedPageRect(
                    left: 0.48,
                    top: 0.2,
                    right: 0.8,
                    bottom: 0.35,
                  ),
                  confidence: OcrConfidence(0.94),
                  wordIndex: 2,
                ),
              ],
            ),
          ],
        ),
      ],
      processingDurationMs: 80,
      engineName: 'MockEngine',
      modelIdentifier: 'test-model',
    );

    test('creates OcrTextSelection from character offset range', () {
      final normText = NormalizedOcrPageText.fromOcrResult(
        documentId: docId,
        result: sampleResult,
      );

      final selection = normText.createSelectionFromOffsets(0, 17);
      expect(selection, isNotNull);
      expect(selection!.selectedText, 'Right to Equality');
      expect(selection.documentId, docId);
      expect(selection.pageNumber, 2);
      expect(selection.selectedTokenIndices, [0, 1, 2]);
      expect(selection.boundingBoxes.length, 3);
    });

    test('creates OcrTextSelection from token indices', () {
      final normText = NormalizedOcrPageText.fromOcrResult(
        documentId: docId,
        result: sampleResult,
      );

      // Select 'Equality' (token 2)
      final selection = normText.createSelectionFromTokens([2]);
      expect(selection, isNotNull);
      expect(selection!.selectedText, 'Equality');
      expect(selection.selectedTokenIndices, [2]);
      expect(selection.boundingBoxes.length, 1);
    });

    test('converts OcrTextSelection to standard PdfTextSelectionSnapshot', () {
      const selection = OcrTextSelection(
        documentId: docId,
        pageNumber: 2,
        selectedText: 'Right to Equality',
        startOffset: 0,
        endOffset: 17,
        selectedTokenIndices: [0, 1, 2],
        boundingBoxes: [
          NormalizedPageRect(left: 0.1, top: 0.2, right: 0.8, bottom: 0.35),
        ],
      );

      final snapshot = selection.toSnapshot();
      expect(snapshot.text, 'Right to Equality');
      expect(snapshot.fragments.length, 1);
      expect(snapshot.fragments.first.pageNumber, 2);
      expect(snapshot.fragments.first.rect.left, 0.1);
    });

    test('serializes and deserializes OcrTextSelection cleanly', () {
      const selection = OcrTextSelection(
        documentId: 'doc_42',
        pageNumber: 5,
        selectedText: 'Judicial Review',
        startOffset: 10,
        endOffset: 25,
        selectedTokenIndices: [3, 4],
        boundingBoxes: [
          NormalizedPageRect(left: 0.2, top: 0.3, right: 0.6, bottom: 0.4),
        ],
      );

      final json = selection.toJson();
      final deserialized = OcrTextSelection.fromJson(json);

      expect(deserialized.documentId, 'doc_42');
      expect(deserialized.pageNumber, 5);
      expect(deserialized.selectedText, 'Judicial Review');
      expect(deserialized.selectedTokenIndices, [3, 4]);
      expect(deserialized.boundingBoxes.length, 1);
    });

    test('OcrClipboardService copies selected text to clipboard without error',
        () async {
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

      const clipboardService = OcrClipboardService();

      const selection = OcrTextSelection(
        documentId: docId,
        pageNumber: 2,
        selectedText: 'Right to Freedom',
        startOffset: 0,
        endOffset: 16,
        selectedTokenIndices: [0, 1, 2],
        boundingBoxes: [],
      );

      final copied = await clipboardService.copySelection(selection);
      expect(copied, isTrue);
      expect(clipboardText, 'Right to Freedom');
    });

    test('OcrClipboardService handles null or empty selection safely',
        () async {
      const clipboardService = OcrClipboardService();

      final nullResult = await clipboardService.copySelection(null);
      expect(nullResult, isFalse);

      const emptySelection = OcrTextSelection(
        documentId: docId,
        pageNumber: 1,
        selectedText: '',
        startOffset: 0,
        endOffset: 0,
        selectedTokenIndices: [],
        boundingBoxes: [],
      );

      final emptyResult = await clipboardService.copySelection(emptySelection);
      expect(emptyResult, isFalse);
    });
  });
}
