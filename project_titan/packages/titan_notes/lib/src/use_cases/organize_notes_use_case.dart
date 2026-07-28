import '../engine/smart_notes_engine.dart';
import '../models/notes_models.dart';

/// Clean Architecture Use Case for organizing notes by subject / collection.
class OrganizeNotesUseCase {
  final SmartNotesEngine _engine;

  const OrganizeNotesUseCase(
      {SmartNotesEngine engine = const SmartNotesEngine()})
      : _engine = engine;

  Map<String, List<SmartNote>> execute(List<SmartNote> notes) {
    return _engine.organizeNotes(notes);
  }
}
