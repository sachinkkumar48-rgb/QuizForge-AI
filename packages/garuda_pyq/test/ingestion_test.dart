import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('Ingestion Layer Tests', () {
    test('JSONIngestion imports and exports correctly', () {
      const jsonStr = '''[
        {
          "id": "J1",
          "examId": "rbi_grade_b",
          "year": 2023,
          "stage": "Phase I",
          "paper": "General Awareness",
          "subject": "Finance",
          "topic": "Monetary Policy",
          "originalQuestion": "What is Repo Rate?",
          "options": [
            {"key": "A", "text": "Lending rate to commercial banks", "isCorrect": true}
          ],
          "officialAnswer": {"correctOptionKeys": ["A"]},
          "garudaExplanation": "Rate at which RBI lends money.",
          "source": {
            "sourceType": "verifiedArchive",
            "publisher": "RBI Archive",
            "retrievedDate": "2024-01-01T00:00:00.000Z",
            "checksum": "rbi_001"
          }
        }
      ]''';

      final questions = JSONIngestion.parseQuestionsJson(jsonStr);
      expect(questions.length, equals(1));
      expect(questions.first.id, equals('J1'));
      expect(questions.first.subject, equals('Finance'));

      final exported = JSONIngestion.exportQuestionsJson(questions);
      expect(exported, contains('"id": "J1"'));
    });

    test('CSVIngestion parses CSV rows properly', () {
      final csvRows = [
        ['id', 'examId', 'year', 'stage', 'paper', 'subject', 'topic', 'questionText', 'optionA', 'optionB', 'optionC', 'optionD', 'correctKey', 'explanation'],
        ['C1', 'cds', '2023', 'Written', 'GS', 'Geography', 'Rivers', 'Which river originates in Western Ghats?', 'Ganga', 'Yamuna', 'Kaveri', 'Indus', 'C', 'Kaveri originates at Talakaveri.'],
      ];

      final questions = CSVIngestion.parseCsvRows(csvRows);
      expect(questions.length, equals(1));
      final q = questions.first;
      expect(q.id, equals('C1'));
      expect(q.options.length, equals(4));
      expect(q.officialAnswer.correctOptionKeys, contains('C'));
    });

    test('DuplicateDetector catches duplicate questions', () {
      final source = QuestionSource(
        sourceType: SourceType.editorialEntry,
        publisher: 'Test',
        retrievedDate: DateTime.now(),
        checksum: 'unique_chk',
      );

      final q1 = Question(
        id: 'DUP1',
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Preamble',
        originalQuestion: 'Is Preamble part of the Constitution?',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        garudaExplanation: 'Yes, Kesavananda Bharati case.',
        source: source,
      );

      final q2 = Question(
        id: 'DUP2',
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Preamble',
        originalQuestion: 'is preamble part of the constitution? ', // Normalized text match
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        garudaExplanation: 'Yes.',
        source: source,
      );

      final dups = DuplicateDetector.findDuplicates([q1], [q2]);
      expect(dups.length, equals(1));
      expect(dups.first.id, equals('DUP2'));
    });
  });
}
