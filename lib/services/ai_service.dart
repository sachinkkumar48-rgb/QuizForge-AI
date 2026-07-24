import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/quiz_model.dart';
import '../repositories/api_key_repository.dart';

import 'ai/ai_provider_factory.dart';
import 'ai/providers/claude_provider.dart';
import 'ai/providers/gemini_provider.dart';
import 'ai/providers/local_llm_provider.dart';
import 'ai/providers/openai_provider.dart';

class AiService {
  AiService._();

  static const String _model = "gemini-2.5-flash";

  static void initProviders({
    String? openAiKey,
    String? claudeKey,
    String? localLlmUrl,
  }) {
    AiProviderFactory.registerProvider(
      AiProviderType.gemini,
      GeminiProvider(),
    );
    AiProviderFactory.registerProvider(
      AiProviderType.openAi,
      OpenAiProvider(apiKey: openAiKey ?? ''),
    );
    AiProviderFactory.registerProvider(
      AiProviderType.claude,
      ClaudeProvider(apiKey: claudeKey ?? ''),
    );
    AiProviderFactory.registerProvider(
      AiProviderType.localLlm,
      LocalLlmProvider(hostUrl: localLlmUrl ?? 'http://localhost:11434'),
    );
  }

  static Future<List<QuizQuestion>> generateQuiz(
    String text, {
    required int questionCount,
  }) async {
    return generateQuizBatch(
      text,
      batchSize: questionCount,
      startIndex: 1,
    );
  }

  static Future<List<QuizQuestion>> generateQuizBatch(
    String text, {
    required int batchSize,
    required int startIndex,
  }) async {
    final apiKey = await ApiKeyRepository().loadKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        "Gemini API key not found. Please set your API key in Settings.",
      );
    }

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey",
    );

    final prompt = _buildBatchPrompt(
      text: text,
      batchSize: batchSize,
      startIndex: startIndex,
    );

    http.Response? response;

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        response = await http
            .post(
              url,
              headers: const {
                "Content-Type": "application/json",
              },
              body: jsonEncode({
                "contents": [
                  {
                    "parts": [
                      {
                        "text": prompt,
                      }
                    ]
                  }
                ],
                "generationConfig": {
                  "temperature": 0.4,
                  "responseMimeType": "application/json",
                }
              }),
            )
            .timeout(const Duration(seconds: 60));
      } catch (e) {
        if (e is TimeoutException) {
          throw Exception(
              "Connection timed out. Please check your network and try again.");
        }
        if (e.toString().contains("SocketException") ||
            e.toString().contains("ClientException")) {
          throw Exception(
              "Network unavailable. Please check your internet connection.");
        }
        rethrow;
      }

      if (response.statusCode == 200) {
        break;
      }

      // Retry only if Gemini is temporarily busy.
      if (response.statusCode == 503 && attempt < 3) {
        await Future.delayed(
          Duration(seconds: attempt * 2),
        );
        continue;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        final bodyText = response.body;
        if (bodyText.contains("expired") || bodyText.contains("EXPIRED")) {
          throw Exception(
            "Gemini API Key has expired. Please update it in Settings.",
          );
        }
        throw Exception(
          "Invalid Gemini API Key. Please verify your key in Settings.",
        );
      }

      if (response.statusCode == 429) {
        throw Exception(
          "Gemini API quota exceeded. Please try again later or use another API key.",
        );
      }

      if (response.statusCode == 503) {
        throw Exception(
          "Gemini AI is currently experiencing high demand. Please try again in a few minutes.",
        );
      }

      throw Exception(
        "Gemini API Error (${response.statusCode})\n\n${response.body}",
      );
    }

    if (response == null || response.statusCode != 200) {
      throw Exception(
        "Unable to connect to Gemini AI.",
      );
    }

    final Map<String, dynamic> responseJson = jsonDecode(response.body);

    final candidates = responseJson["candidates"];

    if (candidates == null || candidates.isEmpty) {
      throw Exception(
        "Gemini returned an empty response.",
      );
    }

    String rawJson = candidates[0]["content"]["parts"][0]["text"];

    rawJson = _cleanJson(rawJson);

    final List<dynamic> decoded = jsonDecode(rawJson);

    return decoded
        .map(
          (e) => QuizQuestion.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  static String _cleanJson(String text) {
    String cleaned = text.trim();

    if (cleaned.startsWith("```json")) {
      cleaned = cleaned.substring(7);
    }

    if (cleaned.startsWith("```")) {
      cleaned = cleaned.substring(3);
    }

    if (cleaned.endsWith("```")) {
      cleaned = cleaned.substring(
        0,
        cleaned.length - 3,
      );
    }

    return cleaned.trim();
  }

  static String _buildBatchPrompt({
    required String text,
    required int batchSize,
    required int startIndex,
  }) {
    return """
You are an expert UPSC Civil Services Examination (Prelims) paper setter.

Read the study material carefully.

Generate exactly $batchSize NEW UPSC-quality multiple-choice questions.
Do not repeat questions from previous batches.
Question numbering should start from $startIndex.

STRICT RULES

1. Use ONLY the supplied study material.
2. Do NOT invent facts.
3. Every question must have exactly FOUR options.
4. Exactly ONE option is correct.
5. Questions should match UPSC CSE Prelims level.
6. Include factual, conceptual and analytical questions.
7. Return ONLY valid JSON.
8. Do NOT return markdown.
9. Do NOT return any explanation outside JSON.
10. Every object MUST contain ALL fields.

Return JSON exactly like this:
[
  {
    "question":"Question text",

    "options":[
      "Option A",
      "Option B",
      "Option C",
      "Option D"
    ],

    "answer":"Correct Option Text",

    "explanation":"Brief explanation of why the answer is correct.",

    "subject":"Polity",

    "difficulty":"Medium"
  }
]

Allowed difficulty values:
Easy
Medium
Hard

Possible subjects:
Polity
History
Ancient History
Medieval History
Modern History
Geography
Economy
Environment
Science & Technology
Art & Culture
Current Affairs

IMPORTANT:
- Return ONLY valid JSON.
- Do NOT wrap the JSON inside ```json.
- Do NOT add any introductory or concluding text.
- Generate exactly $batchSize questions.
- Ensure every question has four options and exactly one correct answer.

Study Material:

$text
""";
  }
}
