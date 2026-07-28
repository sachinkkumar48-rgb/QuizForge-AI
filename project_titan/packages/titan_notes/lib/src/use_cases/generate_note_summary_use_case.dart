import '../engine/smart_notes_engine.dart';
import '../models/notes_models.dart';

/// Clean Architecture Use Case for generating an AI summary of a note.
class GenerateNoteSummaryUseCase {
  final SmartNotesEngine _engine;

  const GenerateNoteSummaryUseCase(
      {SmartNotesEngine engine = const SmartNotesEngine()})
      : _engine = engine;

  NoteSummary execute(SmartNote note) {
    return _engine.summarize(note);
  }
}
