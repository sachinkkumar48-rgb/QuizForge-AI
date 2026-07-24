import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('PYQParser Tests', () {
    final parser = PYQParser();

    test(
        'validate returns valid result for complete questions and invalid for empty required fields',
        () {
      final validQuestion = PreviousYearQuestion(
        id: 'pyq-100',
        question:
            'Which article of the Indian Constitution deals with Equality before law?',
        options: ['Article 14', 'Article 19', 'Article 21', 'Article 32'],
        answer: 'Article 14',
        explanation: 'Article 14 guarantees equality before law.',
        exam: 'UPSC CSE',
        year: 2022,
        paper: 'GS Paper I',
      );

      final result = parser.validate(validQuestion);
      expect(result.isValid, isTrue);

      final invalidQuestion = PreviousYearQuestion(
        id: '',
        question: '   ',
        options: [],
        answer: '',
      );

      final invalidResult = parser.validate(invalidQuestion);
      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.errors.length, greaterThanOrEqualTo(3));
    });

    test('normalize sanitizes whitespace and cleans options, topics, and tags',
        () {
      final rawQuestion = PreviousYearQuestion(
        id: 'pyq-101',
        question: '  What is   the capital   of India?  \r\n',
        options: ['  New Delhi ', 'Mumbai ', '  '],
        answer: ' New Delhi ',
        explanation: ' Explanation   with   spaces.\r\n\r\n',
        exam: ' UPSC CSE ',
        paper: ' GS Paper I ',
        subject: ' Geography ',
        topics: [' Capital ', ' Geography '],
        tags: [' Geography ', '  '],
      );

      final normalized = parser.normalize(rawQuestion);

      expect(normalized.question, equals('What is the capital of India?'));
      expect(normalized.options, equals(['New Delhi', 'Mumbai']));
      expect(normalized.answer, equals('New Delhi'));
      expect(normalized.explanation, equals('Explanation with spaces.'));
      expect(normalized.exam, equals('UPSC CSE'));
      expect(normalized.topics, containsAll(['Capital', 'Geography']));
    });

    test('parse deserializes and normalizes map payload', () {
      final mapData = {
        'id': 'pyq-102',
        'question': '  Sample   Question  ',
        'options': ['Opt A', 'Opt B'],
        'answer': 'Opt A',
        'exam': 'NDA',
        'year': 2021,
      };

      final parsed = parser.parse(mapData);

      expect(parsed.id, equals('pyq-102'));
      expect(parsed.question, equals('Sample Question'));
      expect(parsed.exam, equals('NDA'));
    });
  });
}
