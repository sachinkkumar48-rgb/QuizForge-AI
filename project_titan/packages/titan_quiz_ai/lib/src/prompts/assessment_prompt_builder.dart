import 'package:titan_quiz/titan_quiz.dart';
import '../exceptions/quiz_generation_exception.dart';
import '../models/assessment_blueprint.dart';
import '../models/assessment_question_type.dart';
import '../models/assessment_source.dart';

/// Service responsible for constructing grounded, structured prompts for the smart assessment generation pipeline.
class AssessmentPromptBuilder {
  const AssessmentPromptBuilder();

  /// Constructs the system prompt enforcing strict source grounding, schema adherence, and zero hallucinations.
  String buildSystemPrompt(
      {required List<AssessmentQuestionType> allowedTypes}) {
    final typeListStr = allowedTypes.map((t) => t.typeCode).join(', ');

    return '''
You are TITAN's Senior Assessment Design Engine and Educational Psychometrician.
Your objective is to generate rigorous, high-quality, psychometrically sound assessment questions grounded STRICTLY and EXCLUSIVELY in the provided source document text passages.

CRITICAL PRINCIPLES & CONSTRAINTS:
1. STRICT SOURCE GROUNDING: Every question, option, and explanation MUST be directly verifiable from the provided source passages. DO NOT use external knowledge, unstated assumptions, or hallucinated facts.
2. SOURCE ATTRIBUTION: Every question MUST specify the exact "sourceChunkId" and "pageNumber" from the source snippet where the fact originates.
3. ALLOWED QUESTION TYPES: You may generate only the following question types: [$typeListStr].
   - "mcq": Standard 4-option single choice question ("correctAnswers": [0]).
   - "true_false": Binary question with exactly 2 options: ["True", "False"], ("correctAnswers": [0] or [1]).
   - "multiple_select": Question with 4 options where 1, 2, 3, or all 4 options can be correct ("correctAnswers": [0, 2]).
4. OUTPUT FORMAT: You MUST output ONLY a valid JSON object matching the schema below. Do not wrap in markdown quotes if possible, do not output explanations outside JSON.

JSON SCHEMA:
{
  "title": "Concise assessment title",
  "description": "Short description of the assessment scope",
  "questions": [
    {
      "question": "Clear, grammatically correct question text",
      "type": "mcq | true_false | multiple_select",
      "options": ["Option A text", "Option B text", "Option C text", "Option D text"],
      "correctAnswers": [0],
      "explanation": "Detailed explanation citing the facts from the source passage",
      "sourceChunkId": "Exact chunkId from the source header",
      "pageNumber": 1,
      "topic": "Topic name",
      "difficulty": "easy | medium | hard"
    }
  ]
}

5. OPTIONS & ANSWERS:
   - All options within a question must be distinct and non-empty.
   - "correctAnswers" must be a JSON array of 0-based integer indices corresponding to the correct option(s) in "options".
''';
  }

  /// Constructs the user prompt containing formatted source passages, blueprint constraints, and question count targets.
  String buildUserPrompt({
    required List<AssessmentSource> sources,
    required AssessmentBlueprint blueprint,
    int? targetQuestionsForBatch,
  }) {
    if (sources.isEmpty) {
      throw const PromptException(
          'Sources list for assessment prompt cannot be empty.');
    }

    final targetCount = targetQuestionsForBatch ?? blueprint.targetQuestions;
    final diffStr = _mapDifficulty(blueprint.difficulty);
    final langStr = _mapLanguage(blueprint.language);
    final catStr = _mapCategory(blueprint.category);

    final buffer = StringBuffer();
    buffer.writeln('=== ASSESSMENT BLUEPRINT CONFIGURATION ===');
    buffer.writeln('Exam / Category: $catStr');
    buffer.writeln('Difficulty Target: $diffStr');
    buffer.writeln('Language: $langStr');
    buffer.writeln('Target Questions to Generate: $targetCount');
    if (blueprint.topicHint != null && blueprint.topicHint!.isNotEmpty) {
      buffer.writeln('Topic Focus: ${blueprint.topicHint}');
    }
    buffer.writeln(
        'Explanation Required: ${blueprint.explanationRequired ? "YES" : "NO"}');
    buffer.writeln();

    buffer.writeln('=== SOURCE DOCUMENT PASSAGES ===');
    for (final src in sources) {
      buffer.writeln(
          '--- [CHUNK_ID: ${src.chunkId} | PAGE: ${src.pageNumber}] ---');
      if (src.sectionHeading != null) {
        buffer.writeln('Section: ${src.sectionHeading}');
      }
      buffer.writeln(src.text.trim());
      buffer.writeln('--- [END CHUNK: ${src.chunkId}] ---');
      buffer.writeln();
    }
    buffer.writeln('=== END OF SOURCE PASSAGES ===');
    buffer.writeln();

    buffer.writeln(
        'INSTRUCTION: Generate exactly $targetCount grounded questions in $langStr based ONLY on the passages above. Return valid JSON adhering strictly to the schema.');

    return buffer.toString();
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
        return 'Mixed (Balanced Easy, Medium, and Hard)';
    }
  }

  String _mapLanguage(QuizLanguage language) {
    switch (language) {
      case QuizLanguage.english:
        return 'English';
      case QuizLanguage.hindi:
        return 'Hindi (Devanagari script)';
      case QuizLanguage.bilingual:
        return 'Bilingual (Hindi and English blended context)';
    }
  }

  String _mapCategory(QuizCategory category) {
    switch (category) {
      case QuizCategory.upsc:
        return 'UPSC Civil Services Examination';
      case QuizCategory.bpsc:
        return 'State PSC / BPSC Examination';
      case QuizCategory.ssc:
        return 'Staff Selection Commission (SSC)';
      case QuizCategory.banking:
        return 'Banking & Financial Awareness';
      case QuizCategory.railway:
        return 'Railway Recruitment Board (RRB)';
      case QuizCategory.custom:
        return 'General Academic Assessment';
    }
  }
}
