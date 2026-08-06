import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('OfflinePYQRepository Tests', () {
    late OfflinePYQRepository repo;

    setUp(() {
      repo = OfflinePYQRepository();
    });

    test('saveQuestion and getQuestionById', () async {
      final q = Question(
        id: 'Q1',
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'History',
        topic: 'Ancient India',
        originalQuestion: 'Where was Harappan seal discovered?',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        garudaExplanation: 'Discovered at Indus Valley sites.',
        source: QuestionSource(
          sourceType: SourceType.editorialEntry,
          publisher: 'Test',
          retrievedDate: DateTime.now(),
          checksum: '111',
        ),
      );

      await repo.saveQuestion(q);
      final retrieved = await repo.getQuestionById('Q1');
      expect(retrieved, isNotNull);
      expect(retrieved!.topic, equals('Ancient India'));
    });

    test('getQuestionsByExam filters correctly', () async {
      final q1 = Question(
        id: 'Q1',
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Economy',
        topic: 'Inflation',
        originalQuestion: 'What is CPI?',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['B']),
        garudaExplanation: 'Consumer Price Index',
        source: QuestionSource(
          sourceType: SourceType.editorialEntry,
          publisher: 'Test',
          retrievedDate: DateTime.now(),
          checksum: '222',
        ),
      );

      final q2 = Question(
        id: 'Q2',
        examId: 'bpsc',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'History',
        topic: 'Revolt of 1857',
        originalQuestion: 'Who led 1857 in Bihar?',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['C']),
        garudaExplanation: 'Kunwar Singh',
        source: QuestionSource(
          sourceType: SourceType.editorialEntry,
          publisher: 'Test',
          retrievedDate: DateTime.now(),
          checksum: '333',
        ),
      );

      await repo.saveQuestions([q1, q2]);

      final upscQuestions = await repo.getQuestionsByExam('upsc_cse');
      expect(upscQuestions.length, equals(1));
      expect(upscQuestions.first.id, equals('Q1'));

      final bpscQuestions = await repo.getQuestionsByExam('bpsc');
      expect(bpscQuestions.length, equals(1));
      expect(bpscQuestions.first.id, equals('Q2'));
    });
  });
}
