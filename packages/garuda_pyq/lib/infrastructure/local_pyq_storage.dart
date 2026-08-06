import '../models/question_model.dart';
import '../repository/offline_pyq_repository.dart';

class LocalPYQStorage {
  final OfflinePYQRepository _repository;

  LocalPYQStorage(this._repository);

  Future<void> persistToStorage(List<Question> questions) async {
    await _repository.saveQuestions(questions);
  }

  Future<List<Question>> loadFromStorage() async {
    return _repository.getAllQuestions();
  }
}
