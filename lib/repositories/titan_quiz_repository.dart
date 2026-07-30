import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart' hide QuizQuestion;
import '../core/utils/text_chunk_service.dart';
import '../models/quiz_model.dart';
import '../models/quiz_source.dart';
import '../services/cache_service.dart';
import '../services/knowledge_integration_service.dart';
import '../services/pdf_reader_service.dart';
import '../services/quiz_batch_generator.dart';
import '../services/quiz_generation_adapter.dart';
import 'quiz_source_repository.dart';

/// Repository contract for routing quiz generation through TITAN platform.
abstract class TitanQuizRepository {
  Future<QuizModel> generateQuiz(
    PlatformFile pdf, {
    int questionCount = 10,
    void Function(String message)? onProgress,
  });
}

/// Concrete implementation of [TitanQuizRepository] integrating Knowledge Engine,
/// PDF text ingestion, prompt adaptation, caching, batch generation via FastAPI ApiClient, and metadata management.
class TitanQuizRepositoryImpl implements TitanQuizRepository {
  final ApiClient _apiClient;
  final QuizBatchGenerator _batchGenerator;
  final KnowledgeIntegrationService _integrationService;
  final QuizGenerationAdapter _generationAdapter;
  final QuizSourceRepository _quizSourceRepository;

  TitanQuizRepositoryImpl({
    ApiClient? apiClient,
    QuizBatchGenerator? batchGenerator,
    KnowledgeIntegrationService? integrationService,
    QuizGenerationAdapter? generationAdapter,
    QuizSourceRepository? quizSourceRepository,
  })  : _apiClient = apiClient ?? ApiClient(),
        _batchGenerator = batchGenerator ?? QuizBatchGenerator(apiClient: apiClient),
        _integrationService =
            integrationService ?? KnowledgeIntegrationService(),
        _generationAdapter = generationAdapter ?? const QuizGenerationAdapter(),
        _quizSourceRepository = quizSourceRepository ?? QuizSourceRepository();

  ApiClient get apiClient => _apiClient;

  @override
  Future<QuizModel> generateQuiz(
    PlatformFile pdf, {
    int questionCount = 10,
    void Function(String message)? onProgress,
  }) async {
    // Step 1 - Read PDF
    onProgress?.call("Reading PDF content...");
    final pdfText = await PdfReaderService.readPdf(pdf);

    if (pdfText.trim().isEmpty) {
      throw Exception(
        "No readable text found in the selected PDF.",
      );
    }

    // Step 2 - Knowledge Intelligence Engine Ingestion
    onProgress?.call("Ingesting into Knowledge Intelligence Engine...");
    final pipelineResult = await _integrationService.ingestPdf(
      pdfText: pdfText,
      pdfTitle: pdf.name,
      pdfSourcePath: pdf.path ?? '',
    );

    // Step 3 - Adapt Knowledge Objects to normalized text
    onProgress?.call("Adapting Knowledge Engine objects...");
    final adaptedText = _generationAdapter.preparePromptText(pipelineResult);

    // Step 4 - Clean text payload for hashing & generation
    final sourceText = adaptedText.isNotEmpty ? adaptedText : pdfText;
    final cleanedText = TextChunkService.cleanText(sourceText);

    // Step 5 - Create cache key specific to content and question count
    final baseKey = CacheService.generateKey(cleanedText);
    final countCacheKey = "${baseKey}_$questionCount";

    List<QuizQuestion> questions;
    QuizModel quizModel;

    // Step 6 - Check cache
    onProgress?.call("Checking quiz cache...");
    final cachedQuestions = await CacheService.loadQuiz(countCacheKey);

    if (cachedQuestions != null && cachedQuestions.isNotEmpty) {
      debugPrint("Quiz loaded from cache for $questionCount questions.");
      onProgress?.call("Loaded cached quiz!");
      questions = cachedQuestions;
      quizModel = QuizModel(
        questions: questions,
        id: countCacheKey,
        sourceName: pdf.name,
      );
    } else {
      // Step 7 - Reduce prompt size
      const maxCharacters = 15000;

      final inputText = cleanedText.length > maxCharacters
          ? cleanedText.substring(0, maxCharacters)
          : cleanedText;

      // Step 8 - Generate quiz in batches using ApiClient
      try {
        quizModel = await _batchGenerator.generateInBatches(
          inputText,
          questionCount: questionCount,
          onProgress: onProgress,
        );
      } on BackendUnavailableException catch (e) {
        throw Exception("Backend service unavailable: ${e.message}");
      } on ApiException catch (e) {
        throw Exception("Backend API error (${e.statusCode}): ${e.message}");
      } on ParsingException catch (e) {
        throw Exception("Invalid response format from server: ${e.message}");
      }

      questions = quizModel.questions;

      // Step 9 - Save to cache
      await CacheService.saveQuiz(
        countCacheKey,
        questions,
      );

      debugPrint("Quiz saved to cache for $questionCount questions.");
    }

    // Register / Update PDF in the library
    try {
      final sources = await _quizSourceRepository.getSources();
      QuizSource? existing;
      for (final s in sources) {
        if (s.id == baseKey) {
          existing = s;
          break;
        }
      }

      if (existing == null) {
        final newSource = QuizSource(
          id: baseKey,
          name: pdf.name,
          localPath: pdf.path ?? "",
          importedAt: DateTime.now(),
          lastOpenedAt: DateTime.now(),
          questionCount: questions.length,
          attemptCount: 0,
          fileSize: pdf.size,
          favorite: false,
        );
        await _quizSourceRepository.saveSource(newSource);
      } else {
        final updated = existing.copyWith(
          lastOpenedAt: DateTime.now(),
          questionCount: questions.length,
        );
        await _quizSourceRepository.updateSource(updated);
      }
    } catch (e) {
      debugPrint("Error updating PDF Library metadata: $e");
    }

    return quizModel;
  }
}
