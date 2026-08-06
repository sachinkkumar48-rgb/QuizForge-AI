import '../models/editorial_status.dart';
import '../models/question_model.dart';
import '../repository/pyq_repository_interface.dart';

class EditorialWorkflowService {
  final IPYQRepository repository;

  EditorialWorkflowService(this.repository);

  Future<Question?> advanceStage(String questionId, EditorialStatus targetStage) async {
    final q = await repository.getQuestionById(questionId);
    if (q == null) return null;

    // Quality Rule Enforcement: Cannot mark AnswerVerified without official answer key keys
    if (targetStage == EditorialStatus.answerVerified &&
        q.officialAnswer.correctOptionKeys.isEmpty) {
      throw StateError(
          'Cannot advance to AnswerVerified: Official answer key is missing for $questionId');
    }

    // Quality Rule Enforcement: Cannot mark ConceptTagged without concepts
    if (targetStage == EditorialStatus.conceptTagged &&
        q.conceptsTested.isEmpty &&
        q.coreConcepts.isEmpty) {
      throw StateError(
          'Cannot advance to ConceptTagged: No concepts tagged for $questionId');
    }

    final updated = q.copyWith(editorialStatus: targetStage);
    await repository.saveQuestion(updated);
    return updated;
  }

  Future<List<Question>> getQuestionsByStage(EditorialStatus stage) async {
    final all = await repository.getAllQuestions();
    return all.where((q) => q.editorialStatus == stage).toList();
  }
}
