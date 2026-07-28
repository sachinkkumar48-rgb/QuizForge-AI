import '../models/notes_models.dart';
import '../repository/notes_repository.dart';

/// Clean Architecture Use Case for fetching historical versions of a note.
class GetNoteVersionHistoryUseCase {
  final NotesRepository _repository;

  const GetNoteVersionHistoryUseCase(this._repository);

  Future<List<NoteVersion>> execute(String noteId) {
    return _repository.getVersionHistory(noteId);
  }
}
