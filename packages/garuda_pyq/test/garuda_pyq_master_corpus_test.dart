import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('GARUDA UPSC Master Corpus (1995–2025)', () {
    test('Master Corpus contains 31 consecutive years (2025 down to 1995)', () {
      final questions = UPSCMasterCorpus19952025.getMasterCorpusQuestions();
      expect(questions.isNotEmpty, isTrue);

      final years = questions.map((q) => q.year).toSet();
      expect(years.length, equals(31));

      for (int y = 1995; y <= 2025; y++) {
        expect(years.contains(y), isTrue, reason: 'Year $y must be present in master corpus');
      }
    });

    test('Every question in master corpus has official metadata & verification evidence', () {
      final questions = UPSCMasterCorpus19952025.getMasterCorpusQuestions();
      for (final q in questions) {
        expect(q.id.isNotEmpty, isTrue);
        expect(q.examId, equals('upsc_cse'));
        expect(q.stage, equals('Prelims'));
        expect(q.paper, equals('GS Paper I'));
        expect(q.officialAnswer.correctOptionKeys.isNotEmpty, isTrue);
        expect(q.source.checksum.isNotEmpty, isTrue);
        expect(q.source.url?.isNotEmpty, isTrue);
      }
    });
  });

  group('GARUDA PYQ Master Offline Repository', () {
    late OfflinePYQRepository repo;

    setUp(() async {
      repo = OfflinePYQRepository();
      final questions = UPSCMasterCorpus19952025.getMasterCorpusQuestions();
      await repo.saveQuestions(questions);
    });

    test('Repository retrieves all 1995–2025 questions accurately', () async {
      final count = await repo.getQuestionCount();
      expect(count, greaterThanOrEqualTo(60));

      final q2025 = await repo.getQuestionById('PYQ_UPSC_CSE_2025_GS1_Q001');
      expect(q2025, isNotNull);
      expect(q2025!.year, equals(2025));

      final q1995 = await repo.getQuestionById('PYQ_UPSC_CSE_1995_GS1_Q001');
      expect(q1995, isNotNull);
      expect(q1995!.year, equals(1995));
    });
  });

  group('GARUDA PYQ Master Search Engine', () {
    late OfflinePYQRepository repo;
    late PYQSearchEngine searchEngine;

    setUp(() async {
      repo = OfflinePYQRepository();
      await repo.saveQuestions(UPSCMasterCorpus19952025.getMasterCorpusQuestions());
      searchEngine = PYQSearchEngine(repo);
    });

    test('Search by Year and Question Number', () async {
      final results = await searchEngine.search(const PYQSearchQuery(year: 2024, questionNumber: 1));
      expect(results.length, equals(1));
      expect(results.first.year, equals(2024));
    });

    test('Search by Article link', () async {
      final results = await searchEngine.searchByLegalReference(article: 'Article 14');
      expect(results.isNotEmpty, isTrue);
      expect(results.every((q) => q.articleLinks.contains('Article 14')), isTrue);
    });

    test('Search by Act link', () async {
      final results = await searchEngine.searchByLegalReference(actName: 'BNS 2023');
      expect(results.isNotEmpty, isTrue);
    });

    test('Autocomplete returns suggestions for query prefix', () async {
      final suggestions = await searchEngine.getAutocompleteSuggestions('Pol');
      expect(suggestions.isNotEmpty, isTrue);
    });
  });

  group('GARUDA PYQ Master Analytics Engine', () {
    late OfflinePYQRepository repo;
    late PYQAnalyticsEngine analyticsEngine;

    setUp(() async {
      repo = OfflinePYQRepository();
      await repo.saveQuestions(UPSCMasterCorpus19952025.getMasterCorpusQuestions());
      analyticsEngine = PYQAnalyticsEngine(repo);
    });

    test('Analytics summary contains complete 1995–2025 metrics', () async {
      final analytics = await analyticsEngine.generateAnalytics(examId: 'upsc_cse');

      expect(analytics.yearTrend.keys.length, equals(31));
      expect(analytics.subjectDistribution.isNotEmpty, isTrue);
      expect(analytics.articleFrequency.isNotEmpty, isTrue);
      expect(analytics.actFrequency.isNotEmpty, isTrue);
      expect(analytics.caseFrequency.isNotEmpty, isTrue);
      expect(analytics.repeatConceptAnalysis.isNotEmpty, isTrue);
    });
  });

  group('GARUDA PYQ Master Validation Engine', () {
    test('Master Corpus batch validation passes cleanly', () {
      final questions = UPSCMasterCorpus19952025.getMasterCorpusQuestions();
      final errors = PYQValidator.validateBatch(questions);

      expect(errors, isEmpty, reason: 'Master Corpus must be 100% clean of validation errors');
    });

    test('Detects duplicate question error', () {
      final q1 = UPSCMasterCorpus19952025.getMasterCorpusQuestions().first;
      final q1Dup = Question(
        id: 'PYQ_UPSC_CSE_2025_GS1_Q999',
        examId: q1.examId,
        year: q1.year,
        stage: q1.stage,
        paper: q1.paper,
        subject: q1.subject,
        topic: q1.topic,
        originalQuestion: q1.originalQuestion,
        options: q1.options,
        officialAnswer: q1.officialAnswer,
        source: q1.source,
        conceptsTested: q1.conceptsTested,
      );
      final errors = PYQValidator.validateQuestion(q1Dup, existingQuestions: [q1]);

      expect(errors.any((e) => e.code == ValidationErrorCode.duplicateQuestion), isTrue);
    });
  });
}
