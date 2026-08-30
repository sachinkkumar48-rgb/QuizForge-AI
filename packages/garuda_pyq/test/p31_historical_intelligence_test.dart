import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

// ============================================================================
// P31 TEST FIXTURES
// ============================================================================

/// Creates a minimal NormalizedQuestion for testing.
NormalizedQuestion _q({
  required String examId,
  required int year,
  String paper = 'GS1',
  String subject = 'Polity',
  String topic = 'Constitution',
  String language = 'en',
  List<String> objectiveIds = const [],
  int questionNumber = 1,
  String text = 'Test question',
}) {
  final src = PyqSourceReference.official(
    examId: examId,
    year: year,
    paper: paper,
  );
  final id = DeterministicQuestionId.generate(
    examId: examId,
    year: year,
    paper: paper,
    normalizedQuestionText: '$text $examId $year $paper $topic $questionNumber',
    language: language,
    questionNumber: questionNumber,
  );
  return NormalizedQuestion(
    id: id,
    examId: examId,
    year: year,
    paper: paper,
    subject: subject,
    topic: topic,
    questionNumber: questionNumber,
    normalizedText: '$text $examId $year $paper $topic $questionNumber',
    originalText: '$text $examId $year $paper $topic $questionNumber',
    options: const [
      Option(key: 'A', text: 'Option A'),
      Option(key: 'B', text: 'Option B'),
      Option(key: 'C', text: 'Option C'),
      Option(key: 'D', text: 'Option D'),
    ],
    officialAnswer: const Answer(correctOptionKeys: ['A']),
    language: language,
    source: src,
    objectiveIds: objectiveIds,
  );
}

/// Builds a multi-exam, multi-year corpus for comprehensive testing.
List<NormalizedQuestion> _buildTestCorpus() {
  final questions = <NormalizedQuestion>[];
  int qNum = 0;

  // UPSC: 2021–2025, Polity (heavy), History, Economy
  for (int year = 2021; year <= 2025; year++) {
    // Polity: 5 questions per year (25 total)
    for (int i = 0; i < 5; i++) {
      qNum++;
      questions.add(_q(
        examId: 'upsc',
        year: year,
        subject: 'Polity',
        topic: i < 3 ? 'Fundamental Rights' : 'Parliament',
        objectiveIds: ['OBJ_POL_${i < 3 ? "FR" : "PARL"}'],
        questionNumber: qNum,
      ));
    }
    // History: 3 questions per year (15 total)
    for (int i = 0; i < 3; i++) {
      qNum++;
      questions.add(_q(
        examId: 'upsc',
        year: year,
        subject: 'History',
        topic: 'Modern India',
        objectiveIds: ['OBJ_HIST_MOD'],
        questionNumber: qNum,
      ));
    }
    // Economy: 2 questions per year (10 total)
    for (int i = 0; i < 2; i++) {
      qNum++;
      questions.add(_q(
        examId: 'upsc',
        year: year,
        subject: 'Economy',
        topic: i == 0 ? 'Fiscal Policy' : 'Banking',
        objectiveIds: i == 0 ? ['OBJ_ECON_FP'] : [],
        questionNumber: qNum,
      ));
    }
  }

  // BPSC: 2022–2024, lighter corpus
  for (int year = 2022; year <= 2024; year++) {
    for (int i = 0; i < 4; i++) {
      qNum++;
      questions.add(_q(
        examId: 'bpsc',
        year: year,
        subject: i < 2 ? 'Polity' : 'History',
        topic: i < 2 ? 'State Legislature' : 'Ancient India',
        objectiveIds: i < 2 ? ['OBJ_POL_SL'] : ['OBJ_HIST_ANC'],
        questionNumber: qNum,
      ));
    }
  }

  // SSC: single year, sparse
  qNum++;
  questions.add(_q(
    examId: 'ssc',
    year: 2024,
    subject: 'Polity',
    topic: 'Constitution',
    objectiveIds: ['OBJ_POL_CONST'],
    questionNumber: qNum,
  ));

  return questions;
}

// ============================================================================
// TESTS
// ============================================================================

void main() {
  const engine = PyqHistoricalIntelligenceEngine();

  // ==========================================================================
  // GROUP 1: SUBJECT WEIGHTAGE
  // ==========================================================================

  group('P31.1 Subject Weightage', () {
    test('1. Empty corpus returns zero total and empty entries', () {
      final result = engine.computeSubjectWeightage([]);
      expect(result.totalQuestions, 0);
      expect(result.entries, isEmpty);
    });

    test('2. Single question corpus returns 100% for that subject', () {
      final q = _q(examId: 'upsc', year: 2024, subject: 'Polity');
      final result = engine.computeSubjectWeightage([q]);
      expect(result.totalQuestions, 1);
      expect(result.entries.length, 1);
      expect(result.entries.first.category, 'Polity');
      expect(result.entries.first.percentage, 100.0);
      expect(result.entries.first.rank, 1);
    });

    test('3. Multiple subjects produce correct percentages and ranking', () {
      final corpus = _buildTestCorpus();
      final upscPool = corpus.where((q) => q.examId == 'upsc').toList();
      final result = engine.computeSubjectWeightage(upscPool);

      expect(result.totalQuestions, 50); // 25+15+10
      // Polity: 25/50 = 50%
      final polity = result.entries.firstWhere((e) => e.category == 'Polity');
      expect(polity.percentage, 50.0);
      expect(polity.rank, 1);
      // History: 15/50 = 30%
      final history = result.entries.firstWhere((e) => e.category == 'History');
      expect(history.percentage, 30.0);
      expect(history.rank, 2);
      // Economy: 10/50 = 20%
      final economy = result.entries.firstWhere((e) => e.category == 'Economy');
      expect(economy.percentage, 20.0);
      expect(economy.rank, 3);
    });

    test('4. Tied subjects share the same rank', () {
      final questions = [
        _q(examId: 'upsc', year: 2024, subject: 'Polity', questionNumber: 1),
        _q(examId: 'upsc', year: 2024, subject: 'History', questionNumber: 2),
      ];
      final result = engine.computeSubjectWeightage(questions);
      // Both have count=1, same rank
      expect(result.entries[0].rank, 1);
      expect(result.entries[1].rank, 1);
      // Alphabetical tie-breaker: History before Polity
      expect(result.entries[0].category, 'History');
      expect(result.entries[1].category, 'Polity');
    });
  });

  // ==========================================================================
  // GROUP 2: TOPIC WEIGHTAGE
  // ==========================================================================

  group('P31.2 Topic Weightage', () {
    test('5. Empty filtered result returns zero', () {
      final result = engine.computeTopicWeightage(
        _buildTestCorpus(),
        examId: 'nonexistent',
      );
      expect(result.totalQuestions, 0);
      expect(result.entries, isEmpty);
    });

    test('6. Filtered by exam, year range, subject produces correct stats', () {
      final corpus = _buildTestCorpus();
      final result = engine.computeTopicWeightage(
        corpus,
        examId: 'upsc',
        startYear: 2023,
        endYear: 2025,
        subject: 'Polity',
      );
      // 3 years * 5 polity Qs = 15 total
      expect(result.totalQuestions, 15);
      expect(result.examFilter, 'upsc');
      expect(result.startYearFilter, 2023);
      expect(result.endYearFilter, 2025);
      expect(result.subjectFilter, 'Polity');

      // Fundamental Rights: 3*3=9, Parliament: 3*2=6
      final fr =
          result.entries.firstWhere((e) => e.category == 'Fundamental Rights');
      expect(fr.count, 9);
      expect(fr.rank, 1);

      final parl = result.entries.firstWhere((e) => e.category == 'Parliament');
      expect(parl.count, 6);
      expect(parl.rank, 2);
    });

    test('7. Filtered by paper produces correct topic distribution', () {
      final corpus = _buildTestCorpus();
      final result = engine.computeTopicWeightage(
        corpus,
        examId: 'upsc',
        paper: 'GS1',
      );
      expect(result.totalQuestions, 50);
      expect(result.paperFilter, 'GS1');
    });
  });

  // ==========================================================================
  // GROUP 3: OBJECTIVE COVERAGE
  // ==========================================================================

  group('P31.3 Objective Coverage', () {
    test('8. Empty corpus returns zero coverage with all uncovered', () {
      final result = engine.computeObjectiveCoverage(
        [],
        frameworkObjectiveIds: ['OBJ_A', 'OBJ_B'],
      );
      expect(result.totalQuestions, 0);
      expect(result.mappedQuestions, 0);
      expect(result.mappingCoveragePercentage, 0.0);
      expect(result.uncoveredObjectiveIds, ['OBJ_A', 'OBJ_B']);
    });

    test('9. Correct coverage with framework objectives', () {
      final corpus = _buildTestCorpus();
      final upsc = corpus.where((q) => q.examId == 'upsc').toList();
      final framework = [
        'OBJ_POL_FR',
        'OBJ_POL_PARL',
        'OBJ_HIST_MOD',
        'OBJ_ECON_FP',
        'OBJ_MISSING_1',
        'OBJ_MISSING_2',
      ];
      final result = engine.computeObjectiveCoverage(
        upsc,
        frameworkObjectiveIds: framework,
      );
      expect(result.totalQuestions, 50);
      // 40 mapped (25 polity + 15 history), 10 economy (5 with, 5 without)
      expect(result.mappedQuestions, 45); // 25+15+5
      // 4 of 6 framework objectives covered
      expect(result.mappingCoveragePercentage, closeTo(66.67, 0.01));
      expect(result.uncoveredObjectiveIds, ['OBJ_MISSING_1', 'OBJ_MISSING_2']);
    });

    test('10. Missing mappings are correctly identified', () {
      final questions = [
        _q(
          examId: 'upsc',
          year: 2024,
          subject: 'Polity',
          topic: 'Constitution',
          objectiveIds: [],
          questionNumber: 1,
        ),
      ];
      final result = engine.computeObjectiveCoverage(questions);
      expect(result.mappedQuestions, 0);
      expect(result.coveredObjectives, isEmpty);
    });

    test('11. Years and subjects represented are accurate', () {
      final corpus = _buildTestCorpus();
      final upsc = corpus.where((q) => q.examId == 'upsc').toList();
      final result = engine.computeObjectiveCoverage(upsc);

      final frObj = result.coveredObjectives
          .firstWhere((e) => e.objectiveId == 'OBJ_POL_FR');
      expect(frObj.yearsRepresented, [2021, 2022, 2023, 2024, 2025]);
      expect(frObj.subjectsRepresented, ['Polity']);
    });
  });

  // ==========================================================================
  // GROUP 4: YEAR DISTRIBUTION
  // ==========================================================================

  group('P31.4 Year Distribution', () {
    test('12. Year distribution with subject/topic breakdowns', () {
      final corpus = _buildTestCorpus();
      final upsc = corpus.where((q) => q.examId == 'upsc').toList();
      final result = engine.computeYearDistribution(upsc);

      expect(result.totalQuestions, 50);
      expect(result.entries.length, 5); // 2021-2025

      final y2024 = result.entries.firstWhere((e) => e.year == 2024);
      expect(y2024.questionCount, 10);
      expect(y2024.subjectDistribution['Polity'], 5);
      expect(y2024.subjectDistribution['History'], 3);
      expect(y2024.subjectDistribution['Economy'], 2);
    });

    test('13. Year range filtering works correctly', () {
      final corpus = _buildTestCorpus();
      final result = engine.computeYearDistribution(
        corpus,
        startYear: 2023,
        endYear: 2024,
      );
      // 2023: 10 upsc + 4 bpsc = 14
      // 2024: 10 upsc + 4 bpsc + 1 ssc = 15
      expect(result.totalQuestions, 29);
      expect(result.entries.map((e) => e.year).toList(), [2023, 2024]);
    });

    test('14. Invalid years (<=0) are filtered out', () {
      final questions = [
        _q(examId: 'upsc', year: 0, questionNumber: 1),
        _q(examId: 'upsc', year: -1, questionNumber: 2),
        _q(examId: 'upsc', year: 2024, questionNumber: 3),
      ];
      final result = engine.computeYearDistribution(questions);
      expect(result.totalQuestions, 1);
      expect(result.entries.length, 1);
      expect(result.entries.first.year, 2024);
    });
  });

  // ==========================================================================
  // GROUP 5: YEAR-OVER-YEAR TRENDS
  // ==========================================================================

  group('P31.5 Year-Over-Year Trends', () {
    test('15. Increasing trend produces positive absolute changes', () {
      final questions = [
        _q(examId: 'upsc', year: 2021, topic: 'TopicX', questionNumber: 1),
        _q(examId: 'upsc', year: 2022, topic: 'TopicX', questionNumber: 2),
        _q(examId: 'upsc', year: 2022, topic: 'TopicX', questionNumber: 3),
        _q(examId: 'upsc', year: 2023, topic: 'TopicX', questionNumber: 4),
        _q(examId: 'upsc', year: 2023, topic: 'TopicX', questionNumber: 5),
        _q(examId: 'upsc', year: 2023, topic: 'TopicX', questionNumber: 6),
      ];
      final trends = engine.computeTopicTrends(questions);
      expect(trends.length, 1);
      final tx = trends.first;
      expect(tx.category, 'TopicX');
      expect(tx.yearCounts[2021], 1);
      expect(tx.yearCounts[2022], 2);
      expect(tx.yearCounts[2023], 3);
      expect(tx.absoluteChanges[2021], 0);
      expect(tx.absoluteChanges[2022], 1);
      expect(tx.absoluteChanges[2023], 1);
      expect(tx.percentageChanges[2022], 100.0);
      expect(tx.percentageChanges[2023], 50.0);
      expect(tx.multiYearFrequency, 3);
    });

    test('16. Decreasing trend produces negative absolute changes', () {
      final questions = [
        _q(examId: 'upsc', year: 2021, topic: 'TopicY', questionNumber: 1),
        _q(examId: 'upsc', year: 2021, topic: 'TopicY', questionNumber: 2),
        _q(examId: 'upsc', year: 2021, topic: 'TopicY', questionNumber: 3),
        _q(examId: 'upsc', year: 2022, topic: 'TopicY', questionNumber: 4),
      ];
      final trends = engine.computeTopicTrends(questions);
      expect(trends.first.absoluteChanges[2022], -2);
      expect(
        trends.first.percentageChanges[2022],
        closeTo(-66.67, 0.01),
      );
    });

    test('17. Flat trend produces zero changes', () {
      final questions = [
        _q(examId: 'upsc', year: 2021, topic: 'Flat', questionNumber: 1),
        _q(examId: 'upsc', year: 2022, topic: 'Flat', questionNumber: 2),
        _q(examId: 'upsc', year: 2023, topic: 'Flat', questionNumber: 3),
      ];
      final trends = engine.computeTopicTrends(questions);
      expect(trends.first.absoluteChanges[2022], 0);
      expect(trends.first.absoluteChanges[2023], 0);
    });

    test('18. Intermittent years handled correctly', () {
      final questions = [
        _q(examId: 'upsc', year: 2020, topic: 'IntTopic', questionNumber: 1),
        _q(examId: 'upsc', year: 2023, topic: 'IntTopic', questionNumber: 2),
      ];
      final trends = engine.computeTopicTrends(questions);
      expect(trends.first.multiYearFrequency, 2);
      // Change from 2020 to 2023 (years in between are missing)
      expect(trends.first.absoluteChanges[2023], 0);
    });

    test('19. Objective trends computed across questions', () {
      final corpus = _buildTestCorpus();
      final upsc = corpus.where((q) => q.examId == 'upsc').toList();
      final objTrends = engine.computeObjectiveTrends(upsc);
      expect(objTrends, isNotEmpty);

      final frTrend = objTrends.firstWhere((t) => t.category == 'OBJ_POL_FR');
      expect(frTrend.totalCount, 15); // 3 per year * 5 years
      expect(frTrend.multiYearFrequency, 5);
    });
  });

  // ==========================================================================
  // GROUP 6: RECENCY ANALYSIS
  // ==========================================================================

  group('P31.6 Recency Analysis', () {
    test('20. Recent window correctly separates recent and historical', () {
      final corpus = _buildTestCorpus();
      final upsc = corpus.where((q) => q.examId == 'upsc').toList();

      final recency = engine.computeTopicRecency(
        upsc,
        windowStartYear: 2024,
        windowEndYear: 2025,
      );

      final fr = recency.firstWhere((r) => r.category == 'Fundamental Rights');
      // 2024-2025: 3*2=6 recent, 2021-2023: 3*3=9 historical
      expect(fr.recentCount, 6);
      expect(fr.historicalCount, 9);
      expect(fr.recentShare, closeTo(0.4, 0.01));
    });

    test('21. Custom window with all questions as historical', () {
      final corpus = _buildTestCorpus();
      final recency = engine.computeTopicRecency(
        corpus,
        windowStartYear: 2030,
        windowEndYear: 2035,
      );
      for (final r in recency) {
        expect(r.recentCount, 0);
        expect(r.recentShare, 0.0);
      }
    });

    test('22. Zero-window: start > end produces all historical', () {
      final corpus = _buildTestCorpus();
      final recency = engine.computeTopicRecency(
        corpus,
        windowStartYear: 2025,
        windowEndYear: 2020,
      );
      for (final r in recency) {
        expect(r.recentCount, 0);
      }
    });

    test('23. Objective recency within explicit window', () {
      final corpus = _buildTestCorpus();
      final upsc = corpus.where((q) => q.examId == 'upsc').toList();
      final recency = engine.computeObjectiveRecency(
        upsc,
        windowStartYear: 2024,
        windowEndYear: 2025,
      );
      expect(recency, isNotEmpty);
      final fr = recency.firstWhere((r) => r.category == 'OBJ_POL_FR');
      expect(fr.recentCount, 6); // 3 per year * 2 years
    });
  });

  // ==========================================================================
  // GROUP 7: RECURRENCE ANALYSIS
  // ==========================================================================

  group('P31.7 Recurrence Analysis', () {
    test('24. Multi-year topic has correct recurrence profile', () {
      final corpus = _buildTestCorpus();
      final upsc = corpus.where((q) => q.examId == 'upsc').toList();
      final recurrence = engine.computeTopicRecurrence(upsc);

      final fr = recurrence.firstWhere((r) => r.id == 'Fundamental Rights');
      expect(fr.yearCount, 5);
      expect(fr.yearsPresent, [2021, 2022, 2023, 2024, 2025]);
      expect(fr.questionCount, 15);
      expect(fr.firstYear, 2021);
      expect(fr.lastYear, 2025);
    });

    test('25. Single-year topic has yearCount 1', () {
      final questions = [
        _q(examId: 'upsc', year: 2024, topic: 'OneTimer', questionNumber: 1),
      ];
      final recurrence = engine.computeTopicRecurrence(questions);
      expect(recurrence.first.yearCount, 1);
    });

    test('26. Objective recurrence across multiple years', () {
      final corpus = _buildTestCorpus();
      final upsc = corpus.where((q) => q.examId == 'upsc').toList();
      final recurrence = engine.computeObjectiveRecurrence(upsc);

      final histMod = recurrence.firstWhere((r) => r.id == 'OBJ_HIST_MOD');
      expect(histMod.yearCount, 5);
      expect(histMod.questionCount, 15);
    });

    test(
        '27. Deterministic ordering: yearCount DESC, questionCount DESC, '
        'id ASC', () {
      final recurrence = engine.computeTopicRecurrence(_buildTestCorpus());
      for (int i = 1; i < recurrence.length; i++) {
        final prev = recurrence[i - 1];
        final curr = recurrence[i];
        final yearCmp = prev.yearCount.compareTo(curr.yearCount);
        if (yearCmp == 0) {
          final qCmp = prev.questionCount.compareTo(curr.questionCount);
          if (qCmp == 0) {
            expect(prev.id.compareTo(curr.id) <= 0, isTrue);
          } else {
            expect(qCmp >= 0, isTrue);
          }
        } else {
          expect(yearCmp >= 0, isTrue);
        }
      }
    });
  });

  // ==========================================================================
  // GROUP 8: CROSS-EXAM COMPARISON
  // ==========================================================================

  group('P31.8 Cross-Exam Comparison', () {
    test('28. UPSC vs BPSC comparison produces correct side-by-side', () {
      final corpus = _buildTestCorpus();
      final comparison = engine.compareExams(
        corpus,
        examIdA: 'upsc',
        examIdB: 'bpsc',
      );

      expect(comparison.examIdA, 'upsc');
      expect(comparison.examIdB, 'bpsc');
      expect(comparison.entryA.corpusSize, 50);
      expect(comparison.entryB.corpusSize, 12);
      expect(comparison.entryA.yearCoverage, 5);
      expect(comparison.entryB.yearCoverage, 3);
      expect(comparison.entryA.minYear, 2021);
      expect(comparison.entryB.minYear, 2022);
    });

    test('29. Sparse exam vs empty exam', () {
      final corpus = _buildTestCorpus();
      final comparison = engine.compareExams(
        corpus,
        examIdA: 'ssc',
        examIdB: 'railways',
      );

      expect(comparison.entryA.corpusSize, 1);
      expect(comparison.entryB.corpusSize, 0);
      expect(comparison.entryB.yearCoverage, 0);
      expect(comparison.entryB.subjectDistribution, isEmpty);
    });

    test('30. Same exam compared produces identical entries', () {
      final corpus = _buildTestCorpus();
      final comparison = engine.compareExams(
        corpus,
        examIdA: 'upsc',
        examIdB: 'upsc',
      );
      expect(comparison.entryA.corpusSize, comparison.entryB.corpusSize);
      expect(comparison.entryA.yearCoverage, comparison.entryB.yearCoverage);
    });
  });

  // ==========================================================================
  // GROUP 9: CORPUS QUALITY
  // ==========================================================================

  group('P31.9 Corpus Quality', () {
    test('31. Empty corpus quality returns all zeros', () {
      final result = engine.computeQualityProfile([]);
      expect(result.totalQuestions, 0);
      expect(result.subjectCompleteness, 0.0);
      expect(result.objectiveMappingCoverage, 0.0);
      expect(result.provenanceCoverage, 0.0);
      expect(result.duplicateRatio, 0.0);
    });

    test('32. Complete metadata yields high quality scores', () {
      final corpus = _buildTestCorpus();
      final upsc = corpus.where((q) => q.examId == 'upsc').toList();
      final result = engine.computeQualityProfile(upsc);

      expect(result.totalQuestions, 50);
      expect(result.subjectCompleteness, 1.0); // All have named subjects
      expect(result.topicCompleteness, 1.0);
      expect(result.yearCoverage, 1.0);
      expect(result.provenanceCoverage, 1.0);
    });

    test('33. Partial metadata yields appropriate coverage', () {
      final questions = [
        _q(
          examId: 'upsc',
          year: 2024,
          subject: 'General Studies', // default -> not counted
          topic: 'General', // default -> not counted for topicMapping
          objectiveIds: [],
          questionNumber: 1,
        ),
        _q(
          examId: 'upsc',
          year: 2024,
          subject: 'Polity',
          topic: 'Constitution',
          objectiveIds: ['OBJ_1'],
          questionNumber: 2,
        ),
      ];
      final result = engine.computeQualityProfile(questions);
      expect(result.subjectCompleteness, 0.5);
      expect(result.topicMappingCoverage, 0.5);
      expect(result.objectiveMappingCoverage, 0.5);
    });

    test('34. Duplicate ratio computed correctly', () {
      final corpus = _buildTestCorpus();
      final result = engine.computeQualityProfile(
        corpus,
        knownDuplicateCount: 10,
      );
      // 63 unique + 10 dups = 73 total
      expect(result.duplicateRatio, closeTo(10 / 73, 0.001));
    });
  });

  // ==========================================================================
  // GROUP 10: SAFETY — NO NaN, NO INFINITY, ZERO DIVISION
  // ==========================================================================

  group('P31.10 Safety', () {
    test('35. Zero corpus: no NaN or Infinity in any output', () {
      final sw = engine.computeSubjectWeightage([]);
      expect(sw.totalQuestions, 0);

      final tw = engine.computeTopicWeightage([]);
      expect(tw.totalQuestions, 0);

      final oc = engine.computeObjectiveCoverage([]);
      expect(oc.mappingCoveragePercentage, 0.0);

      final yd = engine.computeYearDistribution([]);
      expect(yd.totalQuestions, 0);

      final tt = engine.computeTopicTrends([]);
      expect(tt, isEmpty);

      final tr = engine.computeTopicRecency(
        [],
        windowStartYear: 2020,
        windowEndYear: 2025,
      );
      expect(tr, isEmpty);

      final rec = engine.computeTopicRecurrence([]);
      expect(rec, isEmpty);

      final cmp = engine.compareExams(
        [],
        examIdA: 'a',
        examIdB: 'b',
      );
      expect(cmp.entryA.corpusSize, 0);
      expect(cmp.entryB.corpusSize, 0);

      final qp = engine.computeQualityProfile([]);
      expect(qp.duplicateRatio, 0.0);
    });

    test('36. Single question: all outputs valid, no division errors', () {
      final q = _q(examId: 'upsc', year: 2024);
      final sw = engine.computeSubjectWeightage([q]);
      expect(sw.entries.first.percentage, 100.0);

      final tw = engine.computeTopicWeightage([q]);
      expect(tw.entries.first.percentage, 100.0);

      final yd = engine.computeYearDistribution([q]);
      expect(yd.entries.first.questionCount, 1);
    });

    test('37. Two questions: subject percentages sum to 100', () {
      final questions = [
        _q(examId: 'upsc', year: 2024, subject: 'A', questionNumber: 1),
        _q(examId: 'upsc', year: 2024, subject: 'B', questionNumber: 2),
      ];
      final sw = engine.computeSubjectWeightage(questions);
      final sum = sw.entries.fold(0.0, (s, e) => s + e.percentage);
      expect(sum, closeTo(100.0, 0.001));
    });
  });

  // ==========================================================================
  // GROUP 11: DETERMINISM
  // ==========================================================================

  group('P31.11 Determinism', () {
    test('38. Identical inputs produce identical JSON outputs', () {
      final corpus = _buildTestCorpus();

      final run1 = engine.buildExamProfile(
        corpus,
        examId: 'upsc',
        frameworkObjectiveIds: ['OBJ_POL_FR', 'OBJ_HIST_MOD', 'OBJ_MISSING'],
      );
      final run2 = engine.buildExamProfile(
        corpus,
        examId: 'upsc',
        frameworkObjectiveIds: ['OBJ_POL_FR', 'OBJ_HIST_MOD', 'OBJ_MISSING'],
      );

      final json1 = run1.toJson().toString();
      final json2 = run2.toJson().toString();
      expect(json1, json2);
    });

    test('39. Five consecutive runs produce identical subject weightage', () {
      final corpus = _buildTestCorpus();
      final results = <String>[];
      for (int i = 0; i < 5; i++) {
        final sw = engine.computeSubjectWeightage(corpus);
        results.add(sw.toJson().toString());
      }
      for (int i = 1; i < results.length; i++) {
        expect(results[i], results[0]);
      }
    });

    test('40. Five consecutive runs produce identical trend analysis', () {
      final corpus = _buildTestCorpus();
      final results = <String>[];
      for (int i = 0; i < 5; i++) {
        final trends = engine.computeTopicTrends(corpus);
        results.add(trends.map((t) => t.toJson().toString()).join('|'));
      }
      for (int i = 1; i < results.length; i++) {
        expect(results[i], results[0]);
      }
    });
  });

  // ==========================================================================
  // GROUP 12: EXAM INTELLIGENCE PROFILE
  // ==========================================================================

  group('P31.12 Exam Intelligence Profile', () {
    test('41. Empty exam produces empty profile with sufficientEvidence=false',
        () {
      final corpus = _buildTestCorpus();
      final profile = engine.buildExamProfile(
        corpus,
        examId: 'railways',
      );
      expect(profile.questionCount, 0);
      expect(profile.sufficientEvidence, false);
      expect(profile.subjectWeightage.entries, isEmpty);
      expect(profile.topicRecurrence, isEmpty);
    });

    test('42. UPSC profile is comprehensive and consistent', () {
      final corpus = _buildTestCorpus();
      final profile = engine.buildExamProfile(
        corpus,
        examId: 'upsc',
        frameworkObjectiveIds: ['OBJ_POL_FR', 'OBJ_HIST_MOD', 'OBJ_MISSING'],
      );

      expect(profile.examId, 'upsc');
      expect(profile.questionCount, 50);
      expect(profile.minYear, 2021);
      expect(profile.maxYear, 2025);
      expect(profile.sufficientEvidence, true);

      // Subject weightage
      expect(profile.subjectWeightage.totalQuestions, 50);
      expect(profile.subjectWeightage.entries.length, 3);

      // Topic weightage
      expect(profile.topicWeightage.totalQuestions, 50);

      // Objective coverage: 2 of 3 framework covered
      expect(
        profile.objectiveCoverage.mappingCoveragePercentage,
        closeTo(66.67, 0.01),
      );
      expect(profile.objectiveCoverage.uncoveredObjectiveIds, ['OBJ_MISSING']);

      // Year distribution
      expect(profile.yearDistribution.entries.length, 5);

      // Paper/language distribution
      expect(profile.paperDistribution['GS1'], 50);
      expect(profile.languageDistribution['en'], 50);

      // Topic recurrence
      expect(profile.topicRecurrence, isNotEmpty);

      // Quality
      expect(profile.qualityProfile.yearCoverage, 1.0);
      expect(profile.qualityProfile.provenanceCoverage, 1.0);
    });

    test('43. SSC sparse profile has sufficientEvidence=false', () {
      final corpus = _buildTestCorpus();
      final profile = engine.buildExamProfile(
        corpus,
        examId: 'ssc',
      );
      expect(profile.questionCount, 1);
      expect(profile.sufficientEvidence, false);
    });

    test('44. Evidence thresholds are configurable', () {
      const customEngine = PyqHistoricalIntelligenceEngine(
        thresholds: EvidenceThresholds(
          minimumQuestionsForWeightage: 2,
          minimumYearsForTrend: 1,
          minimumQuestionsForRecurrence: 1,
        ),
      );
      final corpus = _buildTestCorpus();
      final profile = customEngine.buildExamProfile(
        corpus,
        examId: 'ssc',
      );
      // SSC has 1 question, threshold is 2 -> not sufficient
      expect(profile.sufficientEvidence, false);

      final bpscProfile = customEngine.buildExamProfile(
        corpus,
        examId: 'bpsc',
      );
      // BPSC has 12 questions, threshold is 2 -> sufficient
      expect(bpscProfile.sufficientEvidence, true);
    });
  });

  // ==========================================================================
  // GROUP 13: LARGE CORPUS PERFORMANCE
  // ==========================================================================

  group('P31.13 Large Corpus Performance', () {
    test('45. 10K questions: all analytics complete in < 5s', () {
      final questions = <NormalizedQuestion>[];
      final subjects = ['Polity', 'History', 'Economy', 'Science', 'Geography'];
      final topics = [
        'TopicA',
        'TopicB',
        'TopicC',
        'TopicD',
        'TopicE',
        'TopicF',
        'TopicG',
        'TopicH',
        'TopicI',
        'TopicJ',
      ];
      final exams = ['upsc', 'bpsc', 'ssc', 'banking', 'railways'];

      for (int i = 0; i < 10000; i++) {
        questions.add(_q(
          examId: exams[i % 5],
          year: 2015 + (i % 11),
          subject: subjects[i % 5],
          topic: topics[i % 10],
          objectiveIds: ['OBJ_${i % 20}'],
          questionNumber: i + 1,
          text: 'Bench question $i',
        ));
      }

      final sw = Stopwatch()..start();

      engine.computeSubjectWeightage(questions);
      engine.computeTopicWeightage(questions);
      engine.computeObjectiveCoverage(questions);
      engine.computeYearDistribution(questions);
      engine.computeTopicTrends(questions);
      engine.computeObjectiveTrends(questions);
      engine.computeTopicRecency(
        questions,
        windowStartYear: 2023,
        windowEndYear: 2025,
      );
      engine.computeTopicRecurrence(questions);
      engine.computeObjectiveRecurrence(questions);
      engine.compareExams(questions, examIdA: 'upsc', examIdB: 'bpsc');
      engine.computeQualityProfile(questions);
      engine.buildExamProfile(questions, examId: 'upsc');

      sw.stop();
      // ignore: avoid_print
      print(
        'P31 10K benchmark: ${sw.elapsedMilliseconds}ms '
        '(all 12 analytics)',
      );
      expect(sw.elapsedMilliseconds, lessThan(5000));
    });

    test('46. 50K questions: exam profile build completes in < 10s', () {
      final questions = <NormalizedQuestion>[];
      for (int i = 0; i < 50000; i++) {
        questions.add(_q(
          examId: i % 2 == 0 ? 'upsc' : 'bpsc',
          year: 2010 + (i % 16),
          subject: 'Subject${i % 8}',
          topic: 'Topic${i % 25}',
          objectiveIds: ['OBJ_${i % 50}'],
          questionNumber: i + 1,
          text: 'Large bench $i',
        ));
      }

      final sw = Stopwatch()..start();
      engine.buildExamProfile(questions, examId: 'upsc');
      engine.buildExamProfile(questions, examId: 'bpsc');
      engine.compareExams(questions, examIdA: 'upsc', examIdB: 'bpsc');
      sw.stop();

      // ignore: avoid_print
      print(
        'P31 50K benchmark: ${sw.elapsedMilliseconds}ms '
        '(2 profiles + 1 comparison)',
      );
      expect(sw.elapsedMilliseconds, lessThan(10000));
    });
  });
}
