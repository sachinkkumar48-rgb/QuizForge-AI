enum ConfidenceCategory {
  exactMatch,
  strongMatch,
  possibleMatch,
  rejected,
}

class ConfidenceScore {
  final double score;

  const ConfidenceScore(this.score)
      : assert(score >= 0.0 && score <= 1.0, 'Score must be between 0.0 and 1.0');

  ConfidenceCategory get category {
    if (score >= 0.90) {
      return ConfidenceCategory.exactMatch;
    } else if (score >= 0.75) {
      return ConfidenceCategory.strongMatch;
    } else if (score >= 0.50) {
      return ConfidenceCategory.possibleMatch;
    } else {
      return ConfidenceCategory.rejected;
    }
  }

  bool get isAccepted => category != ConfidenceCategory.rejected;

  String get categoryLabel {
    switch (category) {
      case ConfidenceCategory.exactMatch:
        return 'Exact Match (0.90-1.00)';
      case ConfidenceCategory.strongMatch:
        return 'Strong Match (0.75-0.89)';
      case ConfidenceCategory.possibleMatch:
        return 'Possible Match (0.50-0.74)';
      case ConfidenceCategory.rejected:
        return 'Rejected (< 0.50)';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfidenceScore &&
          runtimeType == other.runtimeType &&
          score == other.score;

  @override
  int get hashCode => score.hashCode;
}
