import 'package:meta/meta.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'assessment_question_type.dart';
import 'topic_mastery.dart';

/// Immutable domain model representing a learner''s comprehensive proficiency and historical progression.
@immutable
class LearnerProfile {
  final String learnerId;
  final int totalAssessments;
  final int totalQuestionsAttempted;
  final int totalCorrect;
  final int totalIncorrect;
  final double overallAccuracy;
  final double overallMastery;
  final Map<String, TopicMastery> topicPerformance;
  final Map<AssessmentQuestionType, double> questionTypePerformance;
  final Map<QuizDifficulty, double> difficultyPerformance;
  final List<double> recentPerformance;
  final List<String> weakTopics;
  final List<String> strongTopics;
  final Map<String, double> masteryLevels;
  final DateTime lastUpdated;

  LearnerProfile({
    required this.learnerId,
    this.totalAssessments = 0,
    this.totalQuestionsAttempted = 0,
    this.totalCorrect = 0,
    this.totalIncorrect = 0,
    double? overallAccuracy,
    double? overallMastery,
    Map<String, TopicMastery>? topicPerformance,
    Map<AssessmentQuestionType, double>? questionTypePerformance,
    Map<QuizDifficulty, double>? difficultyPerformance,
    List<double>? recentPerformance,
    List<String>? weakTopics,
    List<String>? strongTopics,
    Map<String, double>? masteryLevels,
    DateTime? lastUpdated,
  })  : overallAccuracy = overallAccuracy ??
            (totalQuestionsAttempted > 0
                ? (totalCorrect / totalQuestionsAttempted).clamp(0.0, 1.0)
                : 0.0),
        overallMastery =
            overallMastery ?? _calculateOverallMastery(topicPerformance),
        topicPerformance = Map.unmodifiable(topicPerformance ?? const {}),
        questionTypePerformance =
            Map.unmodifiable(questionTypePerformance ?? const {}),
        difficultyPerformance =
            Map.unmodifiable(difficultyPerformance ?? const {}),
        recentPerformance = List.unmodifiable(recentPerformance ?? const []),
        weakTopics = List.unmodifiable(
            weakTopics ?? _extractWeakTopics(topicPerformance)),
        strongTopics = List.unmodifiable(
            strongTopics ?? _extractStrongTopics(topicPerformance)),
        masteryLevels = Map.unmodifiable(
            masteryLevels ?? _extractMasteryLevels(topicPerformance)),
        lastUpdated = lastUpdated ?? DateTime.now();

  const LearnerProfile.constProfile({
    required this.learnerId,
    required this.totalAssessments,
    required this.totalQuestionsAttempted,
    required this.totalCorrect,
    required this.totalIncorrect,
    required this.overallAccuracy,
    required this.overallMastery,
    required this.topicPerformance,
    required this.questionTypePerformance,
    required this.difficultyPerformance,
    required this.recentPerformance,
    required this.weakTopics,
    required this.strongTopics,
    required this.masteryLevels,
    required this.lastUpdated,
  });

  /// Factory for a brand new learner profile with zero prior activity.
  factory LearnerProfile.empty({String learnerId = 'default_learner'}) {
    return LearnerProfile(
      learnerId: learnerId,
      totalAssessments: 0,
      totalQuestionsAttempted: 0,
      totalCorrect: 0,
      totalIncorrect: 0,
      overallAccuracy: 0.0,
      overallMastery: 0.0,
      topicPerformance: const {},
      questionTypePerformance: const {},
      difficultyPerformance: const {},
      recentPerformance: const [],
      weakTopics: const [],
      strongTopics: const [],
      masteryLevels: const {},
      lastUpdated: DateTime.now(),
    );
  }

  static double _calculateOverallMastery(Map<String, TopicMastery>? topics) {
    if (topics == null || topics.isEmpty) return 0.0;
    var sum = 0.0;
    for (final t in topics.values) {
      sum += t.masteryScore;
    }
    return (sum / topics.length).clamp(0.0, 1.0);
  }

  static List<String> _extractWeakTopics(Map<String, TopicMastery>? topics) {
    if (topics == null || topics.isEmpty) return const [];
    final weak = <String>[];
    for (final entry in topics.entries) {
      if (entry.value.isWeak) {
        weak.add(entry.key);
      }
    }
    return weak;
  }

  static List<String> _extractStrongTopics(Map<String, TopicMastery>? topics) {
    if (topics == null || topics.isEmpty) return const [];
    final strong = <String>[];
    for (final entry in topics.entries) {
      if (entry.value.isStrong) {
        strong.add(entry.key);
      }
    }
    return strong;
  }

  static Map<String, double> _extractMasteryLevels(
      Map<String, TopicMastery>? topics) {
    if (topics == null || topics.isEmpty) return const {};
    final map = <String, double>{};
    for (final entry in topics.entries) {
      map[entry.key] = entry.value.masteryScore;
    }
    return map;
  }

  bool get isEmpty => totalAssessments == 0 && totalQuestionsAttempted == 0;
  bool get hasWeakTopics => weakTopics.isNotEmpty;
  bool get hasStrongTopics => strongTopics.isNotEmpty;

  LearnerProfile copyWith({
    String? learnerId,
    int? totalAssessments,
    int? totalQuestionsAttempted,
    int? totalCorrect,
    int? totalIncorrect,
    double? overallAccuracy,
    double? overallMastery,
    Map<String, TopicMastery>? topicPerformance,
    Map<AssessmentQuestionType, double>? questionTypePerformance,
    Map<QuizDifficulty, double>? difficultyPerformance,
    List<double>? recentPerformance,
    List<String>? weakTopics,
    List<String>? strongTopics,
    Map<String, double>? masteryLevels,
    DateTime? lastUpdated,
  }) {
    return LearnerProfile(
      learnerId: learnerId ?? this.learnerId,
      totalAssessments: totalAssessments ?? this.totalAssessments,
      totalQuestionsAttempted:
          totalQuestionsAttempted ?? this.totalQuestionsAttempted,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalIncorrect: totalIncorrect ?? this.totalIncorrect,
      overallAccuracy: overallAccuracy ?? this.overallAccuracy,
      overallMastery: overallMastery ?? this.overallMastery,
      topicPerformance: topicPerformance ?? this.topicPerformance,
      questionTypePerformance:
          questionTypePerformance ?? this.questionTypePerformance,
      difficultyPerformance:
          difficultyPerformance ?? this.difficultyPerformance,
      recentPerformance: recentPerformance ?? this.recentPerformance,
      weakTopics: weakTopics ?? this.weakTopics,
      strongTopics: strongTopics ?? this.strongTopics,
      masteryLevels: masteryLevels ?? this.masteryLevels,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearnerProfile &&
          runtimeType == other.runtimeType &&
          learnerId == other.learnerId &&
          totalAssessments == other.totalAssessments &&
          totalQuestionsAttempted == other.totalQuestionsAttempted &&
          overallAccuracy == other.overallAccuracy &&
          overallMastery == other.overallMastery;

  @override
  int get hashCode => Object.hash(
        learnerId,
        totalAssessments,
        totalQuestionsAttempted,
        overallAccuracy,
        overallMastery,
      );
}
