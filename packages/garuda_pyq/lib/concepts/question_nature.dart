/// Structural/analytical nature of examination questions.
enum QuestionNature {
  factual,
  conceptual,
  analytical,
  statementBased,
  assertionReason,
  matchTheFollowing,
  chronology,
  caseBased,
  multiStatement,
  mapBased,
  dataBased,
}

extension QuestionNatureX on QuestionNature {
  String get label {
    switch (this) {
      case QuestionNature.factual:
        return 'Factual';
      case QuestionNature.conceptual:
        return 'Conceptual';
      case QuestionNature.analytical:
        return 'Analytical';
      case QuestionNature.statementBased:
        return 'Statement Based';
      case QuestionNature.assertionReason:
        return 'Assertion Reason';
      case QuestionNature.matchTheFollowing:
        return 'Match the Following';
      case QuestionNature.chronology:
        return 'Chronology';
      case QuestionNature.caseBased:
        return 'Case Based';
      case QuestionNature.multiStatement:
        return 'Multi Statement';
      case QuestionNature.mapBased:
        return 'Map Based';
      case QuestionNature.dataBased:
        return 'Data Based';
    }
  }
}
