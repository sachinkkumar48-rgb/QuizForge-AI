import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/quiz_model.dart';

class AiService {
  AiService._();

  static const String _model = "gemini-2.5-flash";

  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];

    if (key == null || key.isEmpty) {
      throw Exception(
        "GEMINI_API_KEY not found.\nPlease check your .env file.",
      );
    }

    return key;
  }

  static Uri get _url => Uri.parse(
    "https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey",
  );

  static Future<List<QuizQuestion>> generateQuiz(
      String text, {
        required int questionCount,
      }) async {
    final prompt = _buildPrompt(
      text: text,
      questionCount: questionCount,
    );

    final response = await http
        .post(
      _url,
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

    if (response.statusCode != 200) {
      throw Exception(
        "Gemini API Error (${response.statusCode})\n\n${response.body}",
      );
    }

    final Map<String, dynamic> responseJson =
    jsonDecode(response.body);

    final candidates = responseJson["candidates"];

    if (candidates == null || candidates.isEmpty) {
      throw Exception("Gemini returned an empty response.");
    }

    String rawJson =
    candidates[0]["content"]["parts"][0]["text"];

    rawJson = _cleanJson(rawJson);

    final List<dynamic> decoded = jsonDecode(rawJson);

    return decoded
        .map((e) => QuizQuestion.fromJson(e))
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

  static String _buildPrompt({
    required String text,
    required int questionCount,
  }) {
    return """
You are an expert UPSC Civil Services Examination (Prelims) paper setter.

Read the study material carefully.

Generate EXACTLY $questionCount high-quality UPSC Prelims MCQs.

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

Study Material:

$text
""";
  }
}