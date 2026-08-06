import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/dashboard/coverage/garuda_coverage_dashboard.dart';
import 'package:garuda_pyq/garuda_pyq.dart' hide CoverageReport;

void main() {
  group('CoverageFilter Unit Tests', () {
    late Question testQuestion;

    setUp(() {
      testQuestion = Question(
        id: 'Q_TEST',
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Parliament',
        difficulty: 'Hard',
        language: 'en',
        originalQuestion: 'Test question about Parliament',
        options: const [Option(key: 'A', text: 'Opt', isCorrect: true)],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        source: QuestionSource(
          sourceType: SourceType.officialWebsite,
          publisher: 'Official',
          retrievedDate: DateTime(2024),
          checksum: 'chk1',
        ),
        verificationStatus: 'Verified',
        editorialStatus: EditorialStatus.published,
        trap: const QuestionTrap(
          id: 't1',
          questionId: 'Q_TEST',
          trapType: 'Fact Swap',
          commonMistake: 'Trap',
          expectedThinking: '',
          wrongEliminationStrategy: '',
          correctEliminationStrategy: '',
        ),
        learningObjectives: const LearningObjectives(studentShouldBeAbleTo: ['Obj']),
        knowledgeObjectLinks: const ['KO1'],
        articleLinks: const ['Art 79'],
      );
    });

    test('Default filter matches all questions', () {
      const filter = CoverageFilter();
      expect(filter.isEmpty, isTrue);
      expect(filter.matches(testQuestion), isTrue);
    });

    test('Filter by exam matches correct examId case-insensitively', () {
      const filter = CoverageFilter(examId: 'UPSC_CSE');
      expect(filter.matches(testQuestion), isTrue);

      const mismatchFilter = CoverageFilter(examId: 'bpsc');
      expect(mismatchFilter.matches(testQuestion), isFalse);
    });

    test('Filter by year matches exact year', () {
      const filter = CoverageFilter(year: 2024);
      expect(filter.matches(testQuestion), isTrue);

      const mismatchFilter = CoverageFilter(year: 2020);
      expect(mismatchFilter.matches(testQuestion), isFalse);
    });

    test('Filter by subject matches normalized subject', () {
      const filter = CoverageFilter(subject: 'Polity');
      expect(filter.matches(testQuestion), isTrue);

      const mismatchFilter = CoverageFilter(subject: 'Economy');
      expect(mismatchFilter.matches(testQuestion), isFalse);
    });

    test('Filter by difficulty matches exact difficulty', () {
      const filter = CoverageFilter(difficulty: 'Hard');
      expect(filter.matches(testQuestion), isTrue);

      const mismatchFilter = CoverageFilter(difficulty: 'Easy');
      expect(mismatchFilter.matches(testQuestion), isFalse);
    });

    test('Filter by EditorialStatus matches exact status', () {
      const filter = CoverageFilter(editorialStatus: EditorialStatus.published);
      expect(filter.matches(testQuestion), isTrue);

      const mismatchFilter = CoverageFilter(editorialStatus: EditorialStatus.imported);
      expect(mismatchFilter.matches(testQuestion), isFalse);
    });

    test('Filter by QualityTier matches computed tier', () {
      expect(CoverageFilter.computeQualityTier(testQuestion), equals(QualityTier.gold));

      const filterGold = CoverageFilter(confidenceTier: QualityTier.gold);
      expect(filterGold.matches(testQuestion), isTrue);

      const filterDraft = CoverageFilter(confidenceTier: QualityTier.draft);
      expect(filterDraft.matches(testQuestion), isFalse);
    });

    test('copyWith allows modifying individual filter fields and clearing fields', () {
      const filter = CoverageFilter(examId: 'upsc_cse', year: 2024);
      final updated = filter.copyWith(subject: 'Polity', clearExam: true);

      expect(updated.examId, isNull);
      expect(updated.year, equals(2024));
      expect(updated.subject, equals('Polity'));
    });
  });
}
