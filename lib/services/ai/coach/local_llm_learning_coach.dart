import '../../../models/analytics_engine_models.dart';
import '../../../models/learning_coach_models.dart';
import '../../../models/pyq_question_model.dart';
import 'learning_coach.dart';

/// Local LLM implementation of [LearningCoach] (e.g. Ollama, LM Studio, Llama-3).
class LocalLlmLearningCoach implements LearningCoach {
  final String baseUrl;
  final String model;

  LocalLlmLearningCoach({
    this.baseUrl = 'http://localhost:11434',
    this.model = 'llama3',
  });

  @override
  String get providerId => 'local_llm';

  @override
  String get providerName => 'Local LLM (Offline Coach)';

  @override
  Future<PerformanceAnalysis> analyzePerformance({
    required LearningInsightsModel insights,
  }) async {
    return PerformanceAnalysis(
      weeklyReport:
          "Local LLM Report: Offline performance tracking at ${insights.overallAccuracy.toStringAsFixed(1)}% accuracy.",
      weakTopics: insights.weakSubjects.isNotEmpty
          ? insights.weakSubjects
          : ["General Revision"],
      recommendedPyqs: const ["Offline UPSC Question Bank"],
      recommendedAiQuizzes: const ["Local Practice Drill"],
      studyHoursSuggestion: {"General Revision": 3.0},
      motivationalInsights:
          "🛡️ Local LLM Coach: Privacy-first offline study momentum!",
    );
  }

  @override
  Future<RevisionRecommendation> recommendRevision({
    required List<String> weakTopics,
    required List<PyqQuestionModel> questions,
  }) async {
    return RevisionRecommendation(
      recommendedPyqs: weakTopics.map((t) => "$t Offline PYQ").toList(),
      recommendedAiQuizzes: weakTopics.map((t) => "$t Offline Drill").toList(),
      focusTopics: weakTopics,
      actionPlan: "Local LLM Action Plan: Offline flashcard review.",
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
          "Local LLM Explanation: Topic $weaknessTopic accuracy is ${accuracyPercent.toStringAsFixed(1)}%.",
      rootCauses: const ["Need more offline practice"],
      remedialActions: const ["Review static notes"],
    );
  }

  @override
  Future<StudyPlan> generateStudyPlan({
    required List<String> weakTopics,
    required int totalDays,
    required double dailyHoursAvailable,
  }) async {
    return StudyPlan(
      title: "Local LLM $totalDays-Day Offline Study Schedule",
      totalDays: totalDays,
      dailyFocusAreas:
          List.generate(totalDays, (i) => "Day ${i + 1} Offline Revision"),
      suggestedHoursPerDay: dailyHoursAvailable,
      milestones: const ["Complete offline drill"],
    );
  }
}
