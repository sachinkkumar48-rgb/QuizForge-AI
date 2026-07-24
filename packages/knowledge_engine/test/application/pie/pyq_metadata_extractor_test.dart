import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('PYQMetadataExtractor Tests', () {
    final extractor = PYQMetadataExtractor();

    test('detectSubject infers subject area when unassigned or General', () {
      final question = PreviousYearQuestion(
        id: 'pyq-201',
        question:
            'Consider the following statements regarding the Monetary Policy Committee of RBI...',
        subject: 'General',
      );

      final subject = extractor.detectSubject(question);
      expect(subject, equals('Economy'));
    });

    test('inferDifficulty assigns Hard to complex multi-statement questions',
        () {
      final hardQuestion = PreviousYearQuestion(
        id: 'pyq-202',
        question:
            'Which of the statements given above is/are correct? 1 only, 2 and 3...',
        options: ['1 only', '2 and 3', '1, 2 and 3', 'Neither 1 nor 2'],
        difficulty: 'Medium',
      );

      final difficulty = extractor.inferDifficulty(hardQuestion);
      expect(difficulty, equals('Hard'));
    });

    test('extractTags merges exam, year, paper, subject, and topics', () {
      final question = PreviousYearQuestion(
        id: 'pyq-203',
        question: 'Which river originates from Amarkantak plateau?',
        options: ['Narmada', 'Tapti', 'Mahanadi', 'Godavari'],
        exam: 'UPSC CSE',
        year: 2020,
        paper: 'GS Paper I',
        subject: 'Geography',
        topics: ['Rivers', 'Physical Geography'],
      );

      final tags = extractor.extractTags(question);

      expect(
          tags,
          containsAll([
            'UPSC CSE',
            '2020',
            'PYQ 2020',
            'GS Paper I',
            'Geography',
            'Easy'
          ]));
    });

    test('extractMetadata builds complete metadata dictionary', () {
      final question = PreviousYearQuestion(
        id: 'pyq-204',
        question: 'With reference to ISRO Gaganyaan mission...',
        options: ['Opt A', 'Opt B'],
        answer: 'Opt A',
        explanation: 'India human spaceflight programme.',
        exam: 'UPSC CSE',
        year: 2023,
        paper: 'GS Paper I',
        subject: 'Science & Technology',
        topics: ['Space'],
      );

      final metadata = extractor.extractMetadata(question);

      expect(metadata['itemId'], equals('pyq-204'));
      expect(metadata['exam'], equals('UPSC CSE'));
      expect(metadata['year'], equals(2023));
      expect(metadata['subject'], equals('Science & Technology'));
      expect(metadata['contentType'], equals('pyq'));
    });
  });
}
