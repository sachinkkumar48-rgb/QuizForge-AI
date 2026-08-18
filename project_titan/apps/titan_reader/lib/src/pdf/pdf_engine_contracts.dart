import 'package:flutter/widgets.dart';

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

/// Immutable viewer settings used when constructing a viewer surface.
@immutable
class PdfViewerSettings {
  /// 1-based page shown when the document opens.
  final int initialPage;

  /// Whether text selection is enabled in the viewer.
  final bool textSelectionEnabled;

  const PdfViewerSettings({
    this.initialPage = 1,
    this.textSelectionEnabled = true,
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
  Future<void> startSearch(String query);

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

  /// Registers a listener notified when search state changes.
  void addSearchChangedListener(VoidCallback listener);

  /// Removes a previously registered search-state listener.
  void removeSearchChangedListener(VoidCallback listener);

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
}
