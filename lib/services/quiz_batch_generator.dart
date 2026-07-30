import '../core/network/api_client.dart' hide QuizQuestion;
import '../models/quiz_model.dart';

class QuizBatchGenerator {
  final ApiClient _apiClient;

  QuizBatchGenerator({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Divide requested question count into batches of max 20.
  static List<int> calculateBatchSizes(int totalCount) {
    if (totalCount <= 0) return [];
    final List<int> batches = [];
    int remaining = totalCount;
    while (remaining > 0) {
      final size = remaining > 20 ? 20 : remaining;
      batches.add(size);
      remaining -= size;
    }
    return batches;
  }

  /// Generates a single [QuizModel] by dividing [questionCount] into batches
  /// of max 20 questions, calling FastAPI ApiClient for each batch, retrying failed batches once,
  /// deduplicating questions while preserving order, and emitting progress.
  Future<QuizModel> generateInBatches(
    String text, {
    required int questionCount,
    void Function(String message)? onProgress,
  }) async {
    final batchSizes = calculateBatchSizes(questionCount);
    final totalBatches = batchSizes.length;
    final List<QuizQuestion> allQuestions = [];
    final Set<String> seenQuestionTexts = {};

    int currentIndex = 1;

    for (int i = 0; i < totalBatches; i++) {
      final batchSize = batchSizes[i];
      final batchNumber = i + 1;

      onProgress?.call(
          "Generating Questions...\nBatch $batchNumber of $totalBatches");

      List<QuizQuestion>? batchQuestions;
      Object? lastException;

      // Retry failed batches once (up to 2 total attempts)
      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          final request = QuizGenerateRequest(
            text: text,
            questions: batchSize,
            difficulty: 'medium',
            language: 'en',
          );

          final response = await _apiClient.generateQuiz(request);

          batchQuestions = response.quiz.map((apiQ) {
            String answerText;
            if (apiQ.answer >= 0 && apiQ.answer < apiQ.options.length) {
              answerText = apiQ.options[apiQ.answer];
            } else {
              answerText = apiQ.options.isNotEmpty ? apiQ.options.first : '';
            }

            return QuizQuestion(
              question: apiQ.question,
              options: apiQ.options,
              answer: answerText,
              explanation: apiQ.explanation,
              subject: 'General Studies',
              difficulty: 'Medium',
            );
          }).toList();

          lastException = null;
          break;
        } on BackendUnavailableException catch (e) {
          lastException = e;
          if (attempt < 2) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } on ApiException catch (e) {
          lastException = e;
          if (attempt < 2) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } on ParsingException catch (e) {
          lastException = e;
          if (attempt < 2) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          lastException = e;
          if (attempt < 2) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      if (batchQuestions == null) {
        if (lastException != null) {
          throw lastException;
        } else {
          throw Exception(
              "Batch $batchNumber of $totalBatches failed to generate.");
        }
      }

      for (final question in batchQuestions) {
        final normalized = _normalizeQuestionText(question.question);
        if (normalized.isNotEmpty && !seenQuestionTexts.contains(normalized)) {
          seenQuestionTexts.add(normalized);
          allQuestions.add(question);
        }
      }

      currentIndex += batchQuestions.length;
    }

    return QuizModel(questions: allQuestions);
  }

  static String _normalizeQuestionText(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
