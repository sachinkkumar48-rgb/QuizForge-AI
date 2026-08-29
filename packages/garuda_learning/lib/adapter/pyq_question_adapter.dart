/// PYQ Question Adapter (TITAN-KO-026.0 Track 1).
///
/// Adapts [garuda_pyq.Question] to the generic [IQuestionEntity] contract while
/// providing full backward compatibility as a [LegalQuestion].
library;

import 'package:garuda_case_law/garuda_case_law.dart'
    show LegalQuestion, LegalQuestionType, StructuredAnswer;
import 'package:garuda_pyq/models/question_model.dart' as pyq;
import 'package:meta/meta.dart';

import '../domain/entities/question_entity.dart';

@immutable
class PyqQuestionAdapter extends LegalQuestion implements IQuestionEntity {
  /// The underlying canonical PYQ question object.
  final pyq.Question pyqQuestion;
  final List<String> _mappedObjectiveIds;

  PyqQuestionAdapter({
    required this.pyqQuestion,
    List<String> objectiveIds = const [],
  })  : _mappedObjectiveIds = List.unmodifiable(objectiveIds),
        super(
          questionId: pyqQuestion.id,
          questionText: pyqQuestion.originalQuestion,
          questionType: LegalQuestionType.topic,
          sourceRefs: [
            if (pyqQuestion.source.url != null &&
                pyqQuestion.source.url!.isNotEmpty)
              pyqQuestion.source.url!
            else
              'exam:${pyqQuestion.examId}:${pyqQuestion.year}:${pyqQuestion.paper}'
          ],
          answer: StructuredAnswer(
            answerText: _resolveExpectedAnswer(pyqQuestion),
            evidenceRefs: [
              if (pyqQuestion.source.url != null &&
                  pyqQuestion.source.url!.isNotEmpty)
                pyqQuestion.source.url!
              else
                'exam:${pyqQuestion.examId}:${pyqQuestion.year}:${pyqQuestion.paper}'
            ],
            principles: pyqQuestion.conceptsTested,
            provenance: pyqQuestion.source.publisher.isNotEmpty
                ? '${pyqQuestion.source.publisher} (Checksum: ${pyqQuestion.source.checksum})'
                : 'Official Examination PYQ ${pyqQuestion.examId} ${pyqQuestion.year}',
          ),
          provenance: pyqQuestion.source.publisher.isNotEmpty
              ? '${pyqQuestion.source.publisher} (Checksum: ${pyqQuestion.source.checksum})'
              : 'Official Examination PYQ ${pyqQuestion.examId} ${pyqQuestion.year}',
          framing:
              'Official Examination Question (${pyqQuestion.examId.toUpperCase()} ${pyqQuestion.year} ${pyqQuestion.paper})',
        );

  factory PyqQuestionAdapter.fromPyq(
    pyq.Question question, {
    List<String> objectiveIds = const [],
  }) =>
      PyqQuestionAdapter(
        pyqQuestion: question,
        objectiveIds: objectiveIds,
      );

  @override
  String get id => pyqQuestion.id;

  @override
  String get prompt => pyqQuestion.originalQuestion;

  @override
  List<String> get options =>
      pyqQuestion.options.map((o) => '${o.key}. ${o.text}').toList();

  @override
  String get expectedAnswer => answer.answerText;

  @override
  String? get explanation => pyqQuestion.garudaExplanation.isNotEmpty
      ? pyqQuestion.garudaExplanation
      : null;

  @override
  List<String> get objectiveIds => _mappedObjectiveIds;

  @override
  QuestionExamMetadata get examMetadata => QuestionExamMetadata(
        examId: pyqQuestion.examId,
        year: pyqQuestion.year,
        stage: pyqQuestion.stage,
        paper: pyqQuestion.paper,
        shift: pyqQuestion.shift,
        subject: pyqQuestion.subject,
        topic: pyqQuestion.topic,
        subtopic: pyqQuestion.subtopic,
      );

  static String _resolveExpectedAnswer(pyq.Question q) {
    if (q.officialAnswer.correctOptionKeys.isNotEmpty) {
      return q.officialAnswer.correctOptionKeys.join(', ');
    }
    // Fallback if option has isCorrect true
    for (final opt in q.options) {
      if (opt.isCorrect) return opt.key;
    }
    return '';
  }
}
