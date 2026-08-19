import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/reader_bookmark.dart';
import '../pdf/pdf_engine_contracts.dart';
import '../providers/reader_providers.dart';

/// Panel listing application bookmarks and the PDF-native outline of the
/// open document.
///
/// Application bookmarks come from Reader storage (persisted, editable);
/// outline entries are read from the document through the engine
/// abstraction and are never persisted.
class BookmarksPanel extends ConsumerStatefulWidget {
  final String documentId;

  /// Viewer handle used for outline loading/navigation.
  final PdfViewerHandle handle;

  /// Invoked after the user navigates, so the presenter can close the panel.
  final void Function(int pageNumber)? onNavigate;

  const BookmarksPanel({
    super.key,
    required this.documentId,
    required this.handle,
    this.onNavigate,
  });

  @override
  ConsumerState<BookmarksPanel> createState() => _BookmarksPanelState();
}

class _BookmarksPanelState extends ConsumerState<BookmarksPanel> {
  List<ReaderOutlineEntry> _outline = const [];
  bool _outlineLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadOutline();
  }

  Future<void> _loadOutline() async {
    final outline = await widget.handle.loadOutline();
    if (!mounted) return;
    setState(() {
      _outline = outline;
      _outlineLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = ref
            .watch(bookmarksForDocumentProvider(widget.documentId))
            .valueOrNull ??
        const <ReaderBookmark>[];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_outline),
                  const SizedBox(width: 8),
                  Text('Bookmarks',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  if (bookmarks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No bookmarks yet. Use the bookmark button '
                          'in the toolbar to save the current page.'),
                    ),
                  for (final bookmark in bookmarks)
                    _BookmarkTile(
                      key: ValueKey('bookmark-${bookmark.id}'),
                      bookmark: bookmark,
                      onNavigate: () {
                        widget.handle.goToPage(bookmark.pageNumber);
                        widget.onNavigate?.call(bookmark.pageNumber);
                      },
                      onEdit: () => _editBookmark(bookmark),
                      onDelete: () => _deleteBookmark(bookmark),
                    ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Text('Document outline',
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  if (!_outlineLoaded)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Loading outline…'),
                    )
                  else if (_outline.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('This document has no outline.'),
                    )
                  else
                    ..._outlineTiles(_outline, 0),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _outlineTiles(List<ReaderOutlineEntry> entries, int depth) {
    final tiles = <Widget>[];
    for (final entry in entries) {
      tiles.add(
        ListTile(
          key: ValueKey('outline-${entry.path}'),
          contentPadding: EdgeInsets.only(left: 16.0 + depth * 20.0, right: 16),
          leading: const Icon(Icons.toc),
          title: Text(entry.title),
          trailing:
              entry.pageNumber != null ? Text('${entry.pageNumber}') : null,
          onTap: () {
            widget.handle.goToOutlineEntry(entry.path);
            if (entry.pageNumber != null) {
              widget.onNavigate?.call(entry.pageNumber!);
            }
          },
        ),
      );
      tiles.addAll(_outlineTiles(entry.children, depth + 1));
    }
    return tiles;
  }

  Future<void> _editBookmark(ReaderBookmark bookmark) async {
    final controller = TextEditingController(text: bookmark.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit bookmark'),
        content: TextField(
          key: const Key('bookmark-title-field'),
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('bookmark-save-button'),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newTitle == null || newTitle.trim().isEmpty) return;
    final service = ref.read(bookmarkServiceProvider);
    await service.updateBookmark(
      documentId: widget.documentId,
      bookmarkId: bookmark.id,
      at: DateTime.now(),
      title: newTitle.trim(),
    );
  }

  Future<void> _deleteBookmark(ReaderBookmark bookmark) async {
    final service = ref.read(bookmarkServiceProvider);
    final removed = await service.removeBookmark(
      documentId: widget.documentId,
      bookmarkId: bookmark.id,
    );
    if (!mounted || removed == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bookmark "${removed.title}" removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => service.undo(),
        ),
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final ReaderBookmark bookmark;
  final VoidCallback onNavigate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BookmarkTile({
    super.key,
    required this.bookmark,
    required this.onNavigate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.bookmark),
      title: Text(bookmark.title),
      subtitle: Text('Page ${bookmark.pageNumber}'),
      onTap: onNavigate,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('edit-bookmark-${bookmark.id}'),
            tooltip: 'Edit bookmark',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          IconButton(
            key: ValueKey('delete-bookmark-${bookmark.id}'),
            tooltip: 'Delete bookmark',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Convenience presenter used by the reader screen.
void showBookmarksPanel(
  BuildContext context, {
  required String documentId,
  required PdfViewerHandle handle,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => BookmarksPanel(
      documentId: documentId,
      handle: handle,
      onNavigate: (_) => Navigator.of(context).pop(),
    ),
  );
}
