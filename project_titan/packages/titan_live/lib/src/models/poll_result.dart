import 'package:meta/meta.dart';

/// Immutable domain model representing poll results.
@immutable
class PollResult {
  final String pollId;
  final int totalVotes;
  final Map<String, int> optionVotes;
  final String? winningOptionId;

  const PollResult({
    required this.pollId,
    required this.totalVotes,
    required this.optionVotes,
    this.winningOptionId,
  });

  Map<String, dynamic> toJson() => {
        'pollId': pollId,
        'totalVotes': totalVotes,
        'optionVotes': optionVotes,
        'winningOptionId': winningOptionId,
      };

  factory PollResult.fromJson(Map<String, dynamic> json) => PollResult(
        pollId: json['pollId'] as String,
        totalVotes: json['totalVotes'] as int,
        optionVotes: Map<String, int>.from(json['optionVotes'] as Map? ?? {}),
        winningOptionId: json['winningOptionId'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PollResult &&
          runtimeType == other.runtimeType &&
          pollId == other.pollId &&
          totalVotes == other.totalVotes &&
          winningOptionId == other.winningOptionId;

  @override
  int get hashCode => Object.hash(pollId, totalVotes, winningOptionId);
}
