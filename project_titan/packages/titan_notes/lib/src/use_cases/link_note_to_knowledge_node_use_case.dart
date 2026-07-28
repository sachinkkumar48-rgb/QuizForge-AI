import '../models/notes_models.dart';
import '../repository/notes_repository.dart';

/// Clean Architecture Use Case for linking a smart note to a Knowledge Graph node.
class LinkNoteToKnowledgeNodeUseCase {
  final NotesRepository _repository;

  const LinkNoteToKnowledgeNodeUseCase(this._repository);

  Future<SmartNote> execute(SmartNote note, String knowledgeNodeId) async {
    final existingNodes = Set<String>.from(note.knowledgeNodeIds)
      ..add(knowledgeNodeId);
    final updated = note.copyWith(
      knowledgeNodeIds: existingNodes.toList(),
      updatedAt: DateTime.now(),
    );
    return _repository.updateNote(updated);
  }
}
