import '../engine/smart_notes_engine.dart';
import '../models/notes_models.dart';
import '../repository/notes_repository.dart';

/// Clean Architecture Use Case for enhancing a smart note with AI capabilities.
class EnhanceNoteWithAiUseCase {
  final NotesRepository _repository;
  final SmartNotesEngine _engine;

  const EnhanceNoteWithAiUseCase(
    this._repository, {
    SmartNotesEngine engine = const SmartNotesEngine(),
  }) : _engine = engine;

  Future<SmartNote> execute(SmartNote note) async {
    final enhanced = _engine.aiEnhancement(note);
    return _repository.updateNote(enhanced);
  }
}
