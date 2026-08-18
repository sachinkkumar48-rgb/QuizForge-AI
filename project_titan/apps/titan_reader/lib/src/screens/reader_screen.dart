import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/entities/reader_document.dart';
import '../domain/entities/reading_position.dart';
import '../navigation/reader_routes.dart';
import '../pdf/pdf_engine_contracts.dart';
import '../providers/reader_providers.dart';
import '../services/library_service.dart';
import '../widgets/document_search_bar.dart';

/// Full-screen PDF reader: rendering, page navigation, zoom, fit modes,
/// rotation, text search and reading-position persistence.
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

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  PdfViewerHandle? _handle;
  LibraryService? _libraryService;
  bool _prepared = false;
  int _initialPage = 1;
  int? _page;
  int? _pageCount;
  bool _searchOpen = false;
  bool _openedRecorded = false;

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
    if (!mounted) {
      handle.dispose();
      return;
    }
    setState(() {
      _initialPage = position?.pageNumber ?? 1;
      _page = _initialPage;
      _prepared = true;
    });
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

  @override
  Widget build(BuildContext context) {
    final document = ref.watch(documentByIdProvider(widget.documentId));

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
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
                  settings: PdfViewerSettings(initialPage: _initialPage),
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
