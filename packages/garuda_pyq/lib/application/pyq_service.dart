import '../analytics/pyq_analytics_engine.dart';
import '../models/paper_model.dart';
import '../models/question_model.dart';
import '../repository/pyq_repository_interface.dart';
import '../search/pyq_search_engine.dart';
import '../validators/pyq_validator.dart';

class PYQService {
  final IPYQRepository repository;
  late final PYQSearchEngine searchEngine;
  late final PYQAnalyticsEngine analyticsEngine;

  PYQService(this.repository) {
    searchEngine = PYQSearchEngine(repository);
    analyticsEngine = PYQAnalyticsEngine(repository);
  }

  Future<List<ValidationError>> ingestQuestion(Question question) async {
    final existing = await repository.getAllQuestions();
    final errors = PYQValidator.validateQuestion(question, existingQuestions: existing);
    if (errors.isEmpty) {
      await repository.saveQuestion(question);
    }
    return errors;
  }

  Future<List<ValidationError>> ingestQuestions(List<Question> questions) async {
    final batchErrors = PYQValidator.validateBatch(questions);
    if (batchErrors.isEmpty) {
      await repository.saveQuestions(questions);
    }
    return batchErrors;
  }

  Future<List<Question>> getExamPaperQuestions(String examId, int year, {String? stage}) async {
    return repository.getQuestionsByExam(examId, year: year, stage: stage);
  }

  Future<List<Paper>> getExamPapers(String examId) async {
    return repository.getPapersByExam(examId);
  }
}
