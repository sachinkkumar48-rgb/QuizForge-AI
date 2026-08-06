import '../models/paper_model.dart';
import '../models/question_model.dart';
import 'pyq_repository_interface.dart';

class OfflinePYQRepository implements IPYQRepository {
  final Map<String, Question> _questions = {};
  final Map<String, Paper> _papers = {};

  @override
  Future<void> saveQuestion(Question question) async {
    _questions[question.id] = question;
  }

  @override
  Future<void> saveQuestions(List<Question> questions) async {
    for (final q in questions) {
      _questions[q.id] = q;
    }
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    return _questions[id];
  }

  @override
  Future<List<Question>> getQuestionsByExam(
    String examId, {
    int? year,
    String? subject,
    String? stage,
  }) async {
    return _questions.values.where((q) {
      if (q.examId.toLowerCase() != examId.toLowerCase()) return false;
      if (year != null && q.year != year) return false;
      if (subject != null &&
          q.subject.toLowerCase() != subject.toLowerCase()) {
        return false;
      }
      if (stage != null && q.stage.toLowerCase() != stage.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<Question>> searchQuestions(Map<String, dynamic> criteria) async {
    final query = criteria['keyword'] as String?;
    final examId = criteria['examId'] as String?;
    final year = criteria['year'] as int?;
    final subject = criteria['subject'] as String?;
    final topic = criteria['topic'] as String?;
    final article = criteria['article'] as String?;
    final caseName = criteria['case'] as String?;
    final actName = criteria['act'] as String?;
    final difficulty = criteria['difficulty'] as String?;
    final language = criteria['language'] as String?;

    return _questions.values.where((q) {
      if (examId != null && q.examId.toLowerCase() != examId.toLowerCase()) {
        return false;
      }
      if (year != null && q.year != year) return false;
      if (subject != null &&
          q.subject.toLowerCase() != subject.toLowerCase()) {
        return false;
      }
      if (topic != null && q.topic.toLowerCase() != topic.toLowerCase()) {
        return false;
      }
      if (difficulty != null &&
          q.difficulty.toLowerCase() != difficulty.toLowerCase()) {
        return false;
      }
      if (language != null &&
          q.language.toLowerCase() != language.toLowerCase()) {
        return false;
      }

      if (article != null &&
          !q.articleLinks.any(
              (a) => a.toLowerCase().contains(article.toLowerCase()))) {
        return false;
      }

      if (caseName != null &&
          !q.caseLinks.any(
              (c) => c.toLowerCase().contains(caseName.toLowerCase()))) {
        return false;
      }

      if (actName != null &&
          !q.actLinks
              .any((ac) => ac.toLowerCase().contains(actName.toLowerCase()))) {
        return false;
      }

      if (query != null && query.trim().isNotEmpty) {
        final qLower = query.toLowerCase();
        final matchesContent = q.originalQuestion.toLowerCase().contains(qLower) ||
            q.garudaExplanation.toLowerCase().contains(qLower) ||
            q.topic.toLowerCase().contains(qLower) ||
            q.tags.any((t) => t.toLowerCase().contains(qLower));
        if (!matchesContent) return false;
      }

      return true;
    }).toList();
  }

  @override
  Future<void> deleteQuestion(String id) async {
    _questions.remove(id);
  }

  @override
  Future<int> getQuestionCount() async {
    return _questions.length;
  }

  @override
  Future<List<Question>> getAllQuestions() async {
    return _questions.values.toList();
  }

  @override
  Future<List<Paper>> getPapersByExam(String examId) async {
    return _papers.values
        .where((p) => p.examId.toLowerCase() == examId.toLowerCase())
        .toList();
  }

  @override
  Future<void> savePaper(Paper paper) async {
    _papers[paper.id] = paper;
  }

  @override
  Future<void> clear() async {
    _questions.clear();
    _papers.clear();
  }
}
