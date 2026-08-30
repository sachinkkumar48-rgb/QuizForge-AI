import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

/// P31 Integration Test: End-to-end pipeline from P30 fixtures through
/// P29 ingestion to P31 historical intelligence.
///
/// Flow: P30 fixture -> ingestion -> P29 normalized corpus -> P31 intelligence
///       -> subject profile -> topic profile -> objective coverage
///       -> year trend -> recurrence -> quality profile
void main() {
  test(
    'P31 Integration: P30 source -> P29 corpus -> P31 full intelligence pipeline',
    () {
      // ====================================================================
      // PHASE 1: P30 Source Descriptors & Fixture Data
      // ====================================================================
      final upscSource = PyqSourceDescriptor(
        sourceId: 'INT_UPSC_2024',
        sourceName: 'UPSC CSE 2024 Source',
        examId: 'upsc',
        publisher: 'UPSC',
        sourceType: SourceType.officialPdf,
        format: PyqSourceFormat.json,
        years: [2023, 2024, 2025],
        languages: ['en'],
        uriOrPath: 'fixture://upsc_2024.json',
      );

      final bpscSource = PyqSourceDescriptor(
        sourceId: 'INT_BPSC_2024',
        sourceName: 'BPSC 2024 Source',
        examId: 'bpsc',
        publisher: 'BPSC',
        sourceType: SourceType.officialPdf,
        format: PyqSourceFormat.json,
        years: [2023, 2024],
        languages: ['en', 'hi'],
        uriOrPath: 'fixture://bpsc_2024.json',
      );

      // ====================================================================
      // PHASE 2: P29 Intelligence Service with raw question ingestion
      // ====================================================================
      final service = MultiExamPyqIntelligenceService();

      // UPSC corpus: 30 questions across 3 years
      final upscRaw = <RawQuestionInput>[];
      int qNum = 0;
      for (int year = 2023; year <= 2025; year++) {
        // Polity: 4 per year
        for (int i = 0; i < 4; i++) {
          qNum++;
          upscRaw.add(RawQuestionInput(
            examId: 'upsc',
            year: year,
            paper: 'GS1',
            subject: 'Polity',
            topic: i < 2 ? 'Fundamental Rights' : 'DPSP',
            questionText: 'UPSC Polity Q$qNum year $year',
            options: const ['Opt A', 'Opt B', 'Opt C', 'Opt D'],
            correctAnswer: 'A',
            language: 'en',
            objectiveIds: ['OBJ_POL_FR'],
            source: PyqSourceReference.official(
              examId: 'upsc',
              year: year,
              paper: 'GS1',
            ),
          ));
        }
        // History: 3 per year
        for (int i = 0; i < 3; i++) {
          qNum++;
          upscRaw.add(RawQuestionInput(
            examId: 'upsc',
            year: year,
            paper: 'GS1',
            subject: 'History',
            topic: 'Modern India',
            questionText: 'UPSC History Q$qNum year $year',
            options: const ['Opt A', 'Opt B', 'Opt C', 'Opt D'],
            correctAnswer: 'B',
            language: 'en',
            objectiveIds: ['OBJ_HIST_MOD'],
            source: PyqSourceReference.official(
              examId: 'upsc',
              year: year,
              paper: 'GS1',
            ),
          ));
        }
        // Economy: 3 per year (1 unmapped)
        for (int i = 0; i < 3; i++) {
          qNum++;
          upscRaw.add(RawQuestionInput(
            examId: 'upsc',
            year: year,
            paper: 'GS1',
            subject: 'Economy',
            topic: i == 0 ? 'Fiscal Policy' : 'Banking',
            questionText: 'UPSC Economy Q$qNum year $year',
            options: const ['Opt A', 'Opt B', 'Opt C', 'Opt D'],
            correctAnswer: 'C',
            language: 'en',
            objectiveIds: i < 2 ? ['OBJ_ECON_FP'] : [],
            source: PyqSourceReference.official(
              examId: 'upsc',
              year: year,
              paper: 'GS1',
            ),
          ));
        }
      }

      final upscResult = service.ingestRawQuestions(
        upscRaw,
        defaultSource: PyqSourceReference.official(
          examId: upscSource.examId,
          year: 2024,
          paper: 'GS1',
        ),
      );
      expect(upscResult.uniqueQuestions.length, 30);

      // BPSC corpus: 10 questions across 2 years
      final bpscRaw = <RawQuestionInput>[];
      for (int year = 2023; year <= 2024; year++) {
        for (int i = 0; i < 5; i++) {
          qNum++;
          bpscRaw.add(RawQuestionInput(
            examId: 'bpsc',
            year: year,
            paper: 'GS',
            subject: i < 3 ? 'Polity' : 'History',
            topic: i < 3 ? 'State Legislature' : 'Ancient India',
            questionText: 'BPSC Q$qNum year $year',
            options: const ['Opt A', 'Opt B', 'Opt C', 'Opt D'],
            correctAnswer: 'D',
            language: i % 2 == 0 ? 'en' : 'hi',
            objectiveIds: i < 3 ? ['OBJ_POL_SL'] : ['OBJ_HIST_ANC'],
            source: PyqSourceReference.official(
              examId: 'bpsc',
              year: year,
              paper: 'GS',
            ),
          ));
        }
      }

      final bpscResult = service.ingestRawQuestions(
        bpscRaw,
        defaultSource: PyqSourceReference.official(
          examId: bpscSource.examId,
          year: 2024,
          paper: 'GS',
        ),
      );
      expect(bpscResult.uniqueQuestions.length, 10);

      // Total corpus
      final allQuestions = service.getAllQuestions();
      expect(allQuestions.length, 40);

      // ====================================================================
      // PHASE 3: P31 Historical Intelligence Engine
      // ====================================================================
      const engine = PyqHistoricalIntelligenceEngine();

      // --- Subject Profile ---
      final subjectW = engine.computeSubjectWeightage(
        allQuestions.where((q) => q.examId == 'upsc').toList(),
      );
      expect(subjectW.totalQuestions, 30);
      final polityEntry =
          subjectW.entries.firstWhere((e) => e.category == 'Polity');
      expect(polityEntry.count, 12);
      expect(polityEntry.percentage, 40.0);
      expect(polityEntry.rank, 1);

      // --- Topic Profile (filtered) ---
      final topicW = engine.computeTopicWeightage(
        allQuestions,
        examId: 'upsc',
        startYear: 2024,
        endYear: 2025,
        subject: 'Polity',
      );
      expect(topicW.totalQuestions, 8); // 4 per year * 2 years
      final frEntry =
          topicW.entries.firstWhere((e) => e.category == 'Fundamental Rights');
      expect(frEntry.count, 4); // 2 per year * 2 years
      final dpspEntry = topicW.entries.firstWhere((e) => e.category == 'DPSP');
      expect(dpspEntry.count, 4);

      // --- Objective Coverage ---
      final framework = [
        'OBJ_POL_FR',
        'OBJ_HIST_MOD',
        'OBJ_ECON_FP',
        'OBJ_MISSING_X',
      ];
      final objCov = engine.computeObjectiveCoverage(
        allQuestions.where((q) => q.examId == 'upsc').toList(),
        frameworkObjectiveIds: framework,
      );
      expect(objCov.totalQuestions, 30);
      // 3 of 4 framework objectives covered
      expect(objCov.mappingCoveragePercentage, 75.0);
      expect(objCov.uncoveredObjectiveIds, ['OBJ_MISSING_X']);

      // --- Year Trend ---
      final yearDist = engine.computeYearDistribution(
        allQuestions.where((q) => q.examId == 'upsc').toList(),
      );
      expect(yearDist.entries.length, 3);
      for (final entry in yearDist.entries) {
        expect(entry.questionCount, 10);
        expect(entry.subjectDistribution['Polity'], 4);
        expect(entry.subjectDistribution['History'], 3);
        expect(entry.subjectDistribution['Economy'], 3);
      }

      // --- Recurrence ---
      final topicRec = engine.computeTopicRecurrence(
        allQuestions.where((q) => q.examId == 'upsc').toList(),
      );
      final frRec = topicRec.firstWhere((r) => r.id == 'Fundamental Rights');
      expect(frRec.yearCount, 3);
      expect(frRec.yearsPresent, [2023, 2024, 2025]);

      // --- Cross-Exam Comparison ---
      final comparison = engine.compareExams(
        allQuestions,
        examIdA: 'upsc',
        examIdB: 'bpsc',
      );
      expect(comparison.entryA.corpusSize, 30);
      expect(comparison.entryB.corpusSize, 10);
      expect(comparison.entryA.yearCoverage, 3);
      expect(comparison.entryB.yearCoverage, 2);
      expect(comparison.entryB.languageDistribution.containsKey('hi'), isTrue);

      // --- Quality Profile ---
      final quality = engine.computeQualityProfile(
        allQuestions.where((q) => q.examId == 'upsc').toList(),
      );
      expect(quality.totalQuestions, 30);
      expect(quality.yearCoverage, 1.0);
      expect(quality.provenanceCoverage, 1.0);
      // 27 of 30 have objectives mapped
      expect(quality.objectiveMappingCoverage, 0.9);

      // --- Full Exam Profile ---
      final profile = engine.buildExamProfile(
        allQuestions,
        examId: 'upsc',
        frameworkObjectiveIds: framework,
      );
      expect(profile.examId, 'upsc');
      expect(profile.questionCount, 30);
      expect(profile.sufficientEvidence, true);
      expect(profile.minYear, 2023);
      expect(profile.maxYear, 2025);

      // --- Determinism check ---
      final profile2 = engine.buildExamProfile(
        allQuestions,
        examId: 'upsc',
        frameworkObjectiveIds: framework,
      );
      expect(profile.toJson().toString(), profile2.toJson().toString());

      // --- Recency ---
      final recency = engine.computeTopicRecency(
        allQuestions.where((q) => q.examId == 'upsc').toList(),
        windowStartYear: 2025,
        windowEndYear: 2025,
      );
      expect(recency, isNotEmpty);
      for (final r in recency) {
        expect(r.totalCount, greaterThan(0));
        // No NaN
        expect(r.recentShare.isNaN, false);
        expect(r.recentShare.isInfinite, false);
      }
    },
  );
}
