import '../models/notes_models.dart';

/// Clean Architecture Use Case for converting note key concepts into spaced-repetition flashcards.
class ConvertNoteToFlashcardsUseCase {
  const ConvertNoteToFlashcardsUseCase();

  List<Map<String, String>> execute(SmartNote note) {
    final flashcards = <Map<String, String>>[];
    for (final section in note.sections) {
      flashcards.add({
        'front': 'What is the core principle of "${section.heading}"?',
        'back': section.content,
      });
    }
    if (flashcards.isEmpty) {
      flashcards.add({
        'front': 'Key summary of "${note.title}"?',
        'back': note.summary?.overview ?? note.content,
      });
    }
    return flashcards;
  }
}
