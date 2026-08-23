import 'package:meta/meta.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'assessment_question_type.dart';

/// Immutable domain model specifying WHAT assessment to generate,
/// independent of the underlying AI provider or model execution.
@immutable
class AssessmentBlueprint {
  final String documentId;
  final int targetQuestions;
  final QuizDifficulty difficulty;
  final QuizLanguage language;
  final QuizCategory category;
  final List<AssessmentQuestionType> allowedQuestionTypes;
  final bool explanationRequired;
  final String? topicHint;
  final List<String> selectedChunkIds;
  final int maxTokensPerBatch;
  final String? title;
  final String? description;

  AssessmentBlueprint({
    required this.documentId,
    this.targetQuestions = 5,
    this.difficulty = QuizDifficulty.medium,
    this.language = QuizLanguage.english,
    this.category = QuizCategory.upsc,
    List<AssessmentQuestionType>? allowedQuestionTypes,
    this.explanationRequired = true,
    this.topicHint,
    List<String>? selectedChunkIds,
    this.maxTokensPerBatch = 3000,
    this.title,
    this.description,
  })  : allowedQuestionTypes = List.unmodifiable(
          allowedQuestionTypes ??
              const [
                AssessmentQuestionType.mcq,
                AssessmentQuestionType.trueFalse,
                AssessmentQuestionType.multipleSelect,
              ],
        ),
        selectedChunkIds = List.unmodifiable(selectedChunkIds ?? const []);

  const AssessmentBlueprint.constBlueprint({
    required this.documentId,
    required this.targetQuestions,
    required this.difficulty,
    required this.language,
    required this.category,
    required this.allowedQuestionTypes,
    required this.explanationRequired,
    required this.topicHint,
    required this.selectedChunkIds,
    required this.maxTokensPerBatch,
    required this.title,
    required this.description,
  });

  /// Creates a copy with modified parameters.
  AssessmentBlueprint copyWith({
    String? documentId,
    int? targetQuestions,
    QuizDifficulty? difficulty,
    QuizLanguage? language,
    QuizCategory? category,
    List<AssessmentQuestionType>? allowedQuestionTypes,
    bool? explanationRequired,
    String? topicHint,
    List<String>? selectedChunkIds,
    int? maxTokensPerBatch,
    String? title,
    String? description,
  }) {
    return AssessmentBlueprint(
      documentId: documentId ?? this.documentId,
      targetQuestions: targetQuestions ?? this.targetQuestions,
      difficulty: difficulty ?? this.difficulty,
      language: language ?? this.language,
      category: category ?? this.category,
      allowedQuestionTypes: allowedQuestionTypes ?? this.allowedQuestionTypes,
      explanationRequired: explanationRequired ?? this.explanationRequired,
      topicHint: topicHint ?? this.topicHint,
      selectedChunkIds: selectedChunkIds ?? this.selectedChunkIds,
      maxTokensPerBatch: maxTokensPerBatch ?? this.maxTokensPerBatch,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentBlueprint &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          targetQuestions == other.targetQuestions &&
          difficulty == other.difficulty &&
          language == other.language &&
          category == other.category &&
          explanationRequired == other.explanationRequired &&
          topicHint == other.topicHint &&
          maxTokensPerBatch == other.maxTokensPerBatch &&
          title == other.title &&
          description == other.description;

  @override
  int get hashCode => Object.hash(
        documentId,
        targetQuestions,
        difficulty,
        language,
        category,
        explanationRequired,
        topicHint,
        maxTokensPerBatch,
        title,
        description,
      );
}
