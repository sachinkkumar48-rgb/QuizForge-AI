library;

import '../../repository/pyq_repository_interface.dart';

class CoverageReport {
  final Map<String, int> coverageByExam;
  final Map<int, int> coverageByYear;
  final Map<String, int> coverageBySubject;
  final Map<String, int> coverageByPaper;
  final int totalQuestionsInCorpus;

  const CoverageReport({
    required this.coverageByExam,
    required this.coverageByYear,
    required this.coverageBySubject,
    required this.coverageByPaper,
    required this.totalQuestionsInCorpus,
  });

  static Future<CoverageReport> generate(IPYQRepository repository) async {
    final questions = await repository.getAllQuestions();

    final examMap = <String, int>{};
    final yearMap = <int, int>{};
    final subjectMap = <String, int>{};
    final paperMap = <String, int>{};

    for (final q in questions) {
      examMap[q.examId] = (examMap[q.examId] ?? 0) + 1;
      yearMap[q.year] = (yearMap[q.year] ?? 0) + 1;
      subjectMap[q.subject] = (subjectMap[q.subject] ?? 0) + 1;
      paperMap[q.paper] = (paperMap[q.paper] ?? 0) + 1;
    }

    return CoverageReport(
      coverageByExam: examMap,
      coverageByYear: yearMap,
      coverageBySubject: subjectMap,
      coverageByPaper: paperMap,
      totalQuestionsInCorpus: questions.length,
    );
  }
}
