import 'package:titan_core/titan_core.dart';
import '../models/daily_revision_queue.dart';
import '../models/pyq_analytics_model.dart';
import '../models/pyq_question_model.dart';
import '../repositories/impl/hive_pyq_repository.dart';
import '../repositories/pyq_repository.dart';

class PyqController {
  final PyqRepository _repository;

  PyqController({PyqRepository? repository})
      : _repository = repository ?? _resolveRepository();

  static PyqRepository _resolveRepository() {
    try {
      final locator = TitanServiceLocator.instance;
      if (locator.isRegistered<PyqRepository>()) {
        return locator.get<PyqRepository>();
      }
    } catch (_) {}
    return HivePyqRepository();
  }

  Future<void> init() async {
    await _repository.init();
  }

  Future<List<PyqQuestionModel>> getAllQuestions() async {
    return await _repository.getAllQuestions();
  }

  Future<List<PyqQuestionModel>> getQuestionsByYear(int year) async {
    return await _repository.getQuestionsByYear(year);
  }

  Future<List<PyqQuestionModel>> getQuestionsBySubject(String subject) async {
    return await _repository.getQuestionsBySubject(subject);
  }

  Future<List<PyqQuestionModel>> getQuestionsByTopic(String topic) async {
    return await _repository.getQuestionsByTopic(topic);
  }

  Future<List<PyqQuestionModel>> getBookmarkedQuestions() async {
    return await _repository.getBookmarkedQuestions();
  }

  Future<List<PyqQuestionModel>> getIncorrectQuestions() async {
    return await _repository.getIncorrectQuestions();
  }

  Future<List<PyqQuestionModel>> getQuestionsForObjective(String objectiveId) async {
    return await _repository.getQuestionsForObjective(objectiveId);
  }

  Future<List<PyqQuestionModel>> searchQuestions({
    String? query,
    int? year,
    String? subject,
    String? topic,
    String? difficulty,
    bool? onlyBookmarked,
    bool? onlyIncorrect,
    bool? unattempted,
  }) async {
    return await _repository.searchQuestions(
      query: query,
      year: year,
      subject: subject,
      topic: topic,
      difficulty: difficulty,
      onlyBookmarked: onlyBookmarked,
      onlyIncorrect: onlyIncorrect,
      unattempted: unattempted,
    );
  }

  Future<void> toggleBookmark(String questionId) async {
    await _repository.toggleBookmark(questionId);
  }

  Future<void> recordAttempt({
    required String questionId,
    required String selectedAnswer,
    String? learnerId,
    String? objectiveId,
  }) async {
    await _repository.recordAttempt(
      questionId: questionId,
      selectedAnswer: selectedAnswer,
      learnerId: learnerId,
      objectiveId: objectiveId,
    );
  }

  Future<List<PyqQuestionModel>> generateMockTest({
    required int count,
    String? subject,
    String? topic,
    List<int>? years,
  }) async {
    return await _repository.generateMockTest(
      count: count,
      subject: subject,
      topic: topic,
      years: years,
    );
  }

  Future<List<PyqQuestionModel>> generateSmartRevision({
    int count = 20,
    bool includeIncorrect = true,
    bool includeBookmarked = true,
    bool includeWeak = true,
  }) async {
    return await _repository.generateSmartRevision(
      count: count,
      includeIncorrect: includeIncorrect,
      includeBookmarked: includeBookmarked,
      includeWeak: includeWeak,
    );
  }

  Future<DailyRevisionQueue> getDailyRevisionQueue() async {
    return await _repository.getDailyRevisionQueue();
  }

  Future<void> recordSpacedRevisionResult({
    required String questionId,
    required bool isCorrect,
    required int confidenceRating,
  }) async {
    await _repository.recordSpacedRevisionResult(
      questionId: questionId,
      isCorrect: isCorrect,
      confidenceRating: confidenceRating,
    );
  }

  Future<PyqAnalyticsModel> getAnalytics() async {
    return await _repository.getAnalytics();
  }

  Future<int> importDataset(String jsonString) async {
    return await _repository.importDataset(jsonString);
  }
}
