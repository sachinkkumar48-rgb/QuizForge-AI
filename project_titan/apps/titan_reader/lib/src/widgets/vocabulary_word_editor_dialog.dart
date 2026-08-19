import 'package:flutter/material.dart';

/// Result of the vocabulary word editor dialog.
class VocabularyEditorResult {
  final String personalMeaning;
  final String personalNote;

  const VocabularyEditorResult({
    required this.personalMeaning,
    required this.personalNote,
  });
}

/// Editor dialog for the personal meaning/note of a saved vocabulary word.
///
/// Personal fields never overwrite source-backed dictionary definitions.
class VocabularyWordEditorDialog extends StatelessWidget {
  final String word;
  final String initialMeaning;
  final String initialNote;

  const VocabularyWordEditorDialog({
    super.key,
    required this.word,
    this.initialMeaning = '',
    this.initialNote = '',
  });

  @override
  Widget build(BuildContext context) {
    final meaningController = TextEditingController(text: initialMeaning);
    final noteController = TextEditingController(text: initialNote);
    return AlertDialog(
      title: Text('Edit "$word"'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('vocab-meaning-field'),
              controller: meaningController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'My meaning',
                hintText: 'Your own short definition',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('vocab-note-field'),
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'My note',
                hintText: 'Anything that helps you remember',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('vocab-save-button'),
          onPressed: () => Navigator.of(context).pop(VocabularyEditorResult(
            personalMeaning: meaningController.text,
            personalNote: noteController.text,
          )),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Shows the vocabulary word editor; returns null when cancelled.
Future<VocabularyEditorResult?> showVocabularyWordEditor(
  BuildContext context, {
  required String word,
  String initialMeaning = '',
  String initialNote = '',
}) {
  return showDialog<VocabularyEditorResult>(
    context: context,
    builder: (context) => VocabularyWordEditorDialog(
      word: word,
      initialMeaning: initialMeaning,
      initialNote: initialNote,
    ),
  );
}
