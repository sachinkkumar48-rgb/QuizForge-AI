// Structured output models for the AI Learning Coach system.

class PerformanceAnalysis {
  final String weeklyReport;
  final List<String> weakTopics;
  final List<String> recommendedPyqs;
  final List<String> recommendedAiQuizzes;
  final Map<String, double> studyHoursSuggestion;
  final String motivationalInsights;

  PerformanceAnalysis({
    required this.weeklyReport,
    required this.weakTopics,
    required this.recommendedPyqs,
    required this.recommendedAiQuizzes,
    required this.studyHoursSuggestion,
    required this.motivationalInsights,
  });

  Map<String, dynamic> toJson() => {
        'weeklyReport': weeklyReport,
        'weakTopics': weakTopics,
        'recommendedPyqs': recommendedPyqs,
        'recommendedAiQuizzes': recommendedAiQuizzes,
        'studyHoursSuggestion': studyHoursSuggestion,
        'motivationalInsights': motivationalInsights,
      };

  factory PerformanceAnalysis.fromJson(Map<String, dynamic> json) =>
      PerformanceAnalysis(
        weeklyReport: json['weeklyReport'] as String? ?? '',
        weakTopics: json['weakTopics'] != null
            ? List<String>.from(json['weakTopics'] as List)
            : const [],
        recommendedPyqs: json['recommendedPyqs'] != null
            ? List<String>.from(json['recommendedPyqs'] as List)
            : const [],
        recommendedAiQuizzes: json['recommendedAiQuizzes'] != null
            ? List<String>.from(json['recommendedAiQuizzes'] as List)
            : const [],
        studyHoursSuggestion: json['studyHoursSuggestion'] != null
            ? (json['studyHoursSuggestion'] as Map)
                .map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
            : const {},
        motivationalInsights: json['motivationalInsights'] as String? ?? '',
      );
}

class WeaknessExplanation {
  final String topic;
  final String explanation;
  final List<String> rootCauses;
  final List<String> remedialActions;

  WeaknessExplanation({
    required this.topic,
    required this.explanation,
    required this.rootCauses,
    required this.remedialActions,
  });

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'explanation': explanation,
        'rootCauses': rootCauses,
        'remedialActions': remedialActions,
      };

  factory WeaknessExplanation.fromJson(Map<String, dynamic> json) =>
      WeaknessExplanation(
        topic: json['topic'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        rootCauses: json['rootCauses'] != null
            ? List<String>.from(json['rootCauses'] as List)
            : const [],
        remedialActions: json['remedialActions'] != null
            ? List<String>.from(json['remedialActions'] as List)
            : const [],
      );
}

class StudyPlan {
  final String title;
  final int totalDays;
  final List<String> dailyFocusAreas;
  final double suggestedHoursPerDay;
  final List<String> milestones;

  StudyPlan({
    required this.title,
    required this.totalDays,
    required this.dailyFocusAreas,
    required this.suggestedHoursPerDay,
    required this.milestones,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'totalDays': totalDays,
        'dailyFocusAreas': dailyFocusAreas,
        'suggestedHoursPerDay': suggestedHoursPerDay,
        'milestones': milestones,
      };

  factory StudyPlan.fromJson(Map<String, dynamic> json) => StudyPlan(
        title: json['title'] as String? ?? '',
        totalDays: json['totalDays'] as int? ?? 7,
        dailyFocusAreas: json['dailyFocusAreas'] != null
            ? List<String>.from(json['dailyFocusAreas'] as List)
            : const [],
        suggestedHoursPerDay:
            (json['suggestedHoursPerDay'] as num? ?? 4.0).toDouble(),
        milestones: json['milestones'] != null
            ? List<String>.from(json['milestones'] as List)
            : const [],
      );
}

class RevisionRecommendation {
  final List<String> recommendedPyqs;
  final List<String> recommendedAiQuizzes;
  final List<String> focusTopics;
  final String actionPlan;

  RevisionRecommendation({
    required this.recommendedPyqs,
    required this.recommendedAiQuizzes,
    required this.focusTopics,
    required this.actionPlan,
  });

  Map<String, dynamic> toJson() => {
        'recommendedPyqs': recommendedPyqs,
        'recommendedAiQuizzes': recommendedAiQuizzes,
        'focusTopics': focusTopics,
        'actionPlan': actionPlan,
      };

  factory RevisionRecommendation.fromJson(Map<String, dynamic> json) =>
      RevisionRecommendation(
        recommendedPyqs: json['recommendedPyqs'] != null
            ? List<String>.from(json['recommendedPyqs'] as List)
            : const [],
        recommendedAiQuizzes: json['recommendedAiQuizzes'] != null
            ? List<String>.from(json['recommendedAiQuizzes'] as List)
            : const [],
        focusTopics: json['focusTopics'] != null
            ? List<String>.from(json['focusTopics'] as List)
            : const [],
        actionPlan: json['actionPlan'] as String? ?? '',
      );
}
