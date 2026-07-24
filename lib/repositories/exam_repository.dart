import '../models/exam.dart';

abstract class ExamRepository {
  Future<List<Exam>> getExams();
  Future<Exam?> getExamById(String examId);
  Future<List<Paper>> getPapers({String? examId, int? year});
  Future<List<int>> getAvailableYears({String? examId});
  Future<void> saveExam(Exam exam);
  Future<void> savePaper(Paper paper);
  Future<void> clear();
}
