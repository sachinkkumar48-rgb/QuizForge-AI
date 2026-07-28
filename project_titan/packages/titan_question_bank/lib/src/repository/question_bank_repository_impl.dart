import '../models/question_bank_models.dart';
import 'question_bank_repository.dart';

class QuestionBankRepositoryImpl implements QuestionBankRepository {
  final Map<String, KmpQuestionItem> _questions = {};

  QuestionBankRepositoryImpl() {
    final pyq = KmpQuestionItem(
      id: 'q_pyq_2023_polity_1',
      topicId: 'topic_polity',
      topicName: 'Polity',
      type: KmpQuestionType.pyq,
      stem: 'Consider the following statements regarding the Writs in India...',
      options: [
        'Habeas Corpus can be issued against both public and private entities.',
        'Mandamus cannot be issued against a private individual.',
        'Quo-Warranto can be filed by any interested person, not necessarily aggrieved.',
        'All of the above statements are correct.'
      ],
      correctAnswerIndex: 3,
      solutionExplanation:
          'Detailed explanation of Writ jurisdiction under Article 32 & 226.',
      pyqYear: 2023,
      pyqExamName: 'UPSC CSE Prelims',
      createdAt: DateTime.now(),
    );

    _questions[pyq.id] = pyq;
  }

  @override
  Future<List<KmpQuestionItem>> getQuestions(
      {KmpQuestionType? type, String? topicId}) async {
    var items = _questions.values.toList();
    if (type != null) {
      items = items.where((q) => q.type == type).toList();
    }
    if (topicId != null && topicId.isNotEmpty) {
      items = items.where((q) => q.topicId == topicId).toList();
    }
    return items;
  }

  @override
  Future<KmpQuestionItem?> getQuestionById(String id) async {
    return _questions[id];
  }

  @override
  Future<KmpQuestionItem> createQuestion(KmpQuestionItem question) async {
    _questions[question.id] = question;
    return question;
  }

  @override
  Future<KmpQuestionItem> updateQuestion(KmpQuestionItem question) async {
    _questions[question.id] = question;
    return question;
  }

  @override
  Future<void> deleteQuestion(String id) async {
    _questions.remove(id);
  }
}
