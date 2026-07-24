import 'package:titan_quiz/titan_quiz.dart';
import '../exceptions/quiz_generation_exception.dart';
import '../models/quiz_generation_request.dart';

/// Service responsible for constructing structured AI prompts for quiz generation.
class QuizPromptBuilder {
  const QuizPromptBuilder();

  /// Constructs the system prompt instructing the LLM on its role, constraints, and JSON schema.
  String buildSystemPrompt() {
    return '''
You are an expert exam setter and educational assistant specializing in competitive exams (such as UPSC, BPSC, SSC, Banking, Railway, and Custom domain assessments).
Your task is to generate high-quality, accurate, multiple-choice quizzes based strictly on the provided text passage.

CRITICAL INSTRUCTIONS:
1. You MUST respond ONLY with a valid JSON object. Do not include markdown code blocks, explanation text, preamble, or postscript.
2. The JSON object must strictly conform to the following JSON schema:

{
  "title": "A concise, professional title for the quiz",
  "description": "A brief overview of the quiz content and focus",
  "questions": [
    {
      "question": "The complete, clear question text",
      "options": ["Option A text", "Option B text", "Option C text", "Option D text"],
      "correctAnswer": 0,
      "explanation": "Detailed explanation justifying the correct answer",
      "topic": "Specific topic or subject area",
      "difficulty": "easy | medium | hard | mixed"
    }
  ]
}

3. Each question must have AT LEAST 2 options (preferably 4 distinct options).
4. All options within a question must be unique and non-empty.
5. "correctAnswer" MUST be the 0-based integer index pointing to the single correct option in the "options" array (e.g. 0 for the 1st option, 1 for the 2nd).
6. Ensure questions test genuine comprehension, factual accuracy, and conceptual clarity.
''';
  }

  /// Constructs the user prompt containing the source text and request parameters.
  String buildUserPrompt({
    required String sourceText,
    required QuizGenerationRequest request,
  }) {
    if (sourceText.trim().isEmpty) {
      throw const PromptException(
          'Source text for quiz prompt cannot be empty.');
    }

    final targetQuestions = request.questionsPerChunk;
    final difficultyStr = _mapDifficulty(request.difficulty);
    final languageStr = _mapLanguage(request.language);
    final categoryStr = _mapCategory(request.category);

    return '''
Generate a multiple-choice quiz based on the following text chunk:

=== EXAM CONFIGURATION ===
Category/Exam: $categoryStr
Target Difficulty: $difficultyStr
Language Mode: $languageStr
Number of Questions: $targetQuestions

=== SOURCE TEXT PASSAGE ===
$sourceText
=== END SOURCE TEXT PASSAGE ===

Generate exactly $targetQuestions questions in $languageStr language at $difficultyStr difficulty level tailored for $categoryStr. Return ONLY valid JSON.
''';
  }

  String _mapDifficulty(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'Easy';
      case QuizDifficulty.medium:
        return 'Medium';
      case QuizDifficulty.hard:
        return 'Hard';
      case QuizDifficulty.mixed:
        return 'Mixed';
    }
  }

  String _mapLanguage(QuizLanguage language) {
    switch (language) {
      case QuizLanguage.english:
        return 'English';
      case QuizLanguage.hindi:
        return 'Hindi';
      case QuizLanguage.bilingual:
        return 'Bilingual (English & Hindi)';
    }
  }

  String _mapCategory(QuizCategory category) {
    switch (category) {
      case QuizCategory.upsc:
        return 'UPSC Civil Services Examination';
      case QuizCategory.bpsc:
        return 'BPSC State Public Service Commission';
      case QuizCategory.ssc:
        return 'SSC (Staff Selection Commission)';
      case QuizCategory.banking:
        return 'Banking Examinations (IBPS / SBI)';
      case QuizCategory.railway:
        return 'Railway Recruitment Board (RRB)';
      case QuizCategory.custom:
        return 'General / Custom Assessment';
    }
  }
}
