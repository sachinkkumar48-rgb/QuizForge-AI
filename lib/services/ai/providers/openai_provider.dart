import 'dart:convert';
import 'package:http/http.dart' as http;

import '../ai_provider.dart';

class OpenAiProvider implements AIProvider {
  final String apiKey;
  final String model;
  final String baseUrl;

  OpenAiProvider({
    this.apiKey = '',
    this.model = 'gpt-4o',
    this.baseUrl = 'https://api.openai.com/v1',
  });

  @override
  String get providerId => 'openai';

  @override
  String get providerName => 'OpenAI GPT-4o';

  @override
  Future<bool> isConfigured() async {
    return apiKey.isNotEmpty;
  }

  Future<String> _callOpenAiApi(String prompt) async {
    if (apiKey.isEmpty) {
      throw Exception("OpenAI API key not configured.");
    }

    final url = Uri.parse("$baseUrl/chat/completions");
    final response = await http
        .post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $apiKey",
          },
          body: jsonEncode({
            "model": model,
            "messages": [
              {
                "role": "system",
                "content":
                    "You are an expert UPSC Civil Services AI Tutor delivering high-yield learning materials."
              },
              {"role": "user", "content": prompt}
            ],
            "temperature": 0.3,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
          "OpenAI API error (${response.statusCode}): ${response.body}");
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final choices = data["choices"] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception("OpenAI returned empty choices.");
    }
    return choices[0]["message"]["content"] as String;
  }

  @override
  Future<String> explainAnswer({
    required String question,
    required String selectedAnswer,
    required String correctAnswer,
    String? context,
  }) async {
    final prompt = """
Explain why option '$correctAnswer' is correct and '$selectedAnswer' is incorrect for:
Question: $question
${context != null ? "Context: $context" : ""}
""";
    return await _callOpenAiApi(prompt);
  }

  @override
  Future<String> generateMnemonic({
    required String topic,
    required String concept,
  }) async {
    final prompt =
        "Create a UPSC mnemonic for Topic: $topic, Concept: $concept.";
    return await _callOpenAiApi(prompt);
  }

  @override
  Future<String> suggestRevisionPlan({
    required List<String> weakTopics,
    required int totalDaysAvailable,
  }) async {
    final prompt =
        "Create a $totalDaysAvailable-day revision plan for weak topics: ${weakTopics.join(', ')}.";
    return await _callOpenAiApi(prompt);
  }

  @override
  Future<List<String>> recommendPyqs({
    required List<String> weakConcepts,
    required List<String> availablePyqTitles,
  }) async {
    final prompt = """
Recommend PYQs from this list: ${availablePyqTitles.join(', ')} for weak concepts: ${weakConcepts.join(', ')}.
Return ONLY a JSON array of strings.
""";
    try {
      final res = await _callOpenAiApi(prompt);
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
Generate $count UPSC Prelims style questions for Subject: $subject, Topic: $topic, Reference: $questionText.
Return valid JSON array of objects with keys: "question", "options", "answer", "explanation", "difficulty".
""";
    try {
      final res = await _callOpenAiApi(prompt);
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
Analyze analytics: ${jsonEncode(analyticsSummary)}. Identify top 3 weak concept areas as a JSON array of strings.
""";
    try {
      final res = await _callOpenAiApi(prompt);
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
Answer UPSC doubt: $doubtText
${questionContext != null ? "Context: $questionContext" : ""}
""";
    return await _callOpenAiApi(prompt);
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
