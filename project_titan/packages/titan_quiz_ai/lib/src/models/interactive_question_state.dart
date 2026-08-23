import 'package:meta/meta.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'answer_status.dart';
import 'assessment_question_type.dart';

/// Immutable model managing user response state, evaluation status, and review tags for an interactive question.
@immutable
class InteractiveQuestionState {
  final QuizQuestion question;
  final Set<int> selectedOptionIndices;
  final AnswerStatus status;
  final Duration timeSpent;
  final bool isMarkedForReview;
  final AssessmentQuestionType questionType;
  final String? sourceChunkId;
  final int? pageNumber;

  InteractiveQuestionState({
    required this.question,
    Set<int>? selectedOptionIndices,
    this.status = AnswerStatus.unanswered,
    this.timeSpent = Duration.zero,
    this.isMarkedForReview = false,
    this.questionType = AssessmentQuestionType.mcq,
    this.sourceChunkId,
    int? pageNumber,
  })  : selectedOptionIndices =
            Set.unmodifiable(selectedOptionIndices ?? const <int>{}),
        pageNumber = pageNumber ?? question.pageReference;

  const InteractiveQuestionState.constState({
    required this.question,
    required this.selectedOptionIndices,
    required this.status,
    required this.timeSpent,
    required this.isMarkedForReview,
    required this.questionType,
    required this.sourceChunkId,
    required this.pageNumber,
  });

  /// True if user has selected at least one option.
  bool get isSelected => selectedOptionIndices.isNotEmpty;

  /// True if answer has been evaluated.
  bool get isSubmitted => status.isEvaluated;

  /// True if answer is verified correct.
  bool get isCorrect => status == AnswerStatus.correct;

  /// Primary selected option index for single-choice compatibility.
  int? get primarySelectedOptionIndex =>
      selectedOptionIndices.isNotEmpty ? selectedOptionIndices.first : null;

  /// Creates a copy with modified values.
  InteractiveQuestionState copyWith({
    QuizQuestion? question,
    Set<int>? selectedOptionIndices,
    AnswerStatus? status,
    Duration? timeSpent,
    bool? isMarkedForReview,
    AssessmentQuestionType? questionType,
    String? sourceChunkId,
    int? pageNumber,
  }) {
    return InteractiveQuestionState(
      question: question ?? this.question,
      selectedOptionIndices:
          selectedOptionIndices ?? this.selectedOptionIndices,
      status: status ?? this.status,
      timeSpent: timeSpent ?? this.timeSpent,
      isMarkedForReview: isMarkedForReview ?? this.isMarkedForReview,
      questionType: questionType ?? this.questionType,
      sourceChunkId: sourceChunkId ?? this.sourceChunkId,
      pageNumber: pageNumber ?? this.pageNumber,
    );
  }

  /// Sets a single option (for MCQ / TrueFalse).
  InteractiveQuestionState selectSingleOption(int index) {
    return copyWith(
      selectedOptionIndices: {index},
      status: AnswerStatus.selected,
    );
  }

  /// Toggles an option (for Multiple Select).
  InteractiveQuestionState toggleMultipleOption(int index) {
    final updated = Set<int>.from(selectedOptionIndices);
    if (updated.contains(index)) {
      updated.remove(index);
    } else {
      updated.add(index);
    }
    return copyWith(
      selectedOptionIndices: updated,
      status: updated.isEmpty ? AnswerStatus.unanswered : AnswerStatus.selected,
    );
  }

  /// Submits and evaluates answer correctness.
  InteractiveQuestionState submitAndEvaluate() {
    if (selectedOptionIndices.isEmpty) {
      return copyWith(status: AnswerStatus.unanswered);
    }

    final isAnswerCorrect = selectedOptionIndices.length == 1 &&
        selectedOptionIndices.contains(question.correctAnswerIndex);

    return copyWith(
      status: isAnswerCorrect ? AnswerStatus.correct : AnswerStatus.incorrect,
    );
  }

  /// Toggles review flag.
  InteractiveQuestionState toggleReviewFlag() {
    return copyWith(isMarkedForReview: !isMarkedForReview);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractiveQuestionState &&
          runtimeType == other.runtimeType &&
          question == other.question &&
          status == other.status &&
          isMarkedForReview == other.isMarkedForReview &&
          questionType == other.questionType &&
          sourceChunkId == other.sourceChunkId &&
          pageNumber == other.pageNumber &&
          selectedOptionIndices.length == other.selectedOptionIndices.length;

  @override
  int get hashCode => Object.hash(
        question,
        status,
        isMarkedForReview,
        questionType,
        sourceChunkId,
        pageNumber,
      );
}
