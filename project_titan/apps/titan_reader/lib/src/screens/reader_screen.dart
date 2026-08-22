import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/entities/ai_reading_task.dart';
import '../domain/entities/normalized_page_rect.dart';
import '../domain/entities/pdf_encryption_options.dart';
import '../domain/entities/pdf_manipulation_result.dart';
import '../domain/entities/pdf_visual_signature.dart';
import '../domain/entities/reader_annotation.dart';
import '../domain/entities/reader_bookmark.dart';
import '../domain/entities/reader_document.dart';
import '../domain/entities/reader_note.dart';
import '../domain/entities/reading_position.dart';
import '../domain/word_normalizer.dart';
import '../navigation/reader_routes.dart';
import '../pdf/pdf_engine_contracts.dart';
import '../providers/dictionary_providers.dart';
import '../providers/encryption_providers.dart';
import '../providers/print_providers.dart';
import '../providers/reader_providers.dart';
import '../providers/signature_providers.dart';
import '../services/library_service.dart';
import '../widgets/ai_assistant_panel.dart';
import '../widgets/annotations_panel.dart';
import '../widgets/attachments_panel.dart';
import '../widgets/bookmarks_panel.dart';
import '../widgets/dictionary_panel.dart';
import '../widgets/document_search_bar.dart';
import '../widgets/document_selection_toolbar.dart';
import '../widgets/encryption/protect_pdf_dialog.dart';
import '../widgets/grammar_panel.dart';
import '../widgets/note_editor_dialog.dart';
import '../widgets/notes_panel.dart';
import '../widgets/organize_pages_dialog.dart';
import '../widgets/outline_sidebar.dart';
import '../widgets/signatures/signature_dialogs.dart';
import '../widgets/thumbnail_sidebar.dart';

/// Full-screen PDF reader: rendering, page navigation, zoom, fit modes,
/// rotation, text search, reading-position persistence and Phase 2 markup
/// (highlights, underlines, strikethroughs), bookmarks and notes.
class ReaderScreen extends ConsumerStatefulWidget {
  final String documentId;

  /// Page to open instead of the persisted reading position; used by
  /// vocabulary source navigation (`/reader/:documentId?page=N`).
  final int? initialPageOverride;

  /// Checks whether the backing PDF file still exists on disk.
  ///
  /// Injectable so widget tests can avoid real file IO inside the
  /// FakeAsync zone; production uses the default [File.existsSync] check.
  final bool Function(String filePath)? fileExists;

  const ReaderScreen({
    super.key,
    required this.documentId,
    this.initialPageOverride,
    this.fileExists,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

/// Action ids offered on the text-selection context toolbar (§19 of the
/// Phase 2 brief). Grammar analysis is provided by Phase 4. AI assistant
/// actions are provided by Phase 5.
class _SelectionActionIds {
  static const copy = 'copy';
  static const explain = 'explain';
  static const simplify = 'simplify';
  static const askAi = 'ask-ai';
  static const summarize = 'summarize';
  static const dictionary = 'dictionary';
  static const saveWord = 'save-word';
  static const grammar = 'grammar';
  static const highlight = 'highlight';
  static const underline = 'underline';
  static const strikethrough = 'strikethrough';
  static const note = 'note';
  static const search = 'search';

  static const List<PdfSelectionAction> all = [
    PdfSelectionAction(id: copy, label: 'Copy'),
    PdfSelectionAction(id: highlight, label: 'Highlight'),
    PdfSelectionAction(id: underline, label: 'Underline'),
    PdfSelectionAction(id: strikethrough, label: 'Strikethrough'),
    PdfSelectionAction(id: note, label: 'Note'),
    PdfSelectionAction(id: search, label: 'Search in Document'),
    PdfSelectionAction(id: dictionary, label: 'Dictionary'),
    PdfSelectionAction(id: saveWord, label: 'Save Word'),
    PdfSelectionAction(id: grammar, label: 'Grammar'),
    PdfSelectionAction(id: explain, label: 'Explain'),
    PdfSelectionAction(id: simplify, label: 'Simplify'),
    PdfSelectionAction(id: askAi, label: 'Ask AI'),
    PdfSelectionAction(id: summarize, label: 'Summarize'),
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
  bool _thumbnailSidebarOpen = false;
  bool _outlineSidebarOpen = false;
  bool _openedRecorded = false;
  bool _hasSelection = false;
  PdfVisualSignature? _placingSignature;

  /// Color applied to annotations created from the selection toolbar.
  ReaderAnnotationColor _activeColor = ReaderAnnotationColor.yellow;

  @override
  void initState() {
    super.initState();
    _handle = ref.read(pdfEngineProvider).createHandle();
    final handle = _handle!;
    handle.addPageChangedListener(_onPageChanged);
    handle.addSelectionChangedListener(_onSelectionChanged);
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
    // Phase 3: preload saved vocabulary so Save Word never races the load.
    await ref.read(vocabularyServiceProvider).ensureLoaded();
    if (!mounted) {
      handle.dispose();
      return;
    }
    setState(() {
      _initialPage = widget.initialPageOverride ?? position?.pageNumber ?? 1;
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

  void _onSelectionChanged() {
    if (!mounted) return;
    final hasSel = _handle?.hasTextSelection ?? false;
    if (_hasSelection != hasSel) {
      setState(() => _hasSelection = hasSel);
    }
  }

  @override
  void dispose() {
    final handle = _handle;
    if (handle != null) {
      handle.removePageChangedListener(_onPageChanged);
      handle.removeSelectionChangedListener(_onSelectionChanged);
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
  Future<void> _onSelectionAction(String actionId,
      {ReaderAnnotationColor? color}) async {
    switch (actionId) {
      case _SelectionActionIds.copy:
        await _copySelection();
      case _SelectionActionIds.explain:
        await _aiFromSelection(AIReadingTask.explain);
      case _SelectionActionIds.simplify:
        await _aiFromSelection(AIReadingTask.simplify);
      case _SelectionActionIds.askAi:
        await _aiFromSelection(AIReadingTask.askQuestion);
      case _SelectionActionIds.summarize:
        await _aiFromSelection(AIReadingTask.summarize);
      case _SelectionActionIds.dictionary:
        await _dictionaryFromSelection();
      case _SelectionActionIds.saveWord:
        await _saveWordFromSelection();
      case _SelectionActionIds.grammar:
        await _grammarFromSelection();
      case _SelectionActionIds.highlight:
        await _annotateFromSelection(ReaderAnnotationType.highlight,
            color: color);
      case _SelectionActionIds.underline:
        await _annotateFromSelection(ReaderAnnotationType.underline,
            color: color);
      case _SelectionActionIds.strikethrough:
        await _annotateFromSelection(ReaderAnnotationType.strikethrough,
            color: color);
      case _SelectionActionIds.note:
        await _addNoteFromSelection();
      case _SelectionActionIds.search:
        await _searchFromSelection();
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
  Future<void> _annotateFromSelection(ReaderAnnotationType type,
      {ReaderAnnotationColor? color}) async {
    final handle = _handle;
    if (handle == null) return;
    final snapshot = await handle.captureTextSelection();
    if (snapshot == null || snapshot.fragments.isEmpty) return;
    final service = ref.read(annotationServiceProvider);
    final now = DateTime.now();
    final chosenColor = color ?? _activeColor;
    await service.addAnnotation(ReaderAnnotation(
      id: service.nextId(),
      documentId: widget.documentId,
      pageNumber: snapshot.primaryPageNumber ?? 1,
      type: type,
      color: chosenColor,
      selectedText: snapshot.text,
      rects: [for (final fragment in snapshot.fragments) fragment.rect],
      createdAt: now,
      updatedAt: now,
    ));
    await handle.clearTextSelection();
    _syncOverlays();
  }

  /// Opens the search bar pre-filled with selected text and runs search.
  Future<void> _searchFromSelection() async {
    final handle = _handle;
    if (handle == null) return;
    final snapshot = await handle.captureTextSelection();
    if (snapshot == null || snapshot.text.trim().isEmpty) return;
    final query = snapshot.text.trim();
    await handle.clearTextSelection();
    setState(() => _searchOpen = true);
    await handle.startSearch(query);
  }

  /// Opens the dictionary panel for the selected word. Multi-word
  /// selections are not treated as dictionary words (§14).
  Future<void> _dictionaryFromSelection() async {
    final word = await _singleSelectedWord();
    if (word == null) return;
    final snapshotPage = _lastSelectionPage;
    final document =
        ref.read(documentByIdProvider(widget.documentId)).valueOrNull;
    if (!mounted) return;
    showDictionaryPanel(
      context,
      word: word,
      documentId: widget.documentId,
      documentName: document?.title,
      pageNumber: snapshotPage ?? _page,
      selectedText: word,
    );
  }

  /// Opens the grammar panel for the selected text. Multi-sentence and
  /// multi-paragraph selections are supported (§9 of the Phase 4 brief).
  Future<void> _grammarFromSelection() async {
    final handle = _handle;
    if (handle == null) return;
    final snapshot = await handle.captureTextSelection();
    if (snapshot == null || snapshot.text.trim().isEmpty) return;
    final page = snapshot.primaryPageNumber;
    await handle.clearTextSelection();
    final document =
        ref.read(documentByIdProvider(widget.documentId)).valueOrNull;
    if (!mounted) return;
    showGrammarPanel(
      context,
      text: snapshot.text,
      documentId: widget.documentId,
      documentName: document?.title,
      pageNumber: page,
    );
  }

  /// Opens the AI Assistant panel for the selected text and task.
  Future<void> _aiFromSelection(AIReadingTask task) async {
    final handle = _handle;
    if (handle == null) return;
    final snapshot = await handle.captureTextSelection();
    if (snapshot == null || snapshot.text.trim().isEmpty) return;
    final page = snapshot.primaryPageNumber;
    await handle.clearTextSelection();
    final document =
        ref.read(documentByIdProvider(widget.documentId)).valueOrNull;
    if (!mounted) return;
    showAIAssistantPanel(
      context,
      text: snapshot.text,
      initialTask: task,
      documentId: widget.documentId,
      documentName: document?.title,
      pageNumber: page ?? _page,
      onNavigateToPage: (p) => handle.goToPage(p),
    );
  }

  /// Saves the selected word straight to My Vocabulary with source
  /// tracking, without opening the dictionary panel.
  Future<void> _saveWordFromSelection() async {
    final word = await _singleSelectedWord();
    if (word == null) return;
    final snapshotPage = _lastSelectionPage;
    final document =
        ref.read(documentByIdProvider(widget.documentId)).valueOrNull;
    final service = ref.read(vocabularyServiceProvider);
    await service.ensureLoaded();
    final alreadySaved = service.wordForNormalized(word) != null;
    await service.saveWord(
      rawWord: word,
      at: DateTime.now(),
      sourceDocumentId: widget.documentId,
      sourceDocumentName: document?.title,
      sourcePage: snapshotPage ?? _page,
      selectedText: word,
    );
    if (!mounted) return;
    _placeholder(alreadySaved
        ? '"$word" is already in My Vocabulary.'
        : 'Saved "$word" to My Vocabulary.');
  }

  /// Page of the snapshot captured by the last [_singleSelectedWord] call.
  int? _lastSelectionPage;

  /// Captures the current selection and returns it when it is exactly one
  /// word (after normalization); shows a guidance snackbar otherwise.
  Future<String?> _singleSelectedWord() async {
    final handle = _handle;
    if (handle == null) return null;
    final snapshot = await handle.captureTextSelection();
    if (snapshot == null || snapshot.text.trim().isEmpty) return null;
    await handle.clearTextSelection();
    _lastSelectionPage = snapshot.primaryPageNumber;
    final word = WordNormalizer.singleWordFrom(snapshot.text);
    if (word == null) {
      if (mounted) _placeholder('Select a single word for this action.');
      return null;
    }
    return word;
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

  Future<void> _applySignatureStamp(
      PdfVisualSignature signature, NormalizedPageRect rect) async {
    final pageIndex = (_page ?? 1) - 1;
    final document =
        ref.read(documentByIdProvider(widget.documentId)).valueOrNull;
    if (document == null) return;
    try {
      await ref.read(signatureServiceProvider).stampSignatureOnPdf(
            sourceFilePath: document.filePath,
            pageIndex: pageIndex,
            rect: rect,
            signature: signature,
          );
      if (mounted) {
        _placeholder('Signature placed on page ${pageIndex + 1}.');
      }
    } catch (e) {
      if (mounted) {
        _placeholder('Failed to place signature: $e');
      }
    }
  }

  Future<void> _printDocument() async {
    final document =
        ref.read(documentByIdProvider(widget.documentId)).valueOrNull;
    if (document == null) {
      if (mounted) _placeholder('No active document to print.');
      return;
    }
    final printService = ref.read(printServiceProvider);
    try {
      final result = await printService.printDocument(
        filePath: document.filePath,
        documentTitle: document.title,
      );
      if (!mounted) return;
      if (result.isSuccess) {
        _placeholder('Document sent to printer.');
      } else if (result.isFailure) {
        _placeholder('Print failed: ${result.errorMessage ?? 'Unknown error'}');
      }
      // Cancellations are silent/neutral per specification.
    } catch (e) {
      if (mounted) {
        _placeholder('Print failed: $e');
      }
    }
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
            key: const Key('thumbnails-sidebar-button'),
            tooltip:
                _thumbnailSidebarOpen ? 'Hide thumbnails' : 'Page thumbnails',
            icon: Icon(
              _thumbnailSidebarOpen
                  ? Icons.view_sidebar
                  : Icons.view_sidebar_outlined,
            ),
            onPressed: () {
              setState(() {
                _thumbnailSidebarOpen = !_thumbnailSidebarOpen;
                if (_thumbnailSidebarOpen) {
                  _outlineSidebarOpen = false;
                }
              });
            },
          ),
          IconButton(
            key: const Key('outline-sidebar-button'),
            tooltip: _outlineSidebarOpen ? 'Hide outline' : 'Table of contents',
            icon: Icon(
              _outlineSidebarOpen ? Icons.toc : Icons.toc_outlined,
            ),
            onPressed: () {
              setState(() {
                _outlineSidebarOpen = !_outlineSidebarOpen;
                if (_outlineSidebarOpen) {
                  _thumbnailSidebarOpen = false;
                }
              });
            },
          ),
          IconButton(
            key: const Key('ai-assistant-button'),
            tooltip: 'AI Reading Assistant',
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: () {
              final document =
                  ref.read(documentByIdProvider(widget.documentId)).valueOrNull;
              showAIAssistantPanel(
                context,
                text: '',
                initialTask: AIReadingTask.askQuestion,
                documentId: widget.documentId,
                documentName: document?.title,
                pageNumber: page,
                onNavigateToPage: (p) => handle.goToPage(p),
              );
            },
          ),
          IconButton(
            key: const Key('dictionary-panel-button'),
            tooltip: 'Dictionary',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () {
              final document =
                  ref.read(documentByIdProvider(widget.documentId)).valueOrNull;
              showDictionaryPanel(
                context,
                documentId: widget.documentId,
                documentName: document?.title,
                pageNumber: page,
              );
            },
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
            key: const Key('signatures-panel-button'),
            tooltip: 'Signatures & Stamps',
            icon: const Icon(Icons.draw_outlined),
            onPressed: () async {
              final sig = await showDialog<PdfVisualSignature>(
                context: context,
                builder: (context) => SignatureLibraryDialog(
                  service: ref.read(signatureServiceProvider),
                ),
              );
              if (sig != null && mounted) {
                setState(() => _placingSignature = sig);
              }
            },
          ),
          IconButton(
            key: const Key('attachments-panel-button'),
            tooltip: 'Embedded attachments',
            icon: const Icon(Icons.attach_file),
            onPressed: () => showAttachmentsPanel(
              context,
              filePath: document.filePath,
              documentTitle: document.title,
            ),
          ),
          IconButton(
            key: const Key('print-document-button'),
            tooltip: 'Print document',
            icon: const Icon(Icons.print_outlined),
            onPressed: _printDocument,
          ),
          IconButton(
            tooltip: _searchOpen ? 'Close search' : 'Search document',
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _searchOpen = !_searchOpen),
          ),
          PopupMenuButton<String>(
            tooltip: 'View options',
            onSelected: (value) async {
              switch (value) {
                case 'attachments':
                  showAttachmentsPanel(
                    context,
                    filePath: document.filePath,
                    documentTitle: document.title,
                  );
                case 'print':
                  await _printDocument();
                case 'fit-width':
                  handle.applyFitMode(PdfFitMode.fitWidth);
                case 'fit-page':
                  handle.applyFitMode(PdfFitMode.fitPage);
                case 'rotate':
                  handle.rotateClockwise();
                  setState(() {});
                case 'organize-pages':
                  final result = await showDialog<PdfManipulationResult>(
                    context: context,
                    builder: (context) => OrganizePagesDialog(
                      filePath: document.filePath,
                      initialPageCount: _pageCount ?? 1,
                    ),
                  );
                  if (result != null && mounted) {
                    _placeholder(
                        'Pages organized (${result.pageCount} pages). Saved to ${result.primaryOutputPath}');
                  }
                case 'protect-pdf':
                  final config = await showDialog<PdfEncryptionConfig>(
                    context: context,
                    builder: (context) =>
                        ProtectPdfDialog(documentTitle: document.title),
                  );
                  if (config != null && mounted) {
                    final encryptionService =
                        ref.read(pdfEncryptionServiceProvider);
                    final targetPath = '${document.filePath}.protected.pdf';
                    final result = await encryptionService.encryptPdfFile(
                      sourceFilePath: document.filePath,
                      targetFilePath: targetPath,
                      config: config,
                    );
                    if (mounted) {
                      if (result.isSuccess) {
                        _placeholder(
                            'PDF protected with password. Saved to $targetPath');
                      } else {
                        _placeholder(
                            'Failed to protect PDF: ${result.errorMessage}');
                      }
                    }
                  }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'attachments',
                child: ListTile(
                  leading: Icon(Icons.attach_file),
                  title: Text('Attachments'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'protect-pdf',
                child: ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Protect PDF (Encrypt)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'print',
                child: ListTile(
                  leading: Icon(Icons.print_outlined),
                  title: Text('Print document'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
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
              PopupMenuItem<String>(
                value: 'organize-pages',
                child: ListTile(
                  leading: Icon(Icons.auto_stories),
                  title: Text('Organize pages'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_searchOpen)
                DocumentSearchBar(
                  handle: handle,
                  onClose: () => setState(() => _searchOpen = false),
                ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_thumbnailSidebarOpen)
                      ThumbnailSidebar(
                        filePath: document.filePath,
                        pageCount: _pageCount ?? 1,
                        currentPage: page,
                        handle: handle,
                        onPageSelected: (p) => handle.goToPage(p),
                        onClose: () =>
                            setState(() => _thumbnailSidebarOpen = false),
                        width: MediaQuery.of(context).size.width >= 720
                            ? 220
                            : 180,
                      ),
                    if (_outlineSidebarOpen)
                      OutlineSidebar(
                        handle: handle,
                        currentPage: page,
                        onEntrySelected: (entry) {
                          if (entry.pageNumber != null) {
                            handle.goToPage(entry.pageNumber!);
                          }
                        },
                        onClose: () =>
                            setState(() => _outlineSidebarOpen = false),
                        width: MediaQuery.of(context).size.width >= 720
                            ? 260
                            : 210,
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
                  ],
                ),
              ),
              if (_hasSelection)
                DocumentSelectionToolbar(
                  handle: handle,
                  activeColor: _activeColor,
                  onColorChanged: (c) => setState(() => _activeColor = c),
                  onAction: _onSelectionAction,
                  onClose: () => setState(() => _hasSelection = false),
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
          if (_placingSignature != null)
            Positioned.fill(
              child: SignaturePlacementOverlay(
                signature: _placingSignature!,
                onConfirm: (rect) async {
                  final sig = _placingSignature!;
                  setState(() => _placingSignature = null);
                  await _applySignatureStamp(sig, rect);
                },
                onCancel: () => setState(() => _placingSignature = null),
              ),
            ),
        ],
      ),
    );
  }
}
