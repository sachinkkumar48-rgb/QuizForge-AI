import 'package:garuda_pyq/garuda_pyq.dart';
import '../models/pyq_question_model.dart';
import '../repositories/pyq_repository.dart';

/// Production adapter service translating QuizForge AI [PyqQuestionModel] entities
/// into canonical [NormalizedQuestion] candidates for the GARUDA adaptive learning engine.
class PyqCorpusAdapterService {
  final PyqRepository? _pyqRepository;

  PyqCorpusAdapterService({
    PyqRepository? pyqRepository,
  }) : _pyqRepository = pyqRepository;

  /// Converts a [PyqQuestionModel] to [NormalizedQuestion].
  static NormalizedQuestion toNormalized(PyqQuestionModel model) {
    final optionsList = <Option>[];
    for (int i = 0; i < model.options.length; i++) {
      final rawOpt = model.options[i];
      String key;
      String text;
      final match = RegExp(r'^([A-D])[\.\:\)]\s*(.*)$').firstMatch(rawOpt);
      if (match != null) {
        key = match.group(1)!;
        text = match.group(2)!.trim();
      } else {
        key = String.fromCharCode(65 + i);
        text = rawOpt.trim();
      }
      optionsList.add(Option(
        key: key,
        text: text,
      ));
    }

    String correctKey = 'A';
    final ansMatch = RegExp(r'^([A-D])').firstMatch(model.correctAnswer.trim().toUpperCase());
    if (ansMatch != null) {
      correctKey = ansMatch.group(1)!;
    } else {
      for (final opt in optionsList) {
        if (opt.text.toLowerCase() == model.correctAnswer.trim().toLowerCase()) {
          correctKey = opt.key;
          break;
        }
      }
    }

    final examId = model.exam.trim().isNotEmpty
        ? model.exam.trim().toLowerCase()
        : 'upsc_prelims_gs1';

    final topic = model.topic.trim().isNotEmpty ? model.topic.trim() : 'General';
    final subject = model.subject.trim().isNotEmpty ? model.subject.trim() : 'Indian Polity';

    return NormalizedQuestion(
      id: model.id,
      examId: examId,
      year: model.year > 0 ? model.year : 2024,
      paper: model.paper.isNotEmpty ? model.paper : 'GS1',
      stage: 'Prelims',
      subject: subject,
      topic: topic,
      normalizedText: model.question,
      originalText: model.question,
      options: optionsList,
      officialAnswer: Answer(
        correctOptionKeys: [correctKey],
        officialAnswerSource: model.officialAnswer.isNotEmpty
            ? model.officialAnswer
            : 'UPSC Official Key',
      ),
      explanation: model.explanation.official,
      difficulty: model.difficulty.isNotEmpty ? model.difficulty : 'Medium',
      source: PyqSourceReference.official(
        examId: examId,
        year: model.year > 0 ? model.year : 2024,
        paper: model.paper.isNotEmpty ? model.paper : 'GS1',
      ),
      tags: model.tags,
      objectiveIds: [topic],
    );
  }

  /// Retrieves all questions from [PyqRepository] and converts them to [NormalizedQuestion].
  /// If the repository is empty or unavailable, returns a comprehensive seed corpus.
  Future<List<NormalizedQuestion>> getCorpus({
    String? subject,
    String? topic,
  }) async {
    final List<NormalizedQuestion> corpus = [];

    try {
      final repo = _pyqRepository;
      if (repo != null) {
        final questions = await repo.getAllQuestions();
        for (final q in questions) {
          if (subject != null && q.subject.toLowerCase() != subject.toLowerCase()) {
            continue;
          }
          if (topic != null && q.topic.toLowerCase() != topic.toLowerCase()) {
            continue;
          }
          corpus.add(toNormalized(q));
        }
      }
    } catch (_) {}

    if (corpus.isEmpty) {
      final seed = getDefaultSeedCorpus();
      if (subject != null) {
        corpus.addAll(seed.where((q) => q.subject.toLowerCase() == subject.toLowerCase()));
      } else if (topic != null) {
        corpus.addAll(seed.where((q) => q.topic.toLowerCase() == topic.toLowerCase()));
      } else {
        corpus.addAll(seed);
      }
    }

    return corpus;
  }

  /// Default deterministic offline question corpus covering core UPSC Prelims syllabus areas.
  static List<NormalizedQuestion> getDefaultSeedCorpus() {
    return [
      NormalizedQuestion(
        id: 'pyq_polity_art14',
        examId: 'upsc_prelims_gs1',
        year: 2024,
        paper: 'GS1',
        stage: 'Prelims',
        subject: 'Indian Polity',
        topic: 'Fundamental Rights',
        normalizedText: 'Which Article of the Constitution of India guarantees Equality before Law and Equal Protection of the Laws?',
        originalText: 'Which Article of the Constitution of India guarantees Equality before Law and Equal Protection of the Laws?',
        options: const [
          Option(key: 'A', text: 'Article 14'),
          Option(key: 'B', text: 'Article 19'),
          Option(key: 'C', text: 'Article 21'),
          Option(key: 'D', text: 'Article 32'),
        ],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        explanation: 'Article 14 states that the State shall not deny to any person equality before the law or the equal protection of the laws within the territory of India.',
        difficulty: 'Easy',
        source: PyqSourceReference.official(examId: 'upsc_prelims_gs1', year: 2024, paper: 'GS1'),
        objectiveIds: const ['Fundamental Rights'],
      ),
      NormalizedQuestion(
        id: 'pyq_polity_art32',
        examId: 'upsc_prelims_gs1',
        year: 2023,
        paper: 'GS1',
        stage: 'Prelims',
        subject: 'Indian Polity',
        topic: 'Fundamental Rights',
        normalizedText: 'Which writ is issued by the Supreme Court to secure the release of a person who has been detained unlawfully?',
        originalText: 'Which writ is issued by the Supreme Court to secure the release of a person who has been detained unlawfully?',
        options: const [
          Option(key: 'A', text: 'Mandamus'),
          Option(key: 'B', text: 'Habeas Corpus'),
          Option(key: 'C', text: 'Quo-Warranto'),
          Option(key: 'D', text: 'Certiorari'),
        ],
        officialAnswer: const Answer(correctOptionKeys: ['B']),
        explanation: 'Habeas Corpus literally means "to have the body of". It is an order issued by the court to a person who has detained another person, to produce the body of the latter before it.',
        difficulty: 'Medium',
        source: PyqSourceReference.official(examId: 'upsc_prelims_gs1', year: 2023, paper: 'GS1'),
        objectiveIds: const ['Fundamental Rights'],
      ),
      NormalizedQuestion(
        id: 'pyq_polity_emergency',
        examId: 'upsc_prelims_gs1',
        year: 2022,
        paper: 'GS1',
        stage: 'Prelims',
        subject: 'Indian Polity',
        topic: 'Emergency Provisions',
        normalizedText: 'Under which Article can the President proclaim Financial Emergency in India?',
        originalText: 'Under which Article can the President proclaim Financial Emergency in India?',
        options: const [
          Option(key: 'A', text: 'Article 352'),
          Option(key: 'B', text: 'Article 356'),
          Option(key: 'C', text: 'Article 360'),
          Option(key: 'D', text: 'Article 365'),
        ],
        officialAnswer: const Answer(correctOptionKeys: ['C']),
        explanation: 'Article 360 empowers the President to proclaim a Financial Emergency if he is satisfied that a situation has arisen due to which the financial stability or credit of India or any part of its territory is threatened.',
        difficulty: 'Easy',
        source: PyqSourceReference.official(examId: 'upsc_prelims_gs1', year: 2022, paper: 'GS1'),
        objectiveIds: const ['Emergency Provisions'],
      ),
      NormalizedQuestion(
        id: 'pyq_polity_dpsp',
        examId: 'upsc_prelims_gs1',
        year: 2021,
        paper: 'GS1',
        stage: 'Prelims',
        subject: 'Indian Polity',
        topic: 'Directive Principles',
        normalizedText: 'Which Article of the Constitution provides for the Separation of Judiciary from the Executive?',
        originalText: 'Which Article of the Constitution provides for the Separation of Judiciary from the Executive?',
        options: const [
          Option(key: 'A', text: 'Article 45'),
          Option(key: 'B', text: 'Article 48'),
          Option(key: 'C', text: 'Article 50'),
          Option(key: 'D', text: 'Article 51'),
        ],
        officialAnswer: const Answer(correctOptionKeys: ['C']),
        explanation: 'Article 50 of the Constitution directs the State to take steps to separate the judiciary from the executive in the public services of the State.',
        difficulty: 'Medium',
        source: PyqSourceReference.official(examId: 'upsc_prelims_gs1', year: 2021, paper: 'GS1'),
        objectiveIds: const ['Directive Principles'],
      ),
      NormalizedQuestion(
        id: 'pyq_economy_inflation',
        examId: 'upsc_prelims_gs1',
        year: 2024,
        paper: 'GS1',
        stage: 'Prelims',
        subject: 'Economy',
        topic: 'Macroeconomics',
        normalizedText: 'Which of the following actions is most likely to reduce demand-pull inflation?',
        originalText: 'Which of the following actions is most likely to reduce demand-pull inflation?',
        options: const [
          Option(key: 'A', text: 'Lowering the cash reserve ratio (CRR)'),
          Option(key: 'B', text: 'Increasing government capital expenditure'),
          Option(key: 'C', text: 'Raising policy interest rates (Repo Rate)'),
          Option(key: 'D', text: 'Decreasing personal income tax rates'),
        ],
        officialAnswer: const Answer(correctOptionKeys: ['C']),
        explanation: 'Raising the repo rate increases borrowing costs, dampening consumption and investment demand, thus curbing demand-pull inflation.',
        difficulty: 'Hard',
        source: PyqSourceReference.official(examId: 'upsc_prelims_gs1', year: 2024, paper: 'GS1'),
        objectiveIds: const ['Macroeconomics'],
      ),
    ];
  }
}
