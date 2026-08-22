import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_error.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_page_state.dart';
import 'package:titan_reader/src/domain/entities/ocr/page_text_classification.dart';
import 'package:titan_reader/src/ocr/mock_ocr_engine.dart';
import 'package:titan_reader/src/providers/ocr_providers.dart';

void main() {
  group('OcrPageNotifier & Controller Tests', () {
    late ProviderContainer container;
    late MockOcrEngine mockEngine;

    setUp(() {
      mockEngine = MockOcrEngine();
      container = ProviderContainer(
        overrides: [
          ocrEngineProvider.overrideWithValue(mockEngine),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is idle with default display mode', () {
      const key = OcrPageKey(documentId: 'doc_ctrl', pageNumber: 1);
      final state = container.read(ocrPageStateProvider(key));

      expect(state.documentId, 'doc_ctrl');
      expect(state.pageNumber, 1);
      expect(state.status, OcrProcessingStatus.idle);
      expect(state.displayMode, OcrOverlayDisplayMode.textAndBoxes);
    });

    test('runOcr executes full pipeline and produces completed state',
        () async {
      const key = OcrPageKey(documentId: 'doc_ctrl', pageNumber: 1);
      final notifier = container.read(ocrPageStateProvider(key).notifier);

      final future = notifier.runOcr(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageWidth: 600,
        imageHeight: 800,
        pageWidth: 600,
        pageHeight: 800,
        characterCount: 0,
        rasterImageCount: 1,
      );

      await future;

      final state = container.read(ocrPageStateProvider(key));
      expect(state.status, OcrProcessingStatus.completed);
      expect(state.hasResult, isTrue);
      expect(state.result?.fullText, 'PROJECT TITAN');
      expect(state.classification?.category, PageTextCategory.imageOnly);
    });

    test('runOcr skips OCR when page has native digital text and not forced',
        () async {
      const key = OcrPageKey(documentId: 'doc_ctrl', pageNumber: 2);
      final notifier = container.read(ocrPageStateProvider(key).notifier);

      await notifier.runOcr(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageWidth: 600,
        imageHeight: 800,
        pageWidth: 600,
        pageHeight: 800,
        characterCount: 500,
        rasterImageCount: 0,
        force: false,
      );

      final state = container.read(ocrPageStateProvider(key));
      expect(state.status, OcrProcessingStatus.skipped);
      expect(state.classification?.category, PageTextCategory.nativeText);
      expect(state.hasResult, isFalse);
    });

    test('runOcr forces OCR when force is true even on native text page',
        () async {
      const key = OcrPageKey(documentId: 'doc_ctrl', pageNumber: 2);
      final notifier = container.read(ocrPageStateProvider(key).notifier);

      await notifier.runOcr(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageWidth: 600,
        imageHeight: 800,
        pageWidth: 600,
        pageHeight: 800,
        characterCount: 500,
        rasterImageCount: 0,
        force: true,
      );

      final state = container.read(ocrPageStateProvider(key));
      expect(state.status, OcrProcessingStatus.completed);
      expect(state.hasResult, isTrue);
    });

    test('runOcr transitions to error state on engine failure', () async {
      final failingEngine = MockOcrEngine(
        simulatedFailure: const OcrException(
          code: OcrErrorCode.processingFailure,
          message: 'Low memory condition during recognition.',
        ),
      );
      final errorContainer = ProviderContainer(
        overrides: [
          ocrEngineProvider.overrideWithValue(failingEngine),
        ],
      );
      addTearDown(errorContainer.dispose);

      const key = OcrPageKey(documentId: 'doc_err', pageNumber: 1);
      final notifier = errorContainer.read(ocrPageStateProvider(key).notifier);

      await notifier.runOcr(
        imageBytes: Uint8List.fromList([1]),
        imageWidth: 100,
        imageHeight: 100,
        pageWidth: 100,
        pageHeight: 100,
      );

      final state = errorContainer.read(ocrPageStateProvider(key));
      expect(state.status, OcrProcessingStatus.error);
      expect(state.errorCode, OcrErrorCode.processingFailure);
      expect(state.errorMessage, contains('Low memory condition'));
    });

    test('setDisplayMode updates displayMode without resetting result',
        () async {
      const key = OcrPageKey(documentId: 'doc_ctrl', pageNumber: 1);
      final notifier = container.read(ocrPageStateProvider(key).notifier);

      await notifier.runOcr(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageWidth: 600,
        imageHeight: 800,
        pageWidth: 600,
        pageHeight: 800,
      );

      notifier.setDisplayMode(OcrOverlayDisplayMode.boundingBoxesOnly);
      var state = container.read(ocrPageStateProvider(key));
      expect(state.displayMode, OcrOverlayDisplayMode.boundingBoxesOnly);
      expect(state.hasResult, isTrue);

      notifier.setDisplayMode(OcrOverlayDisplayMode.hidden);
      state = container.read(ocrPageStateProvider(key));
      expect(state.displayMode, OcrOverlayDisplayMode.hidden);
      expect(state.isOverlayVisible, isFalse);
    });

    test('reset clears state back to idle', () async {
      const key = OcrPageKey(documentId: 'doc_ctrl', pageNumber: 1);
      final notifier = container.read(ocrPageStateProvider(key).notifier);

      await notifier.runOcr(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageWidth: 600,
        imageHeight: 800,
        pageWidth: 600,
        pageHeight: 800,
      );

      notifier.reset();
      final state = container.read(ocrPageStateProvider(key));
      expect(state.status, OcrProcessingStatus.idle);
      expect(state.result, isNull);
    });
  });
}
