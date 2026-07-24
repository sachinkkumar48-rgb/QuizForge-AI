import 'package:meta/meta.dart';

/// Immutable configuration rules governing a quiz session.
@immutable
class SessionConfiguration {
  final bool allowReview;
  final bool allowSkip;
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final Duration? timeLimit;
  final bool negativeMarking;

  const SessionConfiguration({
    this.allowReview = true,
    this.allowSkip = true,
    this.shuffleQuestions = false,
    this.shuffleOptions = false,
    this.timeLimit,
    this.negativeMarking = true,
  });

  const SessionConfiguration.standard()
      : allowReview = true,
        allowSkip = true,
        shuffleQuestions = false,
        shuffleOptions = false,
        timeLimit = null,
        negativeMarking = true;

  SessionConfiguration copyWith({
    bool? allowReview,
    bool? allowSkip,
    bool? shuffleQuestions,
    bool? shuffleOptions,
    Duration? timeLimit,
    bool? negativeMarking,
  }) {
    return SessionConfiguration(
      allowReview: allowReview ?? this.allowReview,
      allowSkip: allowSkip ?? this.allowSkip,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      shuffleOptions: shuffleOptions ?? this.shuffleOptions,
      timeLimit: timeLimit ?? this.timeLimit,
      negativeMarking: negativeMarking ?? this.negativeMarking,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionConfiguration &&
          runtimeType == other.runtimeType &&
          allowReview == other.allowReview &&
          allowSkip == other.allowSkip &&
          shuffleQuestions == other.shuffleQuestions &&
          shuffleOptions == other.shuffleOptions &&
          timeLimit == other.timeLimit &&
          negativeMarking == other.negativeMarking;

  @override
  int get hashCode => Object.hash(
        allowReview,
        allowSkip,
        shuffleQuestions,
        shuffleOptions,
        timeLimit,
        negativeMarking,
      );

  @override
  String toString() =>
      'SessionConfiguration(review: $allowReview, skip: $allowSkip, shuffleQ: $shuffleQuestions, limit: ${timeLimit?.inMinutes}m)';
}
