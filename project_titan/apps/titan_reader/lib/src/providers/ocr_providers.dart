import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/ocr/ocr_error.dart';
import '../domain/entities/ocr/ocr_page_state.dart';
import '../domain/entities/ocr/ocr_request.dart';
import '../domain/entities/ocr/ocr_search_selection.dart';
import '../domain/entities/ocr/page_text_classification.dart';
import '../ocr/ocr_engine.dart';
import '../ocr/onnx/onnx_ocr_engine.dart';
import '../ocr/page_text_classifier.dart';
import '../pdf/pdf_engine_contracts.dart';
import '../services/ocr_service.dart';
import '../services/pdf_searchable_export_service.dart';

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

/// Provider for the [PdfSearchableExportService] coordinator.
final searchablePdfExportServiceProvider =
    Provider<PdfSearchableExportService>((ref) {
  return const PdfSearchableExportService();
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

/// Provider family computing the [NormalizedOcrPageText] model for an OCR-completed page.
final ocrNormalizedTextProvider =
    Provider.family<NormalizedOcrPageText?, OcrPageKey>((ref, key) {
  final pageState = ref.watch(ocrPageStateProvider(key));
  final result = pageState.result;
  if (result == null || !result.isSuccess) return null;
  return NormalizedOcrPageText.fromOcrResult(
    documentId: key.documentId,
    result: result,
  );
});

/// Active search query string for OCR in-page search.
final ocrSearchQueryProvider = StateProvider<String>((ref) => '');

/// Whether OCR search should be case sensitive.
final ocrSearchCaseSensitiveProvider = StateProvider<bool>((ref) => false);

/// Whether OCR search should match whole words only.
final ocrSearchWholeWordProvider = StateProvider<bool>((ref) => false);

/// Provider family returning the list of [OcrSearchMatch] for a specific page.
final ocrPageSearchMatchesProvider =
    Provider.family<List<OcrSearchMatch>, OcrPageKey>((ref, key) {
  final normText = ref.watch(ocrNormalizedTextProvider(key));
  if (normText == null) return const [];
  final query = ref.watch(ocrSearchQueryProvider);
  if (query.trim().isEmpty) return const [];
  final caseSensitive = ref.watch(ocrSearchCaseSensitiveProvider);
  final wholeWord = ref.watch(ocrSearchWholeWordProvider);
  return normText.search(
    query,
    caseSensitive: caseSensitive,
    wholeWord: wholeWord,
  );
});

/// Active OCR search match index on a specific page.
final ocrActiveSearchMatchIndexProvider =
    StateProvider.family<int?, OcrPageKey>((ref, key) => null);

/// Active OCR text selection on a specific page.
final ocrActiveSelectionProvider =
    StateProvider.family<OcrTextSelection?, OcrPageKey>((ref, key) => null);

/// Service for copying OCR text selections safely to the system clipboard.
class OcrClipboardService {
  const OcrClipboardService();

  /// Copies the selected text to the clipboard without external logging.
  Future<bool> copySelection(OcrTextSelection? selection) async {
    if (selection == null || selection.selectedText.isEmpty) return false;
    try {
      await Clipboard.setData(ClipboardData(text: selection.selectedText));
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Provider for the [OcrClipboardService] instance.
final ocrClipboardServiceProvider = Provider<OcrClipboardService>((ref) {
  return const OcrClipboardService();
});

/// Utility for combining native PDF search matches and OCR search matches
/// according to the TITAN Reader coexistence policy.
class UnifiedSearchCoexistence {
  const UnifiedSearchCoexistence();

  /// Merges native search matches and OCR search matches.
  ///
  /// - Native text matches remain authoritative.
  /// - OCR matches on image-only or scanned pages are included.
  /// - Obvious duplicates on the same page with identical snippet text are filtered.
  /// - Results are ordered deterministically by page number and match index.
  static List<PdfSearchMatch> mergeMatches({
    required List<PdfSearchMatch> nativeMatches,
    required List<OcrSearchMatch> ocrMatches,
    Set<int> nativeTextPages = const {},
  }) {
    final unified = <PdfSearchMatch>[];
    final seenPageSnippets = <String>{};

    // 1. Add authoritative native matches
    for (final match in nativeMatches) {
      unified.add(match);
      seenPageSnippets.add('${match.pageNumber}:${match.snippet.trim()}');
    }

    // 2. Add non-duplicate OCR matches
    for (final match in ocrMatches) {
      final key = '${match.pageNumber}:${match.snippet.trim()}';
      if (!seenPageSnippets.contains(key)) {
        seenPageSnippets.add(key);
        unified.add(match.toPdfSearchMatch(unified.length));
      }
    }

    // 3. Sort deterministically by page number, then original match index
    unified.sort((a, b) {
      final pageComp = a.pageNumber.compareTo(b.pageNumber);
      if (pageComp != 0) return pageComp;
      return a.index.compareTo(b.index);
    });

    // 4. Re-index sequentially
    return List.unmodifiable([
      for (var i = 0; i < unified.length; i++)
        PdfSearchMatch(
          index: i,
          pageNumber: unified[i].pageNumber,
          snippet: unified[i].snippet,
        ),
    ]);
  }
}
