import 'package:titan_ai/titan_ai.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';

import '../exceptions/quiz_generation_exception.dart';
import '../models/generation_statistics.dart';
import '../models/quiz_generation_request.dart';
import '../models/quiz_generation_result.dart';
import '../parsers/quiz_json_parser.dart';
import '../prompts/quiz_prompt_builder.dart';
import '../validators/quiz_json_validator.dart';

/// Service orchestrating PDF text extraction, prompt building, LLM invocation, and Quiz parsing.
class AIQuizGenerationService {
  final PdfRepository _pdfRepository;
  final AIService _aiService;
  final QuizPromptBuilder _promptBuilder;
  final QuizJsonValidator _jsonValidator;
  final QuizJsonParser _jsonParser;

  const AIQuizGenerationService({
    required PdfRepository pdfRepository,
    required AIService aiService,
    QuizPromptBuilder promptBuilder = const QuizPromptBuilder(),
    QuizJsonValidator jsonValidator = const QuizJsonValidator(),
    QuizJsonParser jsonParser = const QuizJsonParser(),
  })  : _pdfRepository = pdfRepository,
        _aiService = aiService,
        _promptBuilder = promptBuilder,
        _jsonValidator = jsonValidator,
        _jsonParser = jsonParser;

  /// Generates a validated [Quiz] domain entity from a [QuizGenerationRequest].
  Future<QuizGenerationResult> generateQuiz(
      QuizGenerationRequest request) async {
    final stopwatch = Stopwatch()..start();
    final warnings = <String>[];

    // 1. Fetch PDF chunks for document
    final allChunks = await _pdfRepository.createChunks(request.documentId);
    if (allChunks.isEmpty) {
      throw JsonParsingException(
          'No PDF chunks available for document ID [${request.documentId}].');
    }

    final targetChunks = request.chunkIds.isEmpty
        ? allChunks
        : allChunks
            .where((PdfChunk c) => request.chunkIds.contains(c.chunkId))
            .toList();

    if (targetChunks.isEmpty) {
      throw JsonParsingException(
          'None of the requested chunkIds ${request.chunkIds} were found in document [${request.documentId}].');
    }

    final combinedSourceText =
        targetChunks.map((PdfChunk c) => c.text).join('\n\n');

    // 2. Construct System & User Prompts
    final systemPrompt = _promptBuilder.buildSystemPrompt();
    final userPrompt = _promptBuilder.buildUserPrompt(
      sourceText: combinedSourceText,
      request: request,
    );

    final aiRequest = AIRequest(
      prompt: userPrompt,
      systemPrompt: systemPrompt,
      temperature: 0.3,
    );

    // 3. Invoke AIService
    final aiResponse = await _aiService.generate<String>(aiRequest);
    final responseText = aiResponse.text;

    // 4. Extract and Validate JSON
    final jsonMap = _jsonParser.extractJsonMap(responseText);
    _jsonValidator.validateQuizJsonOrThrow(jsonMap);

    // 5. Parse JSON to Quiz entity
    final quiz = _jsonParser.parseQuiz(map: jsonMap, request: request);

    stopwatch.stop();

    final statistics = GenerationStatistics(
      chunksProcessed: targetChunks.length,
      questionsGenerated: quiz.questions.length,
      tokensUsed: aiResponse.usage.totalTokens,
      generationTime: stopwatch.elapsed,
    );

    return QuizGenerationResult(
      quiz: quiz,
      warnings: warnings,
      statistics: statistics,
      processingTime: stopwatch.elapsed,
    );
  }
}
