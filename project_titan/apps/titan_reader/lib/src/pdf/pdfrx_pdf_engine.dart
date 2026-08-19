import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../domain/entities/normalized_page_rect.dart';
import '../domain/entities/reader_bookmark.dart';
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
  final List<VoidCallback> _selectionListeners = [];
  int _rotationQuarterTurns = 0;
  bool _disposed = false;

  /// Active annotation overlays keyed by nothing - a flat list repainted on
  /// every page paint callback.
  List<PdfAnnotationOverlay> _overlays = const [];

  /// Outline destinations captured by [loadOutline], keyed by entry path.
  final Map<String, PdfDest?> _outlineDests = {};

  /// Settings of the most recent [buildViewer] call; retained for the
  /// selection-action callback wired into the context menu.
  PdfViewerSettings? _settings;

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
  bool get hasTextSelection {
    if (!controller.isReady) return false;
    return controller.textSelectionDelegate.hasSelectedText;
  }

  @override
  Future<PdfTextSelectionSnapshot?> captureTextSelection() async {
    if (!controller.isReady) return null;
    final delegate = controller.textSelectionDelegate;
    if (!delegate.hasSelectedText) return null;
    final text = await delegate.getSelectedText();
    final ranges = await delegate.getSelectedTextRanges();
    final fragments = <PdfSelectionFragment>[];
    for (final range in ranges) {
      final pageNumber = range.pageNumber;
      if (pageNumber < 1 || pageNumber > controller.pageCount) continue;
      final page = controller.pages[pageNumber - 1];
      for (final fragment in range.enumerateFragmentBoundingRects()) {
        final bounds = fragment.bounds;
        final rect = NormalizedPageRect(
          left: (bounds.left / page.width).clamp(0.0, 1.0),
          right: (bounds.right / page.width).clamp(0.0, 1.0),
          // PdfRect uses bottom-left origin with Y pointing up; the Reader's
          // canonical coordinates use a top-left origin.
          top: ((page.height - bounds.top) / page.height).clamp(0.0, 1.0),
          bottom: ((page.height - bounds.bottom) / page.height).clamp(0.0, 1.0),
        );
        fragments.add(PdfSelectionFragment(pageNumber: pageNumber, rect: rect));
      }
    }
    if (fragments.isEmpty) return null;
    return PdfTextSelectionSnapshot(text: text, fragments: fragments);
  }

  @override
  Future<void> clearTextSelection() async {
    if (!controller.isReady) return;
    await controller.textSelectionDelegate.clearTextSelection();
  }

  @override
  void addSelectionChangedListener(VoidCallback listener) =>
      _selectionListeners.add(listener);

  @override
  void removeSelectionChangedListener(VoidCallback listener) =>
      _selectionListeners.remove(listener);

  void _onSelectionChanged() {
    for (final listener in List<VoidCallback>.of(_selectionListeners)) {
      listener();
    }
  }

  @override
  Future<List<ReaderOutlineEntry>> loadOutline() async {
    _outlineDests.clear();
    if (!controller.isReady) return const [];
    final nodes = await controller.document.loadOutline();
    return _mapOutline(nodes, '');
  }

  List<ReaderOutlineEntry> _mapOutline(
      List<PdfOutlineNode> nodes, String parentPath) {
    final entries = <ReaderOutlineEntry>[];
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final path = parentPath.isEmpty ? '$i' : '$parentPath/$i';
      _outlineDests[path] = node.dest;
      entries.add(ReaderOutlineEntry(
        title: node.title,
        path: path,
        pageNumber: node.dest?.pageNumber,
        children: _mapOutline(node.children, path),
      ));
    }
    return entries;
  }

  @override
  Future<void> goToOutlineEntry(String path) async {
    if (!controller.isReady) return;
    final dest = _outlineDests[path];
    if (dest == null) return;
    await controller.goToDest(dest);
  }

  @override
  void setAnnotationOverlays(List<PdfAnnotationOverlay> overlays) {
    _overlays = List.unmodifiable(overlays);
    if (controller.isReady) {
      controller.invalidate();
    }
  }

  /// Page paint callback drawing all Reader-managed annotation overlays.
  ///
  /// Normalized geometry is converted back to PDF page coordinates and then
  /// through pdfrx's own [PdfRect.toRect] pipeline, which keeps overlay
  /// rendering consistent with built-in text match painting across zoom and
  /// page rotation.
  void _annotationPaintCallback(Canvas canvas, Rect pageRect, PdfPage page) {
    if (_overlays.isEmpty) return;
    for (final overlay in _overlays) {
      if (overlay.pageNumber != page.pageNumber) continue;
      final pdfRect = PdfRect(
        overlay.rect.left * page.width,
        page.height - overlay.rect.top * page.height,
        overlay.rect.right * page.width,
        page.height - overlay.rect.bottom * page.height,
      );
      final rect = pdfRect
          .toRect(page: page, scaledPageSize: pageRect.size)
          .translate(pageRect.left, pageRect.top);
      final color = Color(overlay.colorArgb);
      switch (overlay.style) {
        case PdfOverlayStyle.highlight:
          canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.35));
        case PdfOverlayStyle.underline:
          final thickness = (rect.height * 0.08).clamp(1.0, 4.0);
          canvas.drawRect(
            Rect.fromLTWH(
                rect.left, rect.bottom - thickness, rect.width, thickness),
            Paint()..color = color,
          );
        case PdfOverlayStyle.strikethrough:
          final thickness = (rect.height * 0.08).clamp(1.0, 4.0);
          final centerY = rect.top + rect.height / 2;
          canvas.drawRect(
            Rect.fromLTWH(
                rect.left, centerY - thickness / 2, rect.width, thickness),
            Paint()..color = color,
          );
      }
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
    _settings = settings;
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
            onTextSelectionChange: (_) => _onSelectionChanged(),
          ),
          matchTextColor: Colors.amber.withValues(alpha: 0.55),
          activeMatchTextColor: Colors.deepOrangeAccent.withValues(alpha: 0.75),
          onPageChanged: (_) => _notifyViewChanged(),
          pagePaintCallbacks: [
            _searcher.pageTextMatchPaintCallback,
            _annotationPaintCallback,
          ],
          customizeContextMenuItems: _customizeContextMenuItems,
        ),
      ),
    );
  }

  /// Appends the Reader's selection actions (highlight, underline, note,
  /// dictionary, grammar, ...) to pdfrx's native text context menu.
  void _customizeContextMenuItems(PdfViewerContextMenuBuilderParams params,
      List<ContextMenuButtonItem> items) {
    final settings = _settings;
    if (settings == null) return;
    for (final action in settings.selectionActions) {
      items.add(ContextMenuButtonItem(
        label: action.label,
        onPressed: () {
          // The application layer consumes the selection (copy, annotate,
          // note) and clears it itself, so the capture sees intact geometry.
          settings.onSelectionAction?.call(action.id);
        },
      ));
    }
  }
}
