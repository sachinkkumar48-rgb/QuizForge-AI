import 'package:meta/meta.dart';

@immutable
class QuestionAnalytics {
  final int appearanceFrequency;
  final int conceptRecurrenceCount;
  final Map<String, int> examDistribution; // Exam Code -> Count
  final Map<int, int> yearTrend; // Year -> Count
  final Map<String, double> difficultyDistribution; // Easy/Medium/Hard -> %
  final List<String> crossExamMappedIds;

  const QuestionAnalytics({
    this.appearanceFrequency = 1,
    this.conceptRecurrenceCount = 0,
    this.examDistribution = const {},
    this.yearTrend = const {},
    this.difficultyDistribution = const {},
    this.crossExamMappedIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'appearanceFrequency': appearanceFrequency,
        'conceptRecurrenceCount': conceptRecurrenceCount,
        'examDistribution': examDistribution,
        'yearTrend': yearTrend.map((k, v) => MapEntry(k.toString(), v)),
        'difficultyDistribution': difficultyDistribution,
        'crossExamMappedIds': crossExamMappedIds,
      };

  factory QuestionAnalytics.fromJson(Map<String, dynamic> json) =>
      QuestionAnalytics(
        appearanceFrequency:
            (json['appearanceFrequency'] as num?)?.toInt() ?? 1,
        conceptRecurrenceCount:
            (json['conceptRecurrenceCount'] as num?)?.toInt() ?? 0,
        examDistribution: Map<String, int>.from(json['examDistribution'] ?? {}),
        yearTrend: (json['yearTrend'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
            ) ??
            const {},
        difficultyDistribution: (json['difficultyDistribution']
                    as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            const {},
        crossExamMappedIds: List<String>.from(json['crossExamMappedIds'] ?? []),
      );
}
