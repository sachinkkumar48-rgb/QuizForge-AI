library;

import 'package:meta/meta.dart';

/// Output result of the rule-based Link Scoring Engine.
@immutable
class LinkScoreResult {
  final double score;
  final Map<String, double> ruleBreakdown;
  final String primaryReason;

  const LinkScoreResult({
    required this.score,
    required this.ruleBreakdown,
    required this.primaryReason,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'ruleBreakdown': ruleBreakdown,
        'primaryReason': primaryReason,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LinkScoreResult &&
        other.score == score &&
        other.primaryReason == primaryReason;
  }

  @override
  int get hashCode => Object.hash(score, primaryReason);
}
