import '../models/notes_models.dart';
import '../repository/notes_repository.dart';

/// Clean Architecture Use Case for adding a bookmark to a smart note.
class AddNoteBookmarkUseCase {
  final NotesRepository _repository;

  const AddNoteBookmarkUseCase(this._repository);

  Future<NoteBookmark> execute(NoteBookmark bookmark) {
    return _repository.addBookmark(bookmark);
  }
}
