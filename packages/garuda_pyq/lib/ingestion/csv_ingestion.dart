import '../models/answer_model.dart';
import '../models/editorial_status.dart';
import '../models/option_model.dart';
import '../models/question_model.dart';
import '../models/source_model.dart';

class CSVIngestion {
  /// Parses tabular CSV rows into Question objects.
  /// Expects columns: id, examId, year, stage, paper, subject, topic, questionText, optionA, optionB, optionC, optionD, correctKey, explanation
  static List<Question> parseCsvRows(List<List<String>> rows) {
    if (rows.isEmpty) return [];

    final questions = <Question>[];
    // Skip header row if present
    final startIndex = (rows.first.first.toLowerCase() == 'id') ? 1 : 0;

    for (var i = startIndex; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 13) continue;

      final id = row[0].trim();
      final examId = row[1].trim();
      final year = int.tryParse(row[2].trim()) ?? 2024;
      final stage = row[3].trim();
      final paper = row[4].trim();
      final subject = row[5].trim();
      final topic = row[6].trim();
      final questionText = row[7].trim();
      final optA = row[8].trim();
      final optB = row[9].trim();
      final optC = row[10].trim();
      final optD = row[11].trim();
      final correctKey = row[12].trim().toUpperCase();
      final explanation = row.length > 13 ? row[13].trim() : '';

      final options = [
        Option(key: 'A', text: optA, isCorrect: correctKey == 'A'),
        Option(key: 'B', text: optB, isCorrect: correctKey == 'B'),
        Option(key: 'C', text: optC, isCorrect: correctKey == 'C'),
        Option(key: 'D', text: optD, isCorrect: correctKey == 'D'),
      ];

      final source = QuestionSource(
        sourceType: SourceType.verifiedArchive,
        publisher: 'CSV Ingestion Pipeline',
        retrievedDate: DateTime.now(),
        checksum: 'csv_${id}_$year',
      );

      questions.add(Question(
        id: id,
        examId: examId,
        year: year,
        stage: stage,
        paper: paper,
        subject: subject,
        topic: topic,
        originalQuestion: questionText,
        options: options,
        officialAnswer: Answer(correctOptionKeys: [correctKey]),
        garudaExplanation: explanation,
        source: source,
        editorialStatus: EditorialStatus.imported,
      ));
    }

    return questions;
  }
}
