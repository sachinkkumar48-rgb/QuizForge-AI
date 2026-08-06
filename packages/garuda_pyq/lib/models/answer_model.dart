import 'package:meta/meta.dart';

@immutable
class Answer {
  final List<String> correctOptionKeys; // e.g. ['A'] or ['A', 'B'] if revised key
  final String? descriptiveAnswer;
  final String officialAnswerSource;
  final DateTime? verifiedDate;
  final bool isDropped; // If question was dropped by official commission

  const Answer({
    required this.correctOptionKeys,
    this.descriptiveAnswer,
    this.officialAnswerSource = 'Official Answer Key',
    this.verifiedDate,
    this.isDropped = false,
  });

  Map<String, dynamic> toJson() => {
        'correctOptionKeys': correctOptionKeys,
        'descriptiveAnswer': descriptiveAnswer,
        'officialAnswerSource': officialAnswerSource,
        'verifiedDate': verifiedDate?.toIso8601String(),
        'isDropped': isDropped,
      };

  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
        correctOptionKeys: List<String>.from(json['correctOptionKeys'] ?? []),
        descriptiveAnswer: json['descriptiveAnswer'] as String?,
        officialAnswerSource:
            json['officialAnswerSource'] as String? ?? 'Official Answer Key',
        verifiedDate: json['verifiedDate'] != null
            ? DateTime.parse(json['verifiedDate'] as String)
            : null,
        isDropped: json['isDropped'] as bool? ?? false,
      );
}
