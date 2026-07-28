import 'package:flutter/material.dart';
import '../models/smart_note.dart';
import 'rich_text_toolbar.dart';

/// Material 3 Note Editor component.
class NoteEditor extends StatefulWidget {
  final SmartNote? initialNote;
  final ValueChanged<SmartNote> onSave;

  const NoteEditor({
    super.key,
    this.initialNote,
    required this.onSave,
  });

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialNote?.title ?? '');
    _contentController =
        TextEditingController(text: widget.initialNote?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) return;

    final now = DateTime.now();
    final note = widget.initialNote?.copyWith(
          title: title.isEmpty ? 'Untitled Note' : title,
          content: content,
          updatedAt: now,
        ) ??
        SmartNote(
          id: 'sn_${now.millisecondsSinceEpoch}',
          title: title.isEmpty ? 'Untitled Note' : title,
          content: content,
          knowledgeNodeIds: const [],
          sections: const [],
          tags: const [],
          attachments: const [],
          bookmarks: const [],
          versions: const [],
          comments: const [],
          references: const [],
          highlights: const [],
          annotations: const [],
          createdAt: now,
          updatedAt: now,
        );

    widget.onSave(note);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.initialNote == null ? 'New Smart Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _handleSave,
            tooltip: 'Save Note',
          ),
        ],
      ),
      body: Column(
        children: [
          RichTextToolbar(
            onBold: () {},
            onItalic: () {},
            onList: () {},
            onHighlight: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _titleController,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Note Title...',
                border: InputBorder.none,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _contentController,
                style: theme.textTheme.bodyLarge,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText:
                      'Start typing notes or insert video timestamp excerpts...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
