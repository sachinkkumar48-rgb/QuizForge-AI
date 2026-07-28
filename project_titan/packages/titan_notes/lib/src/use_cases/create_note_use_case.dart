import '../models/notes_models.dart';
import '../repository/notes_repository.dart';

/// Clean Architecture Use Case for creating a smart note.
class CreateNoteUseCase {
  final NotesRepository _repository;

  const CreateNoteUseCase(this._repository);

  Future<SmartNote> execute(SmartNote note) {
    return _repository.createNote(note);
  }
}
