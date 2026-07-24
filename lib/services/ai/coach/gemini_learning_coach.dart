import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../models/analytics_engine_models.dart';
import '../../../models/learning_coach_models.dart';
import '../../../models/pyq_question_model.dart';
import '../../../repositories/api_key_repository.dart';
import 'learning_coach.dart';

/// Default Gemini implementation of [LearningCoach] using Gemini REST API.
class GeminiLearningCoach implements LearningCoach {
  final ApiKeyRepository _apiKeyRepository;
  final String model;

  GeminiLearningCoach({
    ApiKeyRepository? apiKeyRepository,
    this.model = 'gemini-2.5-flash',
  }) : _apiKeyRepository = apiKeyRepository ?? ApiKeyRepository();

  @override
  String get providerId => 'gemini';

  @override
  String get providerName => 'Google Gemini Coach';

  Future<String> _callApi(String prompt) async {
    final apiKey = await _apiKeyRepository.loadKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("Gemini API key not configured for AI Learning Coach.");
    }

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey",
    );

    final response = await http
        .post(
          url,
          headers: const {"Content-Type": "application/json"},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": prompt}
                ]
              }
            ],
            "generationConfig": {"temperature": 0.3}
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception("Gemini Coach API error: ${response.body}");
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final candidates = data["candidates"] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception("Gemini Coach returned empty output.");
    }
    return candidates[0]["content"]["parts"][0]["text"] as String;
  }

  @override
  Future<PerformanceAnalysis> analyzePerformance({
    required LearningInsightsModel insights,
  }) async {
    final prompt = """
You are an elite UPSC Civil Services AI Learning Coach.
Analyze the following student performance metrics:
- Overall Accuracy: ${insights.overallAccuracy.toStringAsFixed(1)}%
- Streak: ${insights.currentStreak} Days (Max: ${insights.longestStreak} Days)
- Questions Solved: Today=${insights.dailyQuestionsSolved}, Week=${insights.weeklyQuestionsSolved}, Month=${insights.monthlyQuestionsSolved}
- Weak Subjects: ${insights.weakSubjects.join(', ')}
- Strong Subjects: ${insights.strongSubjects.join(', ')}

Provide a structured analysis JSON with exact keys:
1. "weeklyReport": (Concise summary of weekly progress and key milestones)
2. "weakTopics": (Array of top weak topic strings requiring focus)
3. "recommendedPyqs": (Array of 3-5 recommended PYQ paper titles)
4. "recommendedAiQuizzes": (Array of 3-5 recommended AI quiz topics)
5. "studyHoursSuggestion": (Object mapping subject name strings to suggested daily hours float, e.g. {"Polity": 1.5, "Economy": 2.0})
6. "motivationalInsights": (Empowering UPSC mindset coaching quote and streak encouragement)

Return ONLY valid raw JSON.
""";

    try {
      final text = await _callApi(prompt);
      final decoded = jsonDecode(_cleanJson(text)) as Map<String, dynamic>;
      return PerformanceAnalysis.fromJson(decoded);
    } catch (_) {
      return PerformanceAnalysis(
        weeklyReport:
            "Weekly Report: Overall Accuracy stands at ${insights.overallAccuracy.toStringAsFixed(1)}%. Solved ${insights.weeklyQuestionsSolved} questions this week.",
        weakTopics: insights.weakSubjects.isNotEmpty
            ? insights.weakSubjects
            : ["General Studies Fundamentals"],
        recommendedPyqs: const [
          "UPSC CSE 2024 GS Paper 1",
          "UPSC CSE 2023 GS Paper 1",
          "UPSC CSE 2022 GS Paper 1"
        ],
        recommendedAiQuizzes: const [
          "Constitutional Framework Quiz",
          "Inflation & Monetary Policy Quiz",
          "Physical Geography & Climate Quiz"
        ],
        studyHoursSuggestion: {
          if (insights.weakSubjects.isNotEmpty)
            insights.weakSubjects.first: 2.5,
          "General Revision": 1.5,
          "Mock Test": 1.0,
        },
        motivationalInsights:
            "🔥 Great effort maintaining a ${insights.currentStreak} day streak! Consistency is the bridge between UPSC preparation and success.",
      );
    }
  }

  @override
  Future<RevisionRecommendation> recommendRevision({
    required List<String> weakTopics,
    required List<PyqQuestionModel> questions,
  }) async {
    final prompt = """
You are an expert UPSC Revision Coach.
Weak topics: ${weakTopics.join(', ')}

Return raw JSON with keys:
"recommendedPyqs": (Array of titles),
"recommendedAiQuizzes": (Array of quiz names),
"focusTopics": (Array of topics),
"actionPlan": (String action plan)
""";

    try {
      final text = await _callApi(prompt);
      final decoded = jsonDecode(_cleanJson(text)) as Map<String, dynamic>;
      return RevisionRecommendation.fromJson(decoded);
    } catch (_) {
      return RevisionRecommendation(
        recommendedPyqs: weakTopics.map((t) => "$t Past Paper").toList(),
        recommendedAiQuizzes:
            weakTopics.map((t) => "$t Targeted Quiz").toList(),
        focusTopics: weakTopics,
        actionPlan:
            "Focus 2 hours daily solving PYQs on weak topics followed by AI explanation review.",
      );
    }
  }

  @override
  Future<WeaknessExplanation> explainWeakness({
    required String weaknessTopic,
    required double accuracyPercent,
  }) async {
    final prompt = """
Explain conceptual weakness for UPSC topic: '$weaknessTopic' (Current Accuracy: ${accuracyPercent.toStringAsFixed(1)}%).
Return raw JSON with keys:
"topic": "$weaknessTopic",
"explanation": (String conceptual breakdown),
"rootCauses": (Array of 2-3 root cause strings),
"remedialActions": (Array of 2-3 remedial action strings)
""";

    try {
      final text = await _callApi(prompt);
      final decoded = jsonDecode(_cleanJson(text)) as Map<String, dynamic>;
      return WeaknessExplanation.fromJson(decoded);
    } catch (_) {
      return WeaknessExplanation(
        topic: weaknessTopic,
        explanation:
            "Accuracy in $weaknessTopic is ${accuracyPercent.toStringAsFixed(1)}%. Core conceptual clarity requires strengthening.",
        rootCauses: const [
          "Confusion between closely related terms",
          "Lack of recent revision"
        ],
        remedialActions: const [
          "Re-read standard reference textbooks",
          "Practice 15 topical PYQs"
        ],
      );
    }
  }

  @override
  Future<StudyPlan> generateStudyPlan({
    required List<String> weakTopics,
    required int totalDays,
    required double dailyHoursAvailable,
  }) async {
    final prompt = """
Generate a $totalDays-day UPSC Study Plan ($dailyHoursAvailable hours/day).
Weak topics: ${weakTopics.join(', ')}

Return raw JSON with keys:
"title": (String title),
"totalDays": $totalDays,
"dailyFocusAreas": (Array of daily focus strings),
"suggestedHoursPerDay": $dailyHoursAvailable,
"milestones": (Array of milestone strings)
""";

    try {
      final text = await _callApi(prompt);
      final decoded = jsonDecode(_cleanJson(text)) as Map<String, dynamic>;
      return StudyPlan.fromJson(decoded);
    } catch (_) {
      return StudyPlan(
        title: "$totalDays-Day Targeted UPSC Revision Plan",
        totalDays: totalDays,
        dailyFocusAreas: List.generate(
          totalDays,
          (i) =>
              "Day ${i + 1}: ${weakTopics.isNotEmpty ? weakTopics[i % weakTopics.length] : 'GS Revision'}",
        ),
        suggestedHoursPerDay: dailyHoursAvailable,
        milestones: const [
          "Complete core weak topic notes review",
          "Solve 50 topical PYQs",
          "Achieve >75% accuracy in full mock"
        ],
      );
    }
  }

  String _cleanJson(String text) {
    String cleaned = text.trim();
    if (cleaned.startsWith("```json")) cleaned = cleaned.substring(7);
    if (cleaned.startsWith("```")) cleaned = cleaned.substring(3);
    if (cleaned.endsWith("```")) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}
