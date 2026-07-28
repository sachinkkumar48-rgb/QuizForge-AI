import '../models/notes_models.dart';
import '../repository/notes_repository.dart';

/// Clean Architecture Use Case for fetching notes associated with a content ID (video/PDF).
class GetNotesByContentUseCase {
  final NotesRepository _repository;

  const GetNotesByContentUseCase(this._repository);

  Future<List<SmartNote>> execute(String contentId) {
    return _repository.getNotesByContent(contentId);
  }
}
