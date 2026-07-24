import '../../../models/analytics_engine_models.dart';
import '../../../models/learning_coach_models.dart';
import '../../../models/pyq_question_model.dart';

/// Abstract contract for AI Learning Coach.
/// Ensures the application is NOT tightly coupled to Gemini or any single AI provider.
abstract class LearningCoach {
  /// Provider unique identifier (e.g. 'gemini', 'openai', 'claude', 'local_llm')
  String get providerId;

  /// Provider display name
  String get providerName;

  /// 1. Comprehensive Performance Analysis
  /// Generates Weekly report, Weak topics, Recommended PYQs, Recommended AI quizzes, Study hours suggestion, Motivational insights
  Future<PerformanceAnalysis> analyzePerformance({
    required LearningInsightsModel insights,
  });

  /// 2. Targeted Revision Recommendations
  Future<RevisionRecommendation> recommendRevision({
    required List<String> weakTopics,
    required List<PyqQuestionModel> questions,
  });

  /// 3. Explain Conceptual Weakness
  Future<WeaknessExplanation> explainWeakness({
    required String weaknessTopic,
    required double accuracyPercent,
  });

  /// 4. Generate Structured Study Plan
  Future<StudyPlan> generateStudyPlan({
    required List<String> weakTopics,
    required int totalDays,
    required double dailyHoursAvailable,
  });
}
