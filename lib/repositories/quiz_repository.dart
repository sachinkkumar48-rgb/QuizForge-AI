import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/text_chunk_service.dart';
import '../models/quiz_model.dart';
import '../models/quiz_source.dart';
import '../services/ai_service.dart';
import '../services/cache_service.dart';
import '../services/pdf_reader_service.dart';
import 'quiz_source_repository.dart';

class QuizRepository {
  Future<List<QuizQuestion>> generateQuiz(
    PlatformFile pdf,
  ) async {
    // Step 1 - Read PDF
    final pdfText = await PdfReaderService.readPdf(pdf);

    if (pdfText.trim().isEmpty) {
      throw Exception(
        "No readable text found in the selected PDF.",
      );
    }

    // Step 2 - Clean extracted text
    final cleanedText = TextChunkService.cleanText(pdfText);

    // Step 3 - Create cache key
    final cacheKey = CacheService.generateKey(cleanedText);

    List<QuizQuestion> questions;

    // Step 4 - Check cache
    final cachedQuiz = await CacheService.loadQuiz(cacheKey);

    if (cachedQuiz != null) {
      debugPrint("Quiz loaded from cache.");
      questions = cachedQuiz;
    } else {
      // Step 5 - Reduce prompt size
      const maxCharacters = 15000;

      final inputText = cleanedText.length > maxCharacters
          ? cleanedText.substring(0, maxCharacters)
          : cleanedText;

      // Step 6 - Generate quiz using Gemini
      final generated = await AiService.generateQuiz(
        inputText,
        questionCount: 10,
      );

      // Step 7 - Save to cache
      await CacheService.saveQuiz(
        cacheKey,
        generated,
      );

      debugPrint("Quiz saved to cache.");
      questions = generated;
    }

    // Register / Update PDF in the library
    try {
      final repo = QuizSourceRepository();
      final sources = await repo.getSources();
      QuizSource? existing;
      for (final s in sources) {
        if (s.id == cacheKey) {
          existing = s;
          break;
        }
      }

      if (existing == null) {
        final newSource = QuizSource(
          id: cacheKey,
          name: pdf.name,
          localPath: pdf.path ?? "",
          importedAt: DateTime.now(),
          lastOpenedAt: DateTime.now(),
          questionCount: questions.length,
          attemptCount: 0,
          fileSize: pdf.size,
          favorite: false,
        );
        await repo.saveSource(newSource);
      } else {
        final updated = existing.copyWith(
          lastOpenedAt: DateTime.now(),
        );
        await repo.updateSource(updated);
      }
    } catch (e) {
      debugPrint("Error updating PDF Library metadata: $e");
    }

    return questions;
  }
}
