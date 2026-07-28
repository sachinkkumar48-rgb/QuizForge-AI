import 'package:meta/meta.dart';

/// Immutable domain model representing an option in a live class poll.
@immutable
class PollOption {
  final String id;
  final String optionText;
  final int voteCount;

  const PollOption({
    required this.id,
    required this.optionText,
    this.voteCount = 0,
  });

  PollOption copyWith({
    String? id,
    String? optionText,
    int? voteCount,
  }) {
    return PollOption(
      id: id ?? this.id,
      optionText: optionText ?? this.optionText,
      voteCount: voteCount ?? this.voteCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'optionText': optionText,
        'voteCount': voteCount,
      };

  factory PollOption.fromJson(Map<String, dynamic> json) => PollOption(
        id: json['id'] as String,
        optionText: json['optionText'] as String,
        voteCount: json['voteCount'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PollOption &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          optionText == other.optionText &&
          voteCount == other.voteCount;

  @override
  int get hashCode => Object.hash(id, optionText, voteCount);
}
