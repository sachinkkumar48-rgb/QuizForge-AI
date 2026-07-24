import '../../../models/analytics_engine_models.dart';
import '../../../models/learning_coach_models.dart';
import '../../../models/pyq_question_model.dart';
import 'learning_coach.dart';

/// OpenAI implementation of [LearningCoach].
class OpenAiLearningCoach implements LearningCoach {
  final String apiKey;
  final String model;

  OpenAiLearningCoach({
    this.apiKey = '',
    this.model = 'gpt-4o-mini',
  });

  @override
  String get providerId => 'openai';

  @override
  String get providerName => 'OpenAI GPT Coach';

  @override
  Future<PerformanceAnalysis> analyzePerformance({
    required LearningInsightsModel insights,
  }) async {
    return PerformanceAnalysis(
      weeklyReport:
          "OpenAI Weekly Analysis: Accuracy ${insights.overallAccuracy.toStringAsFixed(1)}%, streak ${insights.currentStreak} days.",
      weakTopics: insights.weakSubjects.isNotEmpty
          ? insights.weakSubjects
          : ["General Studies"],
      recommendedPyqs: const ["UPSC 2024 Paper 1", "UPSC 2023 Paper 1"],
      recommendedAiQuizzes: const ["OpenAI Polity Quiz", "OpenAI Economy Quiz"],
      studyHoursSuggestion: {"Polity": 2.0, "Economy": 2.0},
      motivationalInsights:
          "🚀 OpenAI Coach: Focus on consistent practice and deep conceptual understanding.",
    );
  }

  @override
  Future<RevisionRecommendation> recommendRevision({
    required List<String> weakTopics,
    required List<PyqQuestionModel> questions,
  }) async {
    return RevisionRecommendation(
      recommendedPyqs: weakTopics.map((t) => "$t OpenAI PYQ").toList(),
      recommendedAiQuizzes: weakTopics.map((t) => "$t OpenAI Quiz").toList(),
      focusTopics: weakTopics,
      actionPlan: "OpenAI Action Plan: Solve 20 questions daily.",
    );
  }

  @override
  Future<WeaknessExplanation> explainWeakness({
    required String weaknessTopic,
    required double accuracyPercent,
  }) async {
    return WeaknessExplanation(
      topic: weaknessTopic,
      explanation:
          "OpenAI Explanation: Conceptual gaps detected in $weaknessTopic (${accuracyPercent.toStringAsFixed(1)}% accuracy).",
      rootCauses: const ["Superficial formula recall", "Time pressure errors"],
      remedialActions: const [
        "Review primary source material",
        "Timed practice tests"
      ],
    );
  }

  @override
  Future<StudyPlan> generateStudyPlan({
    required List<String> weakTopics,
    required int totalDays,
    required double dailyHoursAvailable,
  }) async {
    return StudyPlan(
      title: "OpenAI $totalDays-Day Revision Strategy",
      totalDays: totalDays,
      dailyFocusAreas: List.generate(totalDays, (i) => "Day ${i + 1} Review"),
      suggestedHoursPerDay: dailyHoursAvailable,
      milestones: const ["Finish syllabus review", "Mock test completion"],
    );
  }
}
