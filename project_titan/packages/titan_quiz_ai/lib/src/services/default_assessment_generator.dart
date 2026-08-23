import 'package:titan_ai/titan_ai.dart';
import 'package:titan_quiz/titan_quiz.dart';
import '../exceptions/quiz_generation_exception.dart';
import '../models/assessment_generation_request.dart';
import '../models/assessment_generation_result.dart';
import '../models/generated_question.dart';
import '../models/generation_statistics.dart';
import '../parsers/assessment_json_parser.dart';
import '../prompts/assessment_prompt_builder.dart';
import '../validators/assessment_validator.dart';
import '../validators/question_deduplicator.dart';
import 'assessment_chunk_selector.dart';
import 'assessment_generator.dart';

/// Production implementation of [AssessmentGenerator] orchestrating batching, prompt construction,
/// LLM generation, parsing, deduplication, validation, and [Quiz] model adaptation.
class DefaultAssessmentGenerator implements AssessmentGenerator {
  final AIService _aiService;
  final AssessmentPromptBuilder _promptBuilder;
  final AssessmentJsonParser _jsonParser;
  final AssessmentValidator _validator;
  final QuestionDeduplicator _deduplicator;
  final AssessmentChunkSelector _chunkSelector;

  const DefaultAssessmentGenerator({
    required AIService aiService,
    AssessmentPromptBuilder promptBuilder = const AssessmentPromptBuilder(),
    AssessmentJsonParser jsonParser = const AssessmentJsonParser(),
    AssessmentValidator validator = const AssessmentValidator(),
    QuestionDeduplicator deduplicator = const QuestionDeduplicator(),
    AssessmentChunkSelector chunkSelector = const AssessmentChunkSelector(),
  })  : _aiService = aiService,
        _promptBuilder = promptBuilder,
        _jsonParser = jsonParser,
        _validator = validator,
        _deduplicator = deduplicator,
        _chunkSelector = chunkSelector;

  @override
  Future<AssessmentGenerationResult> generateAssessment(
    AssessmentGenerationRequest request,
  ) async {
    final stopwatch = Stopwatch()..start();
    final warnings = <String>[];

    // 1. Pre-flight check
    request.cancellationToken?.throwIfCancelled();

    if (request.sources.isEmpty) {
      throw const JsonParsingException(
          'Assessment generation request contains no source passages.');
    }

    // 2. Batch sources
    final batches = _chunkSelector.createBatches(
      sources: request.sources,
      blueprint: request.blueprint,
    );

    if (batches.isEmpty) {
      throw const JsonParsingException(
          'No valid batches could be created from the supplied sources.');
    }

    final allGeneratedQuestions = <GeneratedQuestion>[];
    var totalTokensUsed = 0;
    var rawTitle = request.blueprint.title;
    var rawDescription = request.blueprint.description;

    final targetTotal = request.blueprint.targetQuestions;
    final questionsPerBatch =
        (targetTotal / batches.length).ceil().clamp(1, 20);

    // 3. Process each batch
    for (var bIdx = 0; bIdx < batches.length; bIdx++) {
      request.cancellationToken?.throwIfCancelled();

      final batchSources = batches[bIdx];
      final systemPrompt = _promptBuilder.buildSystemPrompt(
        allowedTypes: request.blueprint.allowedQuestionTypes,
      );
      final userPrompt = _promptBuilder.buildUserPrompt(
        sources: batchSources,
        blueprint: request.blueprint,
        targetQuestionsForBatch: questionsPerBatch,
      );

      final aiRequest = AIRequest(
        prompt: userPrompt,
        systemPrompt: systemPrompt,
        temperature: 0.25,
      );

      final aiResponse = await _aiService.generate<String>(aiRequest);
      totalTokensUsed += aiResponse.usage.totalTokens;

      request.cancellationToken?.throwIfCancelled();

      // Extract & parse JSON
      final jsonMap = _jsonParser.extractJsonMap(aiResponse.text);

      rawTitle ??= jsonMap['title']?.toString();
      rawDescription ??= jsonMap['description']?.toString();

      final parsed = _jsonParser.parseQuestions(
        map: jsonMap,
        request: request,
      );

      allGeneratedQuestions.addAll(parsed);
    }

    // 4. Deduplicate questions across batches
    final deduplicated = _deduplicator.deduplicate(allGeneratedQuestions);

    if (deduplicated.length < allGeneratedQuestions.length) {
      warnings.add(
          'Deduplicated ${allGeneratedQuestions.length - deduplicated.length} similar/identical question candidates across batches.');
    }

    // 5. Enforce deterministic validation
    _validator.validateQuestionsOrThrow(
      questions: deduplicated,
      request: request,
    );

    // 6. Select final target count
    final finalQuestions = deduplicated.take(targetTotal).toList();

    // 7. Adapt to Quiz entity
    final quizQuestions =
        finalQuestions.map((q) => q.toQuizQuestion()).toList();
    final quizId = QuizUtils.generateQuizId();
    final quizTitle = rawTitle?.trim().isNotEmpty == true
        ? rawTitle!.trim()
        : 'Assessment - Document ${request.blueprint.documentId}';
    final quizDesc = rawDescription?.trim().isNotEmpty == true
        ? rawDescription!.trim()
        : 'Smart assessment generated from document ${request.blueprint.documentId}';

    final quiz = Quiz(
      id: quizId,
      title: quizTitle,
      description: quizDesc,
      sourceDocumentId: request.blueprint.documentId,
      difficulty: request.blueprint.difficulty,
      language: request.blueprint.language,
      category: request.blueprint.category,
      questions: quizQuestions,
      metadata: QuizMetadata(
        totalQuestions: quizQuestions.length,
        estimatedDurationMinutes: quizQuestions.length * 2,
        generatedBy: 'TITAN Smart Assessment Engine',
      ),
    );

    stopwatch.stop();

    final statistics = GenerationStatistics(
      chunksProcessed: request.sources.length,
      questionsGenerated: quiz.questions.length,
      tokensUsed: totalTokensUsed,
      generationTime: stopwatch.elapsed,
    );

    return AssessmentGenerationResult(
      quiz: quiz,
      generatedQuestions: finalQuestions,
      statistics: statistics,
      warnings: warnings,
      processingTime: stopwatch.elapsed,
    );
  }
}
