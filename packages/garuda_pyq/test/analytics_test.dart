import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('PYQAnalyticsEngine Tests', () {
    late OfflinePYQRepository repo;
    late PYQAnalyticsEngine analyticsEngine;

    setUp(() async {
      repo = OfflinePYQRepository();
      analyticsEngine = PYQAnalyticsEngine(repo);

      final source = QuestionSource(
        sourceType: SourceType.editorialEntry,
        publisher: 'Test',
        retrievedDate: DateTime.now(),
        checksum: '111',
      );

      final q1 = Question(
        id: 'A1',
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        originalQuestion: 'Question on Rights 1',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        garudaExplanation: 'Exp 1',
        source: source,
        tags: const ['Rights', 'Polity'],
      );

      final q2 = Question(
        id: 'A2',
        examId: 'capf',
        year: 2023,
        stage: 'Written',
        paper: 'Paper 1',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        originalQuestion: 'Question on Rights 2',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['B']),
        garudaExplanation: 'Exp 2',
        source: source,
        tags: const ['Rights', 'Defense'],
      );

      await repo.saveQuestions([q1, q2]);
    });

    test('generateAnalytics summarizes frequency, trend, and cross exam mapping', () async {
      final summary = await analyticsEngine.generateAnalytics();

      expect(summary.topicFrequency['Fundamental Rights'], equals(2));
      expect(summary.examDistribution['upsc_cse'], equals(1));
      expect(summary.examDistribution['capf'], equals(1));
      expect(summary.yearTrend[2024], equals(1));
      expect(summary.conceptRecurrence['Rights'], equals(2));
      expect(summary.crossExamMapping['Fundamental Rights'], containsAll(['upsc_cse', 'capf']));
    });
  });
}
