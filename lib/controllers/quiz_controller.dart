import '../models/quiz_model.dart';
import '../services/ai_service.dart';
import '../services/pdf_reader_service.dart';

class QuizController {

  Future<List<QuizQuestion>> generateQuiz(String pdfPath) async {

    final pdfText = await PdfReaderService.readPdf(pdfPath);

    final quiz =
    await AIService.generateQuiz(pdfText);

    return quiz;
  }

}