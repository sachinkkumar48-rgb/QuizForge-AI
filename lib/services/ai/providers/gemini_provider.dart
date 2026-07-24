import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../repositories/api_key_repository.dart';
import '../ai_provider.dart';

class GeminiProvider implements AIProvider {
  final ApiKeyRepository _apiKeyRepository;
  final String model;

  GeminiProvider({
    ApiKeyRepository? apiKeyRepository,
    this.model = 'gemini-2.5-flash',
  }) : _apiKeyRepository = apiKeyRepository ?? ApiKeyRepository();

  @override
  String get providerId => 'gemini';

  @override
  String get providerName => 'Google Gemini';

  @override
  Future<bool> isConfigured() async {
    final key = await _apiKeyRepository.loadKey();
    return key != null && key.isNotEmpty;
  }

  Future<String> _callGeminiApi(String prompt) async {
    final apiKey = await _apiKeyRepository.loadKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("Gemini API key not configured.");
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
      throw Exception(
          "Gemini API error (${response.statusCode}): ${response.body}");
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final candidates = data["candidates"] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception("Gemini returned empty candidates.");
    }
    return candidates[0]["content"]["parts"][0]["text"] as String;
  }

  @override
  Future<String> explainAnswer({
    required String question,
    required String selectedAnswer,
    required String correctAnswer,
    String? context,
  }) async {
    final prompt = """
You are an expert UPSC Civil Services AI Tutor.
Explain why option '$correctAnswer' is correct and why '$selectedAnswer' is incorrect or selected for the question below.

Question: $question
${context != null ? "Context: $context" : ""}

Provide a concise, high-yield explanation with key UPSC Prelims concepts highlighted.
""";
    return await _callGeminiApi(prompt);
  }

  @override
  Future<String> generateMnemonic({
    required String topic,
    required String concept,
  }) async {
    final prompt = """
Create a memorable, easy-to-remember mnemonic for UPSC Prelims preparation.

Topic: $topic
Concept: $concept

Include:
1. The Mnemonic phrase/word.
2. Step-by-step breakdown.
3. Quick application example.
""";
    return await _callGeminiApi(prompt);
  }

  @override
  Future<String> suggestRevisionPlan({
    required List<String> weakTopics,
    required int totalDaysAvailable,
  }) async {
    final prompt = """
Create a structured $totalDaysAvailable-day revision schedule for UPSC Prelims focusing on these weak topics:
${weakTopics.join(', ')}

Break down daily focus areas, study hours, and review checkpoints.
""";
    return await _callGeminiApi(prompt);
  }

  @override
  Future<List<String>> recommendPyqs({
    required List<String> weakConcepts,
    required List<String> availablePyqTitles,
  }) async {
    final prompt = """
Given these weak concepts: ${weakConcepts.join(', ')}
Select the top relevant PYQs from this list:
${availablePyqTitles.join('\n')}

Return ONLY a JSON array of selected titles.
""";
    try {
      final res = await _callGeminiApi(prompt);
      final decoded = jsonDecode(_cleanJson(res)) as List;
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return availablePyqTitles.take(3).toList();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateSimilarQuestions({
    required String questionText,
    required String subject,
    required String topic,
    int count = 3,
  }) async {
    final prompt = """
Generate $count UPSC Prelims style questions based on:
Subject: $subject
Topic: $topic
Reference Question: $questionText

Return valid JSON array of objects with keys: "question", "options", "answer", "explanation", "difficulty".
""";
    try {
      final res = await _callGeminiApi(prompt);
      final decoded = jsonDecode(_cleanJson(res)) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<String>> identifyWeakConcepts({
    required Map<String, dynamic> analyticsSummary,
  }) async {
    final prompt = """
Analyze this student analytics JSON:
${jsonEncode(analyticsSummary)}

Identify the top 3-5 weak conceptual areas requiring immediate revision.
Return ONLY a JSON array of strings.
""";
    try {
      final res = await _callGeminiApi(prompt);
      final decoded = jsonDecode(_cleanJson(res)) as List;
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return ["Core Subject Fundamentals"];
    }
  }

  @override
  Future<String> answerUserDoubt({
    required String doubtText,
    String? questionContext,
  }) async {
    final prompt = """
You are an expert UPSC AI Tutor. Answer the student's doubt clearly and accurately.

Student Doubt: $doubtText
${questionContext != null ? "Question Context: $questionContext" : ""}
""";
    return await _callGeminiApi(prompt);
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
