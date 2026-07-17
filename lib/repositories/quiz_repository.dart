import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/text_chunk_service.dart';
import '../models/quiz_model.dart';
import '../services/ai_service.dart';
import '../services/cache_service.dart';
import '../services/pdf_reader_service.dart';

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

    // Step 4 - Check cache
    final cachedQuiz = await CacheService.loadQuiz(cacheKey);

    if (cachedQuiz != null) {
      debugPrint("Quiz loaded from cache.");
      return cachedQuiz;
    }

    // Step 5 - Reduce prompt size
    const maxCharacters = 15000;

    final inputText = cleanedText.length > maxCharacters
        ? cleanedText.substring(0, maxCharacters)
        : cleanedText;

    // Step 6 - Generate quiz using Gemini
    final questions = await AiService.generateQuiz(
      inputText,
      questionCount: 10,
    );

    // Step 7 - Save to cache
    await CacheService.saveQuiz(
      cacheKey,
      questions,
    );

    debugPrint("Quiz saved to cache.");

    return questions;
  }
}
