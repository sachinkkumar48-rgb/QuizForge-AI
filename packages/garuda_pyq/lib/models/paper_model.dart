import 'package:meta/meta.dart';

@immutable
class Paper {
  final String id;
  final String examId;
  final int year;
  final String stage; // e.g. Prelims, Mains, Phase I
  final String paperName; // e.g. GS Paper I, CSAT, Phase I Paper 1
  final String? shift; // e.g. Shift 1, Morning
  final int totalQuestions;
  final int? durationMinutes;
  final String defaultLanguage;

  const Paper({
    required this.id,
    required this.examId,
    required this.year,
    required this.stage,
    required this.paperName,
    this.shift,
    this.totalQuestions = 100,
    this.durationMinutes = 120,
    this.defaultLanguage = 'en',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'examId': examId,
        'year': year,
        'stage': stage,
        'paperName': paperName,
        'shift': shift,
        'totalQuestions': totalQuestions,
        'durationMinutes': durationMinutes,
        'defaultLanguage': defaultLanguage,
      };

  factory Paper.fromJson(Map<String, dynamic> json) => Paper(
        id: json['id'] as String,
        examId: json['examId'] as String,
        year: json['year'] as int,
        stage: json['stage'] as String,
        paperName: json['paperName'] as String,
        shift: json['shift'] as String?,
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 100,
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 120,
        defaultLanguage: json['defaultLanguage'] as String? ?? 'en',
      );

  Paper copyWith({
    String? id,
    String? examId,
    int? year,
    String? stage,
    String? paperName,
    String? shift,
    int? totalQuestions,
    int? durationMinutes,
    String? defaultLanguage,
  }) {
    return Paper(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      year: year ?? this.year,
      stage: stage ?? this.stage,
      paperName: paperName ?? this.paperName,
      shift: shift ?? this.shift,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
    );
  }
}
