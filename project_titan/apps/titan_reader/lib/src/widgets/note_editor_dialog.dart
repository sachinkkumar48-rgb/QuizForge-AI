import 'package:flutter/material.dart';

/// Result of the note editor dialog.
@immutable
class NoteEditorResult {
  /// Note title; may be empty.
  final String title;

  /// Note body text.
  final String content;

  const NoteEditorResult({required this.title, required this.content});
}

/// Modal dialog for creating or editing a Reader note.
///
/// Returns null when the user cancels; a [NoteEditorResult] when saved.
class NoteEditorDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;

  /// Optional read-only source text shown above the editors (used when the
  /// note was created from a text selection).
  final String? selectedText;

  const NoteEditorDialog({
    super.key,
    this.initialTitle,
    this.initialContent,
    this.selectedText,
  });

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController =
        TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(NoteEditorResult(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final selectedText = widget.selectedText;
    return AlertDialog(
      title: Text(widget.initialContent == null && widget.initialTitle == null
          ? 'New note'
          : 'Edit note'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedText != null && selectedText.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '“$selectedText”',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                key: const Key('note-title-field'),
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('note-content-field'),
                controller: _contentController,
                minLines: 3,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('note-save-button'),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Convenience presenter wrapping [NoteEditorDialog] in [showDialog].
Future<NoteEditorResult?> showNoteEditorDialog(
  BuildContext context, {
  String? initialTitle,
  String? initialContent,
  String? selectedText,
}) {
  return showDialog<NoteEditorResult>(
    context: context,
    builder: (context) => NoteEditorDialog(
      initialTitle: initialTitle,
      initialContent: initialContent,
      selectedText: selectedText,
    ),
  );
}
