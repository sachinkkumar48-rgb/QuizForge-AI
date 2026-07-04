import 'package:file_picker/file_picker.dart';

import '../core/utils/text_chunk_service.dart';
import '../models/quiz_model.dart';
import '../services/ai_service.dart';
import '../services/pdf_reader_service.dart';

class QuizRepository {
  Future<List<QuizQuestion>> generateQuiz(
      PlatformFile pdf,
      ) async {
    // Step 1: Extract text from PDF
    final pdfText = await PdfReaderService.readPdf(pdf);

    if (pdfText.trim().isEmpty) {
      throw Exception(
        "No readable text found in the selected PDF.",
      );
    }

    // Step 2: Clean the extracted text
    final cleanedText =
    TextChunkService.cleanText(pdfText);

    // Step 3: Limit text size for Sprint 1 MVP
    // This avoids multiple Gemini API calls and
    // prevents hitting the free-tier rate limits.
    const maxCharacters = 15000;

    final inputText =
    cleanedText.length > maxCharacters
        ? cleanedText.substring(0, maxCharacters)
        : cleanedText;

    // Step 4: Single Gemini API call
    return await AiService.generateQuiz(
      inputText,
      questionCount: 10,
    );
  }
}