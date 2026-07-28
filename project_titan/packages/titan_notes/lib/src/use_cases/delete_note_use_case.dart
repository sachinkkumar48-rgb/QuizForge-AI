import '../repository/notes_repository.dart';

/// Clean Architecture Use Case for deleting a smart note.
class DeleteNoteUseCase {
  final NotesRepository _repository;

  const DeleteNoteUseCase(this._repository);

  Future<bool> execute(String noteId) {
    return _repository.deleteNote(noteId);
  }
}
