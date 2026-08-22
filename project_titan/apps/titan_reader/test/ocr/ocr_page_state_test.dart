import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_error.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_page_state.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_result.dart';
import 'package:titan_reader/src/domain/entities/ocr/page_text_classification.dart';

void main() {
  group('OcrPageState Domain Tests', () {
    test('initializes with idle factory correctly', () {
      final state = OcrPageState.idle(
        documentId: 'doc_1',
        pageNumber: 1,
      );

      expect(state.documentId, 'doc_1');
      expect(state.pageNumber, 1);
      expect(state.status, OcrProcessingStatus.idle);
      expect(state.isProcessing, isFalse);
      expect(state.hasResult, isFalse);
      expect(state.isOverlayVisible, isFalse);
      expect(state.displayMode, OcrOverlayDisplayMode.textAndBoxes);
      expect(state.progress, 0.0);
      expect(state.result, isNull);
    });

    test('processing factory constructs active processing state', () {
      final state = OcrPageState.processing(
        documentId: 'doc_1',
        pageNumber: 2,
        progress: 0.45,
      );

      expect(state.status, OcrProcessingStatus.processing);
      expect(state.isProcessing, isTrue);
      expect(state.progress, 0.45);
      expect(state.hasResult, isFalse);
    });

    test('completed factory captures success result and enables overlay', () {
      final result = OcrResult.success(
        pageNumber: 1,
        blocks: const [],
        processingDurationMs: 120,
        engineName: 'MockEngine',
        modelIdentifier: 'test-model',
      );

      final state = OcrPageState.completed(
        documentId: 'doc_1',
        pageNumber: 1,
        result: result,
      );

      expect(state.status, OcrProcessingStatus.completed);
      expect(state.hasResult, isTrue);
      expect(state.isOverlayVisible, isTrue);
      expect(state.progress, 1.0);
      expect(state.result?.engineName, 'MockEngine');
    });

    test('error factory captures error code and message', () {
      final state = OcrPageState.error(
        documentId: 'doc_1',
        pageNumber: 3,
        errorMessage: 'Model initialization failed',
        errorCode: OcrErrorCode.initializationFailure,
      );

      expect(state.status, OcrProcessingStatus.error);
      expect(state.errorMessage, 'Model initialization failed');
      expect(state.errorCode, OcrErrorCode.initializationFailure);
      expect(state.hasResult, isFalse);
      expect(state.isOverlayVisible, isFalse);
    });

    test('skipped factory records page classification', () {
      final classification = PageTextClassification.nativeText(
        pageNumber: 4,
        characterCount: 650,
      );

      final state = OcrPageState.skipped(
        documentId: 'doc_1',
        pageNumber: 4,
        classification: classification,
      );

      expect(state.status, OcrProcessingStatus.skipped);
      expect(state.classification?.category, PageTextCategory.nativeText);
      expect(state.isOverlayVisible, isFalse);
    });

    test('copyWith updates fields immutably', () {
      final initial = OcrPageState.idle(documentId: 'doc_1', pageNumber: 1);
      final updated = initial.copyWith(
        status: OcrProcessingStatus.processing,
        progress: 0.75,
        displayMode: OcrOverlayDisplayMode.boundingBoxesOnly,
      );

      expect(updated.status, OcrProcessingStatus.processing);
      expect(updated.progress, 0.75);
      expect(updated.displayMode, OcrOverlayDisplayMode.boundingBoxesOnly);
      expect(updated.documentId, 'doc_1');
      expect(updated.pageNumber, 1);
    });

    test('serializes and deserializes JSON cleanly', () {
      final result = OcrResult.success(
        pageNumber: 1,
        blocks: const [],
        processingDurationMs: 80,
        engineName: 'MockEngine',
        modelIdentifier: 'test-model',
      );

      final state = OcrPageState.completed(
        documentId: 'doc_json',
        pageNumber: 2,
        result: result,
        displayMode: OcrOverlayDisplayMode.boundingBoxesOnly,
      );

      final json = state.toJson();
      final deserialized = OcrPageState.fromJson(json);

      expect(deserialized.documentId, 'doc_json');
      expect(deserialized.pageNumber, 2);
      expect(deserialized.status, OcrProcessingStatus.completed);
      expect(deserialized.displayMode, OcrOverlayDisplayMode.boundingBoxesOnly);
      expect(deserialized.result?.processingDurationMs, 80);
    });
  });
}
