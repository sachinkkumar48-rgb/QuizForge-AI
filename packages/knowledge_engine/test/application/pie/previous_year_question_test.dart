import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('PreviousYearQuestion Tests', () {
    test('initializes correctly with required and default parameters', () {
      final pyq = PreviousYearQuestion(
        id: 'pyq-cse-2023-q01',
        question:
            'Consider the following statements regarding the Preamble to the Constitution of India...',
        options: [
          '1 only',
          '2 only',
          'Both 1 and 2',
          'Neither 1 nor 2',
        ],
        answer: 'C',
        explanation:
            'The Preamble is an integral part of the Constitution as per Kesavananda Bharati case.',
        exam: 'UPSC CSE',
        year: 2023,
        paper: 'GS Paper I',
        subject: 'Polity',
        topics: ['Preamble', 'Constitutional Framework'],
        difficulty: 'Medium',
        tags: ['Polity', 'PYQ 2023'],
      );

      expect(pyq.id, equals('pyq-cse-2023-q01'));
      expect(pyq.question, contains('Preamble'));
      expect(pyq.options.length, equals(4));
      expect(pyq.answer, equals('C'));
      expect(pyq.explanation, contains('Kesavananda'));
      expect(pyq.exam, equals('UPSC CSE'));
      expect(pyq.year, equals(2023));
      expect(pyq.paper, equals('GS Paper I'));
      expect(pyq.subject, equals('Polity'));
      expect(pyq.topics, equals(['Preamble', 'Constitutional Framework']));
      expect(pyq.difficulty, equals('Medium'));
      expect(pyq.tags, equals(['Polity', 'PYQ 2023']));
    });

    test('guarantees immutability of list collections', () {
      final pyq = PreviousYearQuestion(
        id: 'pyq-cse-2022-q10',
        question: 'Which one of the following is not a RAMSAR site in India?',
        options: ['Site A', 'Site B'],
        topics: ['Environment'],
        tags: ['Ecology'],
      );

      expect(() => (pyq.options as List).add('Site C'), throwsUnsupportedError);
      expect(
          () => (pyq.topics as List).add('Wetlands'), throwsUnsupportedError);
      expect(
          () => (pyq.tags as List).add('Environment'), throwsUnsupportedError);
    });

    test('copyWith modifies specified fields while preserving others', () {
      final original = PreviousYearQuestion(
        id: 'pyq-001',
        question: 'Sample question prompt',
        exam: 'UPSC CSE',
        year: 2021,
      );

      final copy = original.copyWith(
        subject: 'Economy',
        difficulty: 'Hard',
      );

      expect(copy.id, equals('pyq-001'));
      expect(copy.exam, equals('UPSC CSE'));
      expect(copy.year, equals(2021));
      expect(copy.subject, equals('Economy'));
      expect(copy.difficulty, equals('Hard'));
    });

    test('toMap and fromMap achieve full round-trip serialization', () {
      final pyq = PreviousYearQuestion(
        id: 'pyq-cse-2023-q25',
        question: 'With reference to Indian economy, consider the following...',
        options: ['Option A', 'Option B', 'Option C', 'Option D'],
        answer: 'B',
        explanation: 'Detailed explanation text.',
        exam: 'UPSC CSE',
        year: 2023,
        paper: 'GS Paper I',
        subject: 'Economy',
        topics: ['Monetary Policy', 'RBI'],
        difficulty: 'Hard',
        tags: ['Economy', 'Monetary Policy'],
      );

      final map = pyq.toMap();
      final restored = PreviousYearQuestion.fromMap(map);

      expect(restored, equals(pyq));
      expect(restored.id, equals('pyq-cse-2023-q25'));
      expect(restored.year, equals(2023));
    });
  });
}
