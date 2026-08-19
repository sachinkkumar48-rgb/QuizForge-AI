import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/entities/reader_annotation.dart';
import '../domain/entities/reader_bookmark.dart';
import '../domain/entities/reader_document.dart';
import '../domain/entities/reader_note.dart';
import '../domain/entities/reading_position.dart';
import '../navigation/reader_routes.dart';
import '../pdf/pdf_engine_contracts.dart';
import '../providers/reader_providers.dart';
import '../services/library_service.dart';
import '../widgets/annotations_panel.dart';
import '../widgets/bookmarks_panel.dart';
import '../widgets/document_search_bar.dart';
import '../widgets/note_editor_dialog.dart';
import '../widgets/notes_panel.dart';

/// Full-screen PDF reader: rendering, page navigation, zoom, fit modes,
/// rotation, text search, reading-position persistence and Phase 2 markup
/// (highlights, underlines, strikethroughs), bookmarks and notes.
class ReaderScreen extends ConsumerStatefulWidget {
  final String documentId;

  /// Checks whether the backing PDF file still exists on disk.
  ///
  /// Injectable so widget tests can avoid real file IO inside the
  /// FakeAsync zone; production uses the default [File.existsSync] check.
  final bool Function(String filePath)? fileExists;

  const ReaderScreen({super.key, required this.documentId, this.fileExists});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

/// Action ids offered on the text-selection context toolbar (§19 of the
/// Phase 2 brief). Dictionary/Grammar remain placeholders until later phases.
class _SelectionActionIds {
  static const copy = 'copy';
  static const dictionary = 'dictionary';
  static const grammar = 'grammar';
  static const highlight = 'highlight';
  static const underline = 'underline';
  static const strikethrough = 'strikethrough';
  static const note = 'note';

  static const List<PdfSelectionAction> all = [
    PdfSelectionAction(id: copy, label: 'Copy'),
    PdfSelectionAction(id: dictionary, label: 'Dictionary'),
    PdfSelectionAction(id: grammar, label: 'Grammar'),
    PdfSelectionAction(id: highlight, label: 'Highlight'),
    PdfSelectionAction(id: underline, label: 'Underline'),
    PdfSelectionAction(id: strikethrough, label: 'Strikethrough'),
    PdfSelectionAction(id: note, label: 'Note'),
  ];
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  PdfViewerHandle? _handle;
  LibraryService? _libraryService;
  bool _prepared = false;
  int _initialPage = 1;
  int? _page;
  int? _pageCount;
  bool _searchOpen = false;
  bool _openedRecorded = false;

  /// Color applied to annotations created from the selection toolbar.
  ReaderAnnotationColor _activeColor = ReaderAnnotationColor.yellow;

  @override
  void initState() {
    super.initState();
    _handle = ref.read(pdfEngineProvider).createHandle();
    final handle = _handle!;
    handle.addPageChangedListener(_onPageChanged);
    _prepare(handle);
  }

  Future<void> _prepare(PdfViewerHandle handle) async {
    final service = ref.read(libraryServiceProvider);
    _libraryService = service;
    final position = await service.loadPosition(widget.documentId);
    await _recordOpened(service);
    // Phase 2: preload persisted markup so overlays and panels are ready
    // the moment the viewer renders.
    await ref.read(annotationServiceProvider).preload(widget.documentId);
    await ref.read(bookmarkServiceProvider).preload(widget.documentId);
    await ref.read(noteServiceProvider).preload(widget.documentId);
    if (!mounted) {
      handle.dispose();
      return;
    }
    setState(() {
      _initialPage = position?.pageNumber ?? 1;
      _page = _initialPage;
      _prepared = true;
    });
    // Push restored annotations to the engine immediately; the ref.listen
    // wiring only reacts to later mutations.
    _syncOverlays();
  }

  void _onPageChanged(int? pageNumber) {
    if (!mounted || pageNumber == null) return;
    setState(() {
      _page = pageNumber;
      final enginePages = _handle?.pageCount;
      if (enginePages != null && _pageCount != enginePages) {
        _pageCount = enginePages;
        _persistPageCount(enginePages);
      }
    });
    _persistPosition();
  }

  Future<void> _recordOpened(LibraryService service) async {
    if (_openedRecorded) return;
    _openedRecorded = true;
    await service.markOpened(documentId: widget.documentId, at: DateTime.now());
    ref.invalidate(libraryDocumentsProvider);
    ref.invalidate(recentDocumentsProvider);
  }

  Future<void> _persistPageCount(int pageCount) {
    final service = _libraryService;
    if (service == null) return Future<void>.value();
    return service.updatePageCount(
        documentId: widget.documentId, pageCount: pageCount);
  }

  Future<void> _persistPosition() async {
    final service = _libraryService;
    final page = _page;
    if (service == null || page == null) return;
    await service.savePosition(ReadingPosition(
      documentId: widget.documentId,
      pageNumber: page,
      totalPages: _pageCount,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    final handle = _handle;
    if (handle != null) {
      handle.removePageChangedListener(_onPageChanged);
      // Best-effort final position save, then release engine resources.
      _persistPosition();
      handle.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Phase 2: annotations, bookmarks, notes
  // ---------------------------------------------------------------------

  /// Pushes every stored annotation of this document to the engine so the
  /// viewer paints them as page overlays.
  void _syncOverlays() {
    final handle = _handle;
    if (handle == null) return;
    final annotations =
        ref.read(annotationServiceProvider).annotationsFor(widget.documentId);
    handle.setAnnotationOverlays([
      for (final annotation in annotations)
        for (final rect in annotation.rects)
          PdfAnnotationOverlay(
            pageNumber: annotation.pageNumber,
            rect: rect,
            style: switch (annotation.type) {
              ReaderAnnotationType.highlight => PdfOverlayStyle.highlight,
              ReaderAnnotationType.underline => PdfOverlayStyle.underline,
              ReaderAnnotationType.strikethrough =>
                PdfOverlayStyle.strikethrough,
            },
            colorArgb: annotation.color.argb,
          ),
    ]);
  }

  /// Routes selection-context actions from the viewer to the application.
  Future<void> _onSelectionAction(String actionId) async {
    switch (actionId) {
      case _SelectionActionIds.copy:
        await _copySelection();
      case _SelectionActionIds.dictionary:
        _placeholder('Dictionary support arrives in a later phase.');
      case _SelectionActionIds.grammar:
        _placeholder('Grammar support arrives in a later phase.');
      case _SelectionActionIds.highlight:
        await _annotateFromSelection(ReaderAnnotationType.highlight);
      case _SelectionActionIds.underline:
        await _annotateFromSelection(ReaderAnnotationType.underline);
      case _SelectionActionIds.strikethrough:
        await _annotateFromSelection(ReaderAnnotationType.strikethrough);
      case _SelectionActionIds.note:
        await _addNoteFromSelection();
    }
  }

  Future<void> _copySelection() async {
    final handle = _handle;
    if (handle == null) return;
    final snapshot = await handle.captureTextSelection();
    if (snapshot == null || snapshot.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: snapshot.text));
    if (mounted) _placeholder('Copied to clipboard.');
  }

  /// Creates a markup annotation from the viewer's current text selection.
  Future<void> _annotateFromSelection(ReaderAnnotationType type) async {
    final handle = _handle;
    if (handle == null) return;
    final snapshot = await handle.captureTextSelection();
    if (snapshot == null || snapshot.fragments.isEmpty) return;
    final service = ref.read(annotationServiceProvider);
    final now = DateTime.now();
    await service.addAnnotation(ReaderAnnotation(
      id: service.nextId(),
      documentId: widget.documentId,
      pageNumber: snapshot.primaryPageNumber ?? 1,
      type: type,
      color: _activeColor,
      selectedText: snapshot.text,
      rects: [for (final fragment in snapshot.fragments) fragment.rect],
      createdAt: now,
      updatedAt: now,
    ));
    await handle.clearTextSelection();
    _syncOverlays();
  }

  /// Opens the note editor pre-filled with the current selection.
  Future<void> _addNoteFromSelection() async {
    final handle = _handle;
    if (handle == null) return;
    final snapshot = await handle.captureTextSelection();
    if (snapshot == null) return;
    await handle.clearTextSelection();
    if (!mounted) return;
    final result =
        await showNoteEditorDialog(context, selectedText: snapshot.text);
    if (result == null || !mounted) return;
    if (result.title.isEmpty && result.content.isEmpty) return;
    final service = ref.read(noteServiceProvider);
    final now = DateTime.now();
    await service.addNote(ReaderNote(
      id: service.nextId(),
      documentId: widget.documentId,
      pageNumber: snapshot.primaryPageNumber ?? (_page ?? 1),
      title: result.title,
      content: result.content,
      selectedText: snapshot.text.isEmpty ? null : snapshot.text,
      createdAt: now,
      updatedAt: now,
    ));
  }

  /// Adds or removes the application bookmark for the current page.
  Future<void> _toggleBookmark() async {
    final page = _page;
    if (page == null) return;
    final service = ref.read(bookmarkServiceProvider);
    final existing = service.bookmarkForPage(widget.documentId, page);
    if (existing != null) {
      await service.removeBookmark(
        documentId: widget.documentId,
        bookmarkId: existing.id,
      );
      if (mounted) _placeholder('Bookmark removed.');
      return;
    }
    final now = DateTime.now();
    await service.addBookmark(ReaderBookmark(
      id: service.nextId(),
      documentId: widget.documentId,
      pageNumber: page,
      title: 'Page $page',
      createdAt: now,
      updatedAt: now,
    ));
    if (mounted) _placeholder('Bookmark added on page $page.');
  }

  Future<void> _undo() async {
    final done = await ref.read(annotationServiceProvider).undo() ||
        await ref.read(bookmarkServiceProvider).undo() ||
        await ref.read(noteServiceProvider).undo();
    if (!done && mounted) _placeholder('Nothing to undo.');
  }

  Future<void> _redo() async {
    final done = await ref.read(annotationServiceProvider).redo() ||
        await ref.read(bookmarkServiceProvider).redo() ||
        await ref.read(noteServiceProvider).redo();
    if (!done && mounted) _placeholder('Nothing to redo.');
  }

  void _placeholder(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final document = ref.watch(documentByIdProvider(widget.documentId));

    // Keep painted overlays in sync with the annotation store.
    ref.listen(annotationsForDocumentProvider(widget.documentId),
        (previous, next) {
      _syncOverlays();
    });

    return document.when(
      loading: () => const Scaffold(
        body: Center(child: Text('Loading document…')),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Failed to load document: $error')),
      ),
      data: (document) {
        if (document == null) return _buildNotFound(context);
        if (!_prepared) {
          return const Scaffold(
            body: Center(child: Text('Preparing document…')),
          );
        }
        return _buildReader(context, document);
      },
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This document is no longer in the library.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(ReaderRoutes.library),
              child: const Text('Back to library'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReader(BuildContext context, ReaderDocument document) {
    final handle = _handle!;
    final theme = Theme.of(context);

    final fileExists =
        widget.fileExists ?? (String path) => File(path).existsSync();
    if (!fileExists(document.filePath)) {
      return Scaffold(
        appBar: AppBar(title: Text(document.title)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'The PDF file behind this entry is missing from disk. '
              'Re-import the file to continue reading.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final pageCount = _pageCount ?? 1;
    final page = (_page ?? 1).clamp(1, pageCount);
    final isBookmarked = ref
            .watch(bookmarksForDocumentProvider(widget.documentId))
            .valueOrNull
            ?.any((bookmark) => bookmark.pageNumber == page) ??
        false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            key: const Key('undo-button'),
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: _undo,
          ),
          IconButton(
            key: const Key('redo-button'),
            tooltip: 'Redo',
            icon: const Icon(Icons.redo),
            onPressed: _redo,
          ),
          PopupMenuButton<ReaderAnnotationColor>(
            key: const Key('annotation-color-picker'),
            tooltip: 'Highlight color',
            onSelected: (color) => setState(() => _activeColor = color),
            itemBuilder: (context) => [
              for (final color in ReaderAnnotationColor.values)
                PopupMenuItem<ReaderAnnotationColor>(
                  value: color,
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 18,
                        color: Color(color.argb),
                      ),
                      const SizedBox(width: 12),
                      Text(color.name[0].toUpperCase() +
                          color.name.substring(1)),
                      if (color == _activeColor) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.check, size: 16),
                      ],
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            key: const Key('bookmark-toggle-button'),
            tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark this page',
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            key: const Key('bookmarks-panel-button'),
            tooltip: 'Bookmarks and outline',
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => showBookmarksPanel(
              context,
              documentId: widget.documentId,
              handle: handle,
            ),
          ),
          IconButton(
            key: const Key('annotations-panel-button'),
            tooltip: 'Annotations',
            icon: const Icon(Icons.highlight_outlined),
            onPressed: () => showAnnotationsPanel(
              context,
              documentId: widget.documentId,
              handle: handle,
            ),
          ),
          IconButton(
            key: const Key('notes-panel-button'),
            tooltip: 'Notes',
            icon: const Icon(Icons.sticky_note_2_outlined),
            onPressed: () => showNotesPanel(
              context,
              documentId: widget.documentId,
              handle: handle,
              currentPage: page,
            ),
          ),
          IconButton(
            tooltip: _searchOpen ? 'Close search' : 'Search document',
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _searchOpen = !_searchOpen),
          ),
          PopupMenuButton<String>(
            tooltip: 'View options',
            onSelected: (value) {
              switch (value) {
                case 'fit-width':
                  handle.applyFitMode(PdfFitMode.fitWidth);
                case 'fit-page':
                  handle.applyFitMode(PdfFitMode.fitPage);
                case 'rotate':
                  handle.rotateClockwise();
                  setState(() {});
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'fit-width',
                child: ListTile(
                  leading: Icon(Icons.swap_horiz),
                  title: Text('Fit width'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'fit-page',
                child: ListTile(
                  leading: Icon(Icons.fit_screen_outlined),
                  title: Text('Fit page'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'rotate',
                child: ListTile(
                  leading: Icon(Icons.rotate_right_outlined),
                  title: Text('Rotate'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchOpen)
            DocumentSearchBar(
              handle: handle,
              onClose: () => setState(() => _searchOpen = false),
            ),
          Expanded(
            child: ref.read(pdfEngineProvider).buildViewer(
                  filePath: document.filePath,
                  settings: PdfViewerSettings(
                    initialPage: _initialPage,
                    selectionActions: _SelectionActionIds.all,
                    onSelectionAction: _onSelectionAction,
                  ),
                  handle: handle,
                ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Zoom out',
                    icon: const Icon(Icons.zoom_out),
                    onPressed: handle.zoomOut,
                  ),
                  Expanded(
                    child: Slider(
                      value: page.toDouble(),
                      min: 1,
                      max: pageCount.toDouble().clamp(1, double.infinity),
                      divisions: pageCount > 1 ? pageCount - 1 : null,
                      label: '$page',
                      onChanged: (value) {
                        setState(() => _page = value.round());
                        handle.goToPage(value.round());
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Zoom in',
                    icon: const Icon(Icons.zoom_in),
                    onPressed: handle.zoomIn,
                  ),
                  SizedBox(
                    width: 88,
                    child: Text(
                      '$page / ${_pageCount ?? '–'}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
