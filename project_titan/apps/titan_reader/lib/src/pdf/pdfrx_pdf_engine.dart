import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'pdf_engine_contracts.dart';

/// [PdfDocumentEngine] implementation backed by the pdfrx/PDFium stack.
///
/// This adapter is the ONLY place in the application that imports pdfrx
/// (see ADR-0004). Everything outside `src/pdf/` depends solely on
/// [PdfDocumentEngine]/[PdfViewerHandle] contracts.
class PdfrxPdfEngine implements PdfDocumentEngine {
  const PdfrxPdfEngine();

  @override
  String get engineName => 'pdfrx (PDFium)';

  @override
  PdfViewerHandle createHandle() => PdfrxViewerHandle();

  @override
  Widget buildViewer({
    required String filePath,
    required PdfViewerSettings settings,
    required PdfViewerHandle handle,
  }) {
    final pdfrxHandle = handle as PdfrxViewerHandle;
    return pdfrxHandle.buildViewer(filePath, settings);
  }
}

/// [PdfViewerHandle] bound to a pdfrx [PdfViewerController] and
/// [PdfTextSearcher].
class PdfrxViewerHandle implements PdfViewerHandle {
  PdfrxViewerHandle() {
    _searcher.addListener(_onSearchChanged);
  }

  /// Controller driving the underlying pdfrx viewer.
  final PdfViewerController controller = PdfViewerController();

  /// pdfrx text-search session bound to [controller].
  late final PdfTextSearcher _searcher = PdfTextSearcher(controller);

  final List<void Function(int?)> _pageListeners = [];
  final List<VoidCallback> _searchListeners = [];
  int _rotationQuarterTurns = 0;
  bool _disposed = false;

  @override
  bool get isReady => controller.isReady;

  @override
  int? get currentPageNumber =>
      controller.isReady ? controller.pageNumber : null;

  @override
  int? get pageCount => controller.isReady ? controller.pageCount : null;

  @override
  void addPageChangedListener(void Function(int? pageNumber) listener) =>
      _pageListeners.add(listener);

  @override
  void removePageChangedListener(void Function(int? pageNumber) listener) =>
      _pageListeners.remove(listener);

  void _notifyViewChanged() {
    final page = currentPageNumber;
    for (final listener in List<void Function(int?)>.of(_pageListeners)) {
      listener(page);
    }
  }

  @override
  Future<void> goToPage(int pageNumber) async {
    if (!controller.isReady) return;
    final clamped = pageNumber.clamp(1, controller.pageCount);
    await controller.goToPage(pageNumber: clamped);
  }

  @override
  Future<void> zoomIn() async {
    if (controller.isReady) {
      await controller.zoomUp();
    }
  }

  @override
  Future<void> zoomOut() async {
    if (controller.isReady) {
      await controller.zoomDown();
    }
  }

  @override
  Future<void> applyFitMode(PdfFitMode mode) async {
    if (!controller.isReady) return;
    final page = controller.pageNumber ?? 1;
    final matrix = mode == PdfFitMode.fitWidth
        ? controller.calcMatrixFitWidthForPage(pageNumber: page)
        : controller.calcMatrixForFit(pageNumber: page);
    if (matrix != null) {
      await controller.goTo(matrix);
    }
  }

  @override
  void rotateClockwise() {
    _rotationQuarterTurns = (_rotationQuarterTurns + 1) & 3;
    _notifyViewChanged();
  }

  @override
  int get rotationQuarterTurns => _rotationQuarterTurns;

  @override
  Future<void> startSearch(String query) async {
    if (query.trim().isEmpty) {
      await clearSearch();
      return;
    }
    _searcher.startTextSearch(
      query,
      caseInsensitive: true,
      goToFirstMatch: true,
      searchImmediately: true,
    );
  }

  @override
  Future<void> clearSearch() async {
    _searcher.resetTextSearch();
  }

  @override
  List<PdfSearchMatch> get searchMatches {
    final matches = _searcher.matches;
    final result = <PdfSearchMatch>[];
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      result.add(PdfSearchMatch(
        index: i,
        pageNumber: match.pageNumber,
        snippet: match.text,
      ));
    }
    return result;
  }

  @override
  int? get currentSearchMatchIndex => _searcher.currentIndex;

  @override
  bool get isSearchActive => _searcher.pattern != null;

  @override
  bool get isSearchInProgress => _searcher.isSearching;

  @override
  Future<void> goToNextSearchMatch() async {
    await _searcher.goToNextMatch();
  }

  @override
  Future<void> goToPreviousSearchMatch() async {
    await _searcher.goToPrevMatch();
  }

  @override
  void addSearchChangedListener(VoidCallback listener) =>
      _searchListeners.add(listener);

  @override
  void removeSearchChangedListener(VoidCallback listener) =>
      _searchListeners.remove(listener);

  void _onSearchChanged() {
    for (final listener in List<VoidCallback>.of(_searchListeners)) {
      listener();
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _searcher.removeListener(_onSearchChanged);
    _searcher.dispose();
    // PdfViewerController has no dispose() in pdfrx 2.x; it detaches from
    // the viewer state automatically.
    _pageListeners.clear();
    _searchListeners.clear();
  }

  /// Builds the pdfrx viewer surface for [filePath] wrapped in the current
  /// rotation. Rotation is applied at presentation level because pdfrx does
  /// not expose a viewer rotation parameter.
  Widget buildViewer(String filePath, PdfViewerSettings settings) {
    return RotatedBox(
      quarterTurns: _rotationQuarterTurns,
      child: PdfViewer.file(
        filePath,
        controller: controller,
        initialPageNumber: settings.initialPage,
        params: PdfViewerParams(
          margin: 12,
          sizeDelegateProvider: const PdfViewerSizeDelegateProviderLegacy(
            minScale: 0.2,
            maxScale: 8,
          ),
          textSelectionParams: PdfTextSelectionParams(
            enabled: settings.textSelectionEnabled,
          ),
          matchTextColor: Colors.amber.withValues(alpha: 0.55),
          activeMatchTextColor: Colors.deepOrangeAccent.withValues(alpha: 0.75),
          onPageChanged: (_) => _notifyViewChanged(),
          pagePaintCallbacks: [_searcher.pageTextMatchPaintCallback],
        ),
      ),
    );
  }
}
