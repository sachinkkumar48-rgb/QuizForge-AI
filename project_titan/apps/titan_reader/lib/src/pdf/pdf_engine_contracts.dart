import 'package:flutter/widgets.dart';

import '../domain/entities/normalized_page_rect.dart';
import '../domain/entities/reader_bookmark.dart';

/// Fit modes for the reader viewport.
enum PdfFitMode {
  /// Fit the whole page into the viewport.
  fitPage,

  /// Fit the page width into the viewport.
  fitWidth,
}

/// Engine-agnostic description of a single text-search match.
@immutable
class PdfSearchMatch {
  /// Zero-based index of the match inside the current search session.
  final int index;

  /// 1-based page number containing the match.
  final int pageNumber;

  /// The matched text fragment.
  final String snippet;

  const PdfSearchMatch({
    required this.index,
    required this.pageNumber,
    required this.snippet,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfSearchMatch &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          pageNumber == other.pageNumber &&
          snippet == other.snippet;

  @override
  int get hashCode => Object.hash(index, pageNumber, snippet);

  @override
  String toString() =>
      'PdfSearchMatch(index: $index, page: $pageNumber, "$snippet")';
}

/// Engine-agnostic snapshot of an open document.
@immutable
class PdfDocumentSummary {
  /// Total number of pages.
  final int pageCount;

  const PdfDocumentSummary({required this.pageCount});

  @override
  String toString() => 'PdfDocumentSummary(pageCount: $pageCount)';
}

/// Markup style of an annotation overlay rendered by the engine.
enum PdfOverlayStyle { highlight, underline, strikethrough }

/// Engine-agnostic request to render one Reader-managed annotation as a
/// page overlay. Geometry uses the canonical normalized page coordinates, so
/// overlays stay stable across zoom, window size, orientation and rendering
/// scale.
@immutable
class PdfAnnotationOverlay {
  /// 1-based page to paint the overlay on.
  final int pageNumber;

  /// Normalized text fragment covered by the annotation.
  final NormalizedPageRect rect;

  /// How the fragment is marked.
  final PdfOverlayStyle style;

  /// Opaque ARGB color value.
  final int colorArgb;

  const PdfAnnotationOverlay({
    required this.pageNumber,
    required this.rect,
    required this.style,
    required this.colorArgb,
  });

  @override
  String toString() =>
      'PdfAnnotationOverlay(page: $pageNumber, style: ${style.name})';
}

/// One selected text fragment expressed in normalized page coordinates.
@immutable
class PdfSelectionFragment {
  /// 1-based page containing the fragment.
  final int pageNumber;

  /// Normalized bounding rectangle of the fragment.
  final NormalizedPageRect rect;

  const PdfSelectionFragment({required this.pageNumber, required this.rect});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfSelectionFragment &&
          runtimeType == other.runtimeType &&
          pageNumber == other.pageNumber &&
          rect == other.rect;

  @override
  int get hashCode => Object.hash(pageNumber, rect);

  @override
  String toString() => 'PdfSelectionFragment(page: $pageNumber, $rect)';
}

/// Engine-agnostic snapshot of the viewer's current text selection.
///
/// The selected text alone is not sufficient to restore an annotation (the
/// same text may appear several times on a page), therefore the snapshot also
/// carries the per-fragment geometry.
@immutable
class PdfTextSelectionSnapshot {
  /// The selected text.
  final String text;

  /// Geometry of every selected fragment, in document order.
  final List<PdfSelectionFragment> fragments;

  const PdfTextSelectionSnapshot({required this.text, required this.fragments});

  /// Page of the first fragment, or null for an empty selection.
  int? get primaryPageNumber =>
      fragments.isEmpty ? null : fragments.first.pageNumber;

  @override
  String toString() =>
      'PdfTextSelectionSnapshot("$text", fragments: ${fragments.length})';
}

/// Action item offered on the text-selection context toolbar.
@immutable
class PdfSelectionAction {
  /// Stable action identifier understood by the application.
  final String id;

  /// User-visible label.
  final String label;

  const PdfSelectionAction({required this.id, required this.label});
}

/// Immutable viewer settings used when constructing a viewer surface.
@immutable
class PdfViewerSettings {
  /// 1-based page shown when the document opens.
  final int initialPage;

  /// Whether text selection is enabled in the viewer.
  final bool textSelectionEnabled;

  /// Actions offered on the selection context toolbar (e.g. copy, highlight,
  /// note). Empty by default.
  final List<PdfSelectionAction> selectionActions;

  /// Invoked with the [PdfSelectionAction.id] when the user triggers one of
  /// the [selectionActions].
  final void Function(String actionId)? onSelectionAction;

  const PdfViewerSettings({
    this.initialPage = 1,
    this.textSelectionEnabled = true,
    this.selectionActions = const [],
    this.onSelectionAction,
  }) : assert(initialPage >= 1, 'initialPage must be >= 1');
}

/// Imperative and observable control surface for the currently open PDF.
///
/// Implementations are bound to a concrete rendering library but expose only
/// engine-agnostic operations so the application layer never depends on a
/// specific PDF SDK.
abstract class PdfViewerHandle {
  /// Whether the underlying document is loaded and ready.
  bool get isReady;

  /// Current 1-based page number, or null while unknown.
  int? get currentPageNumber;

  /// Total page count, or null while the document is not loaded.
  int? get pageCount;

  /// Registers a listener notified whenever the visible page changes.
  void addPageChangedListener(void Function(int? pageNumber) listener);

  /// Removes a previously registered page-changed listener.
  void removePageChangedListener(void Function(int? pageNumber) listener);

  /// Navigates to the given 1-based page number.
  Future<void> goToPage(int pageNumber);

  /// Zooms in one step.
  Future<void> zoomIn();

  /// Zooms out one step.
  Future<void> zoomOut();

  /// Applies the requested fit mode to the current page.
  Future<void> applyFitMode(PdfFitMode mode);

  /// Rotates the presentation clockwise by one 90-degree step.
  void rotateClockwise();

  /// Current rotation expressed as clockwise quarter turns (0..3).
  int get rotationQuarterTurns;

  /// Starts a new text search session for [query].
  Future<void> startSearch(
    String query, {
    bool caseSensitive = false,
    bool wholeWord = false,
  });

  /// Clears the current search session and its highlights.
  Future<void> clearSearch();

  /// Matches found so far in the current search session.
  List<PdfSearchMatch> get searchMatches;

  /// Index of the active match inside [searchMatches], if any.
  int? get currentSearchMatchIndex;

  /// Whether a search session is active.
  bool get isSearchActive;

  /// Whether the engine is still scanning pages for matches.
  bool get isSearchInProgress;

  /// Moves to the next search match, wrapping around at the end.
  Future<void> goToNextSearchMatch();

  /// Moves to the previous search match, wrapping around at the start.
  Future<void> goToPreviousSearchMatch();

  /// Navigates directly to the search match at [index].
  Future<void> goToSearchMatch(int index);

  /// Registers a listener notified when search state changes.
  void addSearchChangedListener(VoidCallback listener);

  /// Removes a previously registered search-state listener.
  void removeSearchChangedListener(VoidCallback listener);

  /// Whether the viewer currently holds a text selection.
  bool get hasTextSelection;

  /// Captures the current text selection including per-fragment geometry.
  /// Returns null when nothing is selected.
  Future<PdfTextSelectionSnapshot?> captureTextSelection();

  /// Clears the current text selection.
  Future<void> clearTextSelection();

  /// Registers a listener notified when the text selection changes.
  void addSelectionChangedListener(VoidCallback listener);

  /// Removes a previously registered selection-changed listener.
  void removeSelectionChangedListener(VoidCallback listener);

  /// Loads the PDF document's native outline (PDF bookmarks). Empty when the
  /// document has no outline or is not loaded yet.
  Future<List<ReaderOutlineEntry>> loadOutline();

  /// Navigates to the outline entry identified by [path] (see
  /// [ReaderOutlineEntry.path]).
  Future<void> goToOutlineEntry(String path);

  /// Replaces the annotation overlays painted on the pages and repaints.
  void setAnnotationOverlays(List<PdfAnnotationOverlay> overlays);

  /// Releases engine resources bound to this handle.
  void dispose();
}

/// Factory abstraction over the concrete PDF rendering library.
///
/// The application depends only on this contract; the concrete SDK is
/// confined to a single adapter (see ADR-0004).
abstract class PdfDocumentEngine {
  /// Human-readable engine name, used for diagnostics only.
  String get engineName;

  /// Creates a new, unbound viewer handle.
  PdfViewerHandle createHandle();

  /// Builds the viewer widget surface for the PDF at [filePath].
  Widget buildViewer({
    required String filePath,
    required PdfViewerSettings settings,
    required PdfViewerHandle handle,
  });

  /// Builds a thumbnail preview widget for [pageNumber] (1-based) of the PDF document.
  Widget buildThumbnail({
    required String filePath,
    required int pageNumber,
    required PdfViewerHandle handle,
    double? width,
    double? height,
  });
}
