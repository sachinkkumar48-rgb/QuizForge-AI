/// Evaluation Method Enum (TITAN-KO-018.0 P18).
///
/// Indicates the deterministic method used to evaluate a submitted question attempt.
library;

enum EvaluationMethod {
  /// Exact match evaluation for multiple choice option selection.
  multipleChoice,

  /// Normalized boolean match evaluation for true/false questions.
  trueFalse,

  /// Keyword/pattern rule-based evaluation for short text answers.
  shortAnswerKeyword,

  /// Manual / non-automated evaluation placeholder for essay/case analysis.
  manual;

  String get displayName => switch (this) {
        EvaluationMethod.multipleChoice => 'Multiple Choice',
        EvaluationMethod.trueFalse => 'True / False',
        EvaluationMethod.shortAnswerKeyword => 'Short Answer (Keyword)',
        EvaluationMethod.manual => 'Manual Evaluation',
      };
}
