import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('PYQSearchEngine Tests', () {
    late OfflinePYQRepository repo;
    late PYQSearchEngine searchEngine;

    setUp(() async {
      repo = OfflinePYQRepository();
      searchEngine = PYQSearchEngine(repo);

      final source = QuestionSource(
        sourceType: SourceType.editorialEntry,
        publisher: 'Test',
        retrievedDate: DateTime.now(),
        checksum: '111',
      );

      final q1 = Question(
        id: 'S1',
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        originalQuestion: 'Which Article abolishes Untouchability?',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        garudaExplanation: 'Article 17 abolishes untouchability.',
        source: source,
        articleLinks: const ['Article 17'],
        tags: const ['Social Justice', 'Equality'],
      );

      final q2 = Question(
        id: 'S2',
        examId: 'uppsc',
        year: 2023,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Executive',
        originalQuestion: 'Who appoints the Governor of a State?',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['B']),
        garudaExplanation: 'President under Article 155.',
        source: source,
        articleLinks: const ['Article 155'],
        tags: const ['President', 'Governor'],
      );

      await repo.saveQuestions([q1, q2]);
    });

    test('Search by keyword', () async {
      final results = await searchEngine.search(
        const PYQSearchQuery(keyword: 'Untouchability'),
      );
      expect(results.length, equals(1));
      expect(results.first.id, equals('S1'));
    });

    test('Search by Article link', () async {
      final results = await searchEngine.searchByLegalReference(article: 'Article 155');
      expect(results.length, equals(1));
      expect(results.first.id, equals('S2'));
    });

    test('Search by exam and year filter', () async {
      final results = await searchEngine.search(
        const PYQSearchQuery(examId: 'upsc_cse', year: 2024),
      );
      expect(results.length, equals(1));
      expect(results.first.id, equals('S1'));
    });
  });
}
