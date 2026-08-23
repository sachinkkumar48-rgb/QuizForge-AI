/// Represents the supported structural types of questions in TITAN Smart Assessments.
enum AssessmentQuestionType {
  /// Standard 4-option Single-choice question.
  mcq,

  /// Binary True / False question.
  trueFalse,

  /// Multi-select question with one or more correct options.
  multipleSelect,

  /// Assertion and Reason question (UPSC style).
  assertionReason,

  /// Statement-based question (e.g. Which of the statements given above is/are correct?).
  statementBased,

  /// Match the following lists.
  matchTheFollowing,

  /// Fill in the blanks.
  fillInBlank;

  /// String code for serialization and prompt instructions.
  String get typeCode {
    switch (this) {
      case AssessmentQuestionType.mcq:
        return 'mcq';
      case AssessmentQuestionType.trueFalse:
        return 'true_false';
      case AssessmentQuestionType.multipleSelect:
        return 'multiple_select';
      case AssessmentQuestionType.assertionReason:
        return 'assertion_reason';
      case AssessmentQuestionType.statementBased:
        return 'statement_based';
      case AssessmentQuestionType.matchTheFollowing:
        return 'match_the_following';
      case AssessmentQuestionType.fillInBlank:
        return 'fill_in_blank';
    }
  }

  /// Parses a string code into a typed [AssessmentQuestionType].
  static AssessmentQuestionType fromCode(String code) {
    switch (code.trim().toLowerCase()) {
      case 'true_false':
      case 'truefalse':
        return AssessmentQuestionType.trueFalse;
      case 'multiple_select':
      case 'multipleselect':
      case 'multi_select':
        return AssessmentQuestionType.multipleSelect;
      case 'assertion_reason':
      case 'assertionreason':
        return AssessmentQuestionType.assertionReason;
      case 'statement_based':
      case 'statementbased':
        return AssessmentQuestionType.statementBased;
      case 'match_the_following':
      case 'matchthefollowing':
        return AssessmentQuestionType.matchTheFollowing;
      case 'fill_in_blank':
      case 'fillinblank':
        return AssessmentQuestionType.fillInBlank;
      case 'mcq':
      default:
        return AssessmentQuestionType.mcq;
    }
  }
}
