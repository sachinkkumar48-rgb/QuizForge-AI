import 'package:meta/meta.dart';
import 'assessment_rubric.dart';
import 'difficulty_profile.dart';

/// Immutable domain model representing an assessment blueprint configuration.
@immutable
class AssessmentBlueprint {
  final String id;
  final String title;
  final String subjectCategory;
  final Map<String, double>
      topicWeights; // e.g. {'Polity': 0.4, 'History': 0.6}
  final DifficultyProfile difficultyProfile;
  final int totalQuestions;
  final int timeLimitMinutes;
  final AssessmentRubric rubric;

  const AssessmentBlueprint({
    required this.id,
    required this.title,
    required this.subjectCategory,
    this.topicWeights = const {},
    this.difficultyProfile = const DifficultyProfile(),
    this.totalQuestions = 10,
    this.timeLimitMinutes = 30,
    this.rubric = const AssessmentRubric(id: 'r_std', name: 'Standard'),
  });

  AssessmentBlueprint copyWith({
    String? id,
    String? title,
    String? subjectCategory,
    Map<String, double>? topicWeights,
    DifficultyProfile? difficultyProfile,
    int? totalQuestions,
    int? timeLimitMinutes,
    AssessmentRubric? rubric,
  }) {
    return AssessmentBlueprint(
      id: id ?? this.id,
      title: title ?? this.title,
      subjectCategory: subjectCategory ?? this.subjectCategory,
      topicWeights: topicWeights ?? this.topicWeights,
      difficultyProfile: difficultyProfile ?? this.difficultyProfile,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      rubric: rubric ?? this.rubric,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subjectCategory': subjectCategory,
        'topicWeights': topicWeights,
        'difficultyProfile': difficultyProfile.toJson(),
        'totalQuestions': totalQuestions,
        'timeLimitMinutes': timeLimitMinutes,
        'rubric': rubric.toJson(),
      };

  factory AssessmentBlueprint.fromJson(Map<String, dynamic> json) =>
      AssessmentBlueprint(
        id: json['id'] as String,
        title: json['title'] as String,
        subjectCategory:
            json['subjectCategory'] as String? ?? 'General Studies',
        topicWeights:
            (json['topicWeights'] as Map? ?? {}).cast<String, double>(),
        difficultyProfile: json['difficultyProfile'] != null
            ? DifficultyProfile.fromJson(
                json['difficultyProfile'] as Map<String, dynamic>)
            : const DifficultyProfile(),
        totalQuestions: json['totalQuestions'] as int? ?? 10,
        timeLimitMinutes: json['timeLimitMinutes'] as int? ?? 30,
        rubric: json['rubric'] != null
            ? AssessmentRubric.fromJson(json['rubric'] as Map<String, dynamic>)
            : const AssessmentRubric(id: 'r_std', name: 'Standard'),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentBlueprint &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => Object.hash(id, title);
}
