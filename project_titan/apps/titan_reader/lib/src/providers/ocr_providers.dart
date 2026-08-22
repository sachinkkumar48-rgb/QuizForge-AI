import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/ocr/ocr_error.dart';
import '../domain/entities/ocr/ocr_page_state.dart';
import '../domain/entities/ocr/ocr_request.dart';
import '../domain/entities/ocr/page_text_classification.dart';
import '../ocr/ocr_engine.dart';
import '../ocr/onnx/onnx_ocr_engine.dart';
import '../ocr/page_text_classifier.dart';
import '../services/ocr_service.dart';

/// Provider for the abstract [PageTextClassifier] instance.
final pageClassifierProvider = Provider<PageTextClassifier>((ref) {
  return const PageTextClassifier();
});

/// Provider for the active [OcrEngine] implementation.
///
/// Can be overridden in tests with [MockOcrEngine].
final ocrEngineProvider = Provider<OcrEngine>((ref) {
  final engine = OnnxOcrEngine();
  ref.onDispose(() {
    engine.dispose();
  });
  return engine;
});

/// Provider for the application [OcrService] coordinator.
final ocrServiceProvider = Provider<OcrService>((ref) {
  final engine = ref.watch(ocrEngineProvider);
  final classifier = ref.watch(pageClassifierProvider);
  return OcrService(
    engine: engine,
    classifier: classifier,
  );
});

/// Composite immutable key identifying an OCR page task by document and page number.
@immutable
class OcrPageKey {
  final String documentId;
  final int pageNumber;

  const OcrPageKey({
    required this.documentId,
    required this.pageNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrPageKey &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          pageNumber == other.pageNumber;

  @override
  int get hashCode => Object.hash(documentId, pageNumber);

  @override
  String toString() => 'OcrPageKey($documentId, p: $pageNumber)';
}

/// Global default display mode provider for OCR overlays.
final ocrGlobalDisplayModeProvider = StateProvider<OcrOverlayDisplayMode>(
    (ref) => OcrOverlayDisplayMode.textAndBoxes);

/// StateNotifier managing OCR state, classification, execution, and overlay modes for a specific page.
class OcrPageNotifier extends StateNotifier<OcrPageState> {
  final OcrService _ocrService;

  OcrPageNotifier({
    required OcrService ocrService,
    required String documentId,
    required int pageNumber,
    OcrOverlayDisplayMode initialDisplayMode =
        OcrOverlayDisplayMode.textAndBoxes,
  })  : _ocrService = ocrService,
        super(OcrPageState.idle(
          documentId: documentId,
          pageNumber: pageNumber,
          displayMode: initialDisplayMode,
        ));

  /// Changes the visual overlay display mode for this page.
  void setDisplayMode(OcrOverlayDisplayMode mode) {
    state = state.copyWith(displayMode: mode);
  }

  /// Sets the state to skipped when native text or other conditions bypass OCR.
  void setSkipped(PageTextClassification classification) {
    state = OcrPageState.skipped(
      documentId: state.documentId,
      pageNumber: state.pageNumber,
      classification: classification,
      displayMode: state.displayMode,
    );
  }

  /// Resets this page state back to idle.
  void reset() {
    state = OcrPageState.idle(
      documentId: state.documentId,
      pageNumber: state.pageNumber,
      displayMode: state.displayMode,
    );
  }

  /// Runs the full OCR processing workflow on this page.
  Future<void> runOcr({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
    required double pageWidth,
    required double pageHeight,
    int? characterCount,
    int? rasterImageCount,
    bool force = false,
  }) async {
    // 1. Classification check if metrics supplied
    PageTextClassification? classification;
    if (characterCount != null && rasterImageCount != null) {
      classification = _ocrService.classifyPage(
        pageNumber: state.pageNumber,
        characterCount: characterCount,
        rasterImageCount: rasterImageCount,
      );

      // If page is digital text and not forced, mark skipped
      if (classification.category == PageTextCategory.nativeText && !force) {
        state = OcrPageState.skipped(
          documentId: state.documentId,
          pageNumber: state.pageNumber,
          classification: classification,
          displayMode: state.displayMode,
        );
        return;
      }
    }

    // 2. Set processing state
    state = OcrPageState.processing(
      documentId: state.documentId,
      pageNumber: state.pageNumber,
      progress: 0.2,
      classification: classification,
      displayMode: state.displayMode,
    );

    final request = OcrRequest(
      documentId: state.documentId,
      pageNumber: state.pageNumber,
      imageBytes: imageBytes,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
    );

    try {
      state = state.copyWith(progress: 0.6);
      final result = await _ocrService.processPage(request);

      if (result.isSuccess) {
        state = OcrPageState.completed(
          documentId: state.documentId,
          pageNumber: state.pageNumber,
          result: result,
          classification: classification,
          displayMode: state.displayMode,
        );
      } else if (result.isCancelled) {
        state = OcrPageState.idle(
          documentId: state.documentId,
          pageNumber: state.pageNumber,
          displayMode: state.displayMode,
        );
      } else {
        state = OcrPageState.error(
          documentId: state.documentId,
          pageNumber: state.pageNumber,
          errorMessage: result.errorMessage ?? 'OCR recognition failed.',
          errorCode: result.errorCode ?? OcrErrorCode.processingFailure,
          classification: classification,
          displayMode: state.displayMode,
        );
      }
    } catch (e) {
      state = OcrPageState.error(
        documentId: state.documentId,
        pageNumber: state.pageNumber,
        errorMessage: 'Unexpected OCR error: $e',
        errorCode: OcrErrorCode.processingFailure,
        classification: classification,
        displayMode: state.displayMode,
      );
    }
  }
}

/// Provider family for managing the OCR state of a specific document page.
final ocrPageStateProvider =
    StateNotifierProvider.family<OcrPageNotifier, OcrPageState, OcrPageKey>(
        (ref, key) {
  final service = ref.watch(ocrServiceProvider);
  final globalMode = ref.watch(ocrGlobalDisplayModeProvider);
  return OcrPageNotifier(
    ocrService: service,
    documentId: key.documentId,
    pageNumber: key.pageNumber,
    initialDisplayMode: globalMode,
  );
});
