import 'package:flutter/widgets.dart';
import 'package:titan_reader/src/pdf/pdf_engine_contracts.dart';

/// In-memory [PdfDocumentEngine] used by widget tests so the UI can be
/// exercised without the native pdfrx/PDFium stack.
class FakePdfEngine implements PdfDocumentEngine {
  /// Most recently created handle, so tests can script/inspect it.
  FakeViewerHandle? lastHandle;

  @override
  String get engineName => 'fake';

  @override
  PdfViewerHandle createHandle() {
    final handle = FakeViewerHandle();
    lastHandle = handle;
    return handle;
  }

  @override
  Widget buildViewer({
    required String filePath,
    required PdfViewerSettings settings,
    required PdfViewerHandle handle,
  }) {
    final fake = handle as FakeViewerHandle;
    fake.lastFilePath = filePath;
    fake.lastSettings = settings;
    fake.isReady = true;
    return const SizedBox.expand(key: Key('fake-pdf-viewer'));
  }
}

/// Scriptable [PdfViewerHandle] recording every interaction.
class FakeViewerHandle implements PdfViewerHandle {
  final List<int> visitedPages = [];
  final List<String> searchQueries = [];
  int zoomInCount = 0;
  int zoomOutCount = 0;
  int rotateCount = 0;
  PdfFitMode? lastFitMode;
  String? lastFilePath;
  PdfViewerSettings? lastSettings;
  bool clearSearchCalled = false;
  int nextMatchCalls = 0;
  int previousMatchCalls = 0;

  final List<void Function(int?)> _pageListeners = [];
  final List<VoidCallback> _searchListeners = [];

  @override
  bool isReady = true;

  @override
  int? currentPageNumber = 1;

  @override
  int? pageCount = 10;

  @override
  int rotationQuarterTurns = 0;

  List<PdfSearchMatch> matches = const [];

  @override
  int? currentSearchMatchIndex;

  bool searching = false;

  @override
  List<PdfSearchMatch> get searchMatches => matches;

  @override
  bool get isSearchActive => searchQueries.isNotEmpty && !clearSearchCalled;

  @override
  bool get isSearchInProgress => searching;

  @override
  void addPageChangedListener(void Function(int? pageNumber) listener) =>
      _pageListeners.add(listener);

  @override
  void removePageChangedListener(void Function(int? pageNumber) listener) =>
      _pageListeners.remove(listener);

  @override
  Future<void> goToPage(int pageNumber) async {
    visitedPages.add(pageNumber);
    currentPageNumber = pageNumber;
    firePageChanged(pageNumber);
  }

  @override
  Future<void> zoomIn() async => zoomInCount++;

  @override
  Future<void> zoomOut() async => zoomOutCount++;

  @override
  Future<void> applyFitMode(PdfFitMode mode) async => lastFitMode = mode;

  @override
  void rotateClockwise() {
    rotateCount++;
    rotationQuarterTurns = (rotationQuarterTurns + 1) & 3;
  }

  @override
  Future<void> startSearch(String query) async {
    searchQueries.add(query);
    searching = false;
  }

  @override
  Future<void> clearSearch() async {
    clearSearchCalled = true;
    matches = const [];
    currentSearchMatchIndex = null;
  }

  @override
  Future<void> goToNextSearchMatch() async => nextMatchCalls++;

  @override
  Future<void> goToPreviousSearchMatch() async => previousMatchCalls++;

  @override
  void addSearchChangedListener(VoidCallback listener) =>
      _searchListeners.add(listener);

  @override
  void removeSearchChangedListener(VoidCallback listener) =>
      _searchListeners.remove(listener);

  @override
  void dispose() {}

  /// Test hook: simulate the engine reporting a new visible page.
  void firePageChanged(int? pageNumber) {
    for (final listener in List<void Function(int?)>.of(_pageListeners)) {
      listener(pageNumber);
    }
  }

  /// Test hook: simulate the engine's search state changing.
  void fireSearchChanged() {
    for (final listener in List<VoidCallback>.of(_searchListeners)) {
      listener();
    }
  }
}
