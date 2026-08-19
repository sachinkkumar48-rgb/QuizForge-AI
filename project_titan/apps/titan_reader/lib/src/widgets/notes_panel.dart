import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/reader_note.dart';
import '../pdf/pdf_engine_contracts.dart';
import '../providers/reader_providers.dart';
import 'note_editor_dialog.dart';

/// Panel listing, searching and managing the notes of the open document.
///
/// Notes are read from Reader storage through [NoteService]; tapping a note
/// navigates to its source page. Notes survive annotation deletion by design.
class NotesPanel extends ConsumerStatefulWidget {
  final String documentId;

  /// Viewer handle used to navigate to a note's page.
  final PdfViewerHandle handle;

  /// Page the reader currently shows; used as the default page for free
  /// notes created from this panel.
  final int currentPage;

  /// Invoked after the user navigates, so the presenter can close the panel.
  final void Function(int pageNumber)? onNavigate;

  const NotesPanel({
    super.key,
    required this.documentId,
    required this.handle,
    required this.currentPage,
    this.onNavigate,
  });

  @override
  ConsumerState<NotesPanel> createState() => _NotesPanelState();
}

class _NotesPanelState extends ConsumerState<NotesPanel> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allNotes =
        ref.watch(notesForDocumentProvider(widget.documentId)).valueOrNull ??
            const <ReaderNote>[];
    final query = _query.trim().toLowerCase();
    final notes = query.isEmpty
        ? allNotes
        : allNotes.where((note) => note.matches(query)).toList();

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
                  const Icon(Icons.sticky_note_2_outlined),
                  const SizedBox(width: 8),
                  Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    key: const Key('add-note-button'),
                    tooltip: 'Add note',
                    icon: const Icon(Icons.add),
                    onPressed: _addFreeNote,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('notes-search-field'),
                controller: _queryController,
                decoration: InputDecoration(
                  hintText: 'Search notes',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          key: const Key('notes-search-clear'),
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _queryController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  if (notes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(allNotes.isEmpty
                          ? 'No notes yet. Create one from the toolbar or '
                              'from a text selection.'
                          : 'No notes match “$_query”.'),
                    ),
                  for (final note in notes)
                    _NoteTile(
                      key: ValueKey('note-${note.id}'),
                      note: note,
                      onNavigate: () {
                        widget.handle.goToPage(note.pageNumber);
                        widget.onNavigate?.call(note.pageNumber);
                      },
                      onEdit: () => _editNote(note),
                      onDelete: () => _deleteNote(note),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addFreeNote() async {
    final result = await showNoteEditorDialog(context);
    if (result == null || !mounted) return;
    if (result.title.isEmpty && result.content.isEmpty) return;
    final service = ref.read(noteServiceProvider);
    final now = DateTime.now();
    await service.addNote(ReaderNote(
      id: service.nextId(),
      documentId: widget.documentId,
      pageNumber: widget.currentPage,
      title: result.title,
      content: result.content,
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> _editNote(ReaderNote note) async {
    final result = await showNoteEditorDialog(
      context,
      initialTitle: note.title,
      initialContent: note.content,
      selectedText: note.selectedText,
    );
    if (result == null || !mounted) return;
    final service = ref.read(noteServiceProvider);
    await service.updateNote(
      documentId: widget.documentId,
      noteId: note.id,
      at: DateTime.now(),
      title: result.title,
      content: result.content,
    );
  }

  Future<void> _deleteNote(ReaderNote note) async {
    final service = ref.read(noteServiceProvider);
    final removed = await service.removeNote(
      documentId: widget.documentId,
      noteId: note.id,
    );
    if (!mounted || removed == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Note "${removed.title}" removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => service.undo(),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final ReaderNote note;
  final VoidCallback onNavigate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteTile({
    super.key,
    required this.note,
    required this.onNavigate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = note.title.isEmpty ? '(Untitled)' : note.title;
    return ListTile(
      leading: const Icon(Icons.sticky_note_2_outlined),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.selectedText != null && note.selectedText!.isNotEmpty)
            Text(
              '“${note.selectedText}”',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          if (note.content.isNotEmpty)
            Text(
              note.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          Text('Page ${note.pageNumber}', style: theme.textTheme.bodySmall),
        ],
      ),
      isThreeLine: true,
      onTap: onNavigate,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('edit-note-${note.id}'),
            tooltip: 'Edit note',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          IconButton(
            key: ValueKey('delete-note-${note.id}'),
            tooltip: 'Delete note',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Convenience presenter used by the reader screen.
void showNotesPanel(
  BuildContext context, {
  required String documentId,
  required PdfViewerHandle handle,
  required int currentPage,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => NotesPanel(
      documentId: documentId,
      handle: handle,
      currentPage: currentPage,
      onNavigate: (_) => Navigator.of(context).pop(),
    ),
  );
}
