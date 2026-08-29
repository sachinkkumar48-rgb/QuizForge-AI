/// LegalQuestion Adapter (TITAN-KO-026.0 Track 1).
///
/// Adapts P15 [LegalQuestion] to the generic [IQuestionEntity] contract while
/// preserving 100% backward compatibility as an instance of [LegalQuestion].
library;

import 'package:garuda_case_law/garuda_case_law.dart' show LegalQuestion;
import 'package:meta/meta.dart';

import '../domain/entities/question_entity.dart';

@immutable
class LegalQuestionAdapter extends LegalQuestion implements IQuestionEntity {
  final List<String> _mappedObjectiveIds;
  final QuestionExamMetadata? _examMetadata;

  LegalQuestionAdapter({
    required super.questionId,
    required super.questionText,
    required super.questionType,
    required super.sourceRefs,
    required super.answer,
    required super.provenance,
    required super.framing,
    List<String> objectiveIds = const [],
    QuestionExamMetadata? examMetadata,
  })  : _mappedObjectiveIds = List.unmodifiable(objectiveIds),
        _examMetadata = examMetadata;

  factory LegalQuestionAdapter.fromLegalQuestion(
    LegalQuestion question, {
    List<String> objectiveIds = const [],
    QuestionExamMetadata? examMetadata,
  }) {
    return LegalQuestionAdapter(
      questionId: question.questionId,
      questionText: question.questionText,
      questionType: question.questionType,
      sourceRefs: question.sourceRefs,
      answer: question.answer,
      provenance: question.provenance,
      framing: question.framing,
      objectiveIds: objectiveIds,
      examMetadata: examMetadata,
    );
  }

  @override
  String get id => questionId;

  @override
  String get prompt => questionText;

  @override
  List<String> get options => const [];

  @override
  String get expectedAnswer => answer.answerText;

  @override
  String? get explanation =>
      answer.principles.isNotEmpty ? answer.principles.join('; ') : null;

  @override
  List<String> get objectiveIds => _mappedObjectiveIds;

  @override
  QuestionExamMetadata? get examMetadata => _examMetadata;
}
