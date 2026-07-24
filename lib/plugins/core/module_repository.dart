import '../../models/exam.dart';
import '../../models/question.dart';

/// Contract for module-specific data persistence and querying.
abstract class ModuleRepository {
  /// Fetch list of questions supported or owned by this module.
  Future<List<Question>> getQuestions({
    String? subject,
    String? topic,
    int? year,
    String? difficulty,
    int? limit,
  });

  /// Fetch exams defined by this module.
  Future<List<Exam>> getExams();

  /// Fetch papers defined for a specific exam under this module.
  Future<List<Paper>> getPapers(String examId);

  /// Save questions into this module's repository.
  Future<void> saveQuestions(List<Question> questions);

  /// Retrieve arbitrary key-value metadata for the module.
  Future<dynamic> getModuleData(String key);

  /// Store arbitrary key-value metadata for the module.
  Future<void> setModuleData(String key, dynamic value);

  /// Get total count of available questions in this module.
  Future<int> getQuestionCount();
}
