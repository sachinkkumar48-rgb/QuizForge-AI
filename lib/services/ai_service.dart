import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/quiz_model.dart';

class AIService {
  // Replace with your Gemini API key
  static const String apiKey = "AQ.Ab8RN6JneHLESUzVbaOGFHGz0XNqkAdOJT8W0TkmnALQLOgSng";

  static Future<List<QuizQuestion>> generateQuiz(String pdfText) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );

    final prompt = """
You are an experienced UPSC Civil Services Examination paper setter.

Your task is to generate high-quality UPSC Prelims multiple-choice questions from the provided study material.

Instructions:

1. Generate exactly 10 questions.
2. Questions should test concepts, not factual memorization only.
3. Follow UPSC Prelims standard.
4. Each question must have exactly four options.
5. Mention the correct answer exactly as one of the four options.
6. Give a short explanation (2-3 sentences).
7. Identify the subject.
8. Difficulty must be one of: Easy, Medium or Hard.

Return ONLY valid JSON.

Example:

[
  {
    "question":"...",
    "options":["A","B","C","D"],
    "answer":"A",
    "explanation":"...",
    "subject":"Polity",
    "difficulty":"Medium"
  }
]

Study Material:

$pdfText
""";

    final response = await model.generateContent([
      Content.text(prompt),
    ]);

    String text = response.text ?? "";

    text = text.replaceAll("```json", "");
    text = text.replaceAll("```", "");
    text = text.trim();

    final List<dynamic> jsonData = jsonDecode(text);

    return jsonData
        .map((item) => QuizQuestion.fromJson(item))
        .toList();
  }
}