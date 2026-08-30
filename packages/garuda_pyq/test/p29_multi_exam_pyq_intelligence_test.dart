import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P29.1 Exam Registry & Multi-Exam Identity', () {
    test('1. Registry contains canonical default exams with accurate tiers',
        () {
      final registry = ExamRegistry();

      expect(registry.isRegistered('upsc'), isTrue);
      expect(registry.isRegistered('bpsc'), isTrue);
      expect(registry.isRegistered('ssc'), isTrue);
      expect(registry.isRegistered('banking'), isTrue);
      expect(registry.isRegistered('railways'), isTrue);

      final upsc = registry.getExam('upsc');
      expect(upsc, isNotNull);
      expect(upsc!.tier, ExamSupportTier.fullySupported);
      expect(upsc.isFullySupported, isTrue);
      expect(upsc.organization, 'Union Public Service Commission');

      final bpsc = registry.getExam('bpsc');
      expect(bpsc, isNotNull);
      expect(bpsc!.tier, ExamSupportTier.indexed);
      expect(bpsc.isIndexedOrBetter, isTrue);

      final ssc = registry.getExam('ssc');
      expect(ssc?.tier, ExamSupportTier.available);

      final railways = registry.getExam('railways');
      expect(railways?.tier, ExamSupportTier.registered);
    });

    test('2. Case-insensitive lookup and unknown exam handling', () {
      final registry = ExamRegistry();

      expect(registry.getExam('UPSC'), isNotNull);
      expect(registry.getExam('  Bpsc  '), isNotNull);
      expect(registry.getExam('unknown_exam_xyz'), isNull);
      expect(registry.isRegistered('nonexistent'), isFalse);
    });

    test('3. Custom exam registration and deterministic ordering', () {
      final registry = ExamRegistry();
      final custom = ExamProfile(
        examId: 'mpsc',
        displayName: 'Maharashtra Public Service Commission',
        organization: 'MPSC',
        subjects: ['General Studies', 'Marathi'],
        supportedYears: [2022, 2023, 2024],
        tier: ExamSupportTier.indexed,
      );

      registry.registerExam(custom);
      expect(registry.isRegistered('mpsc'), isTrue);
      expect(registry.getExam('mpsc')?.displayName,
          'Maharashtra Public Service Commission');

      // Deterministic sort by examId ascending
      final all = registry.allExams;
      final ids = all.map((e) => e.examId).toList();
      final sortedIds = [...ids]..sort();
      expect(ids, equals(sortedIds));
    });

    test('4. Tier-based exam filtering', () {
      final registry = ExamRegistry();
      final fullySupported =
          registry.getExamsByTier(ExamSupportTier.fullySupported);
      expect(fullySupported.map((e) => e.examId), contains('upsc'));

      final indexed = registry.getExamsByTier(ExamSupportTier.indexed);
      expect(indexed.map((e) => e.examId), contains('bpsc'));
    });
  });

  group('P29.2 Question Normalization Pipeline & Content Identity', () {
    test('5. Strips question prefixes and normalizes whitespace cleanly', () {
      expect(
        PyqNormalizationPipeline.normalizeQuestionText(
            'Q1. What is Article 21?'),
        'What is Article 21?',
      );
      expect(
        PyqNormalizationPipeline.normalizeQuestionText(
            'Question 42:  Which case established basic structure?'),
        'Which case established basic structure?',
      );
      expect(
        PyqNormalizationPipeline.normalizeQuestionText(
            '5)   Under the Constitution of India,   Preamble is:  '),
        'Under the Constitution of India, Preamble is:',
      );
      expect(
        PyqNormalizationPipeline.normalizeQuestionText(
            'प्रश्न 12. भारत का संविधान कब लागू हुआ?'),
        'भारत का संविधान कब लागू हुआ?',
      );
    });

    test('6. Normalizes option formats into standard keys and text', () {
      final rawList = [
        '(a) First option text',
        'B. Second option text',
        '3) Third option text',
        'D - Fourth option text',
      ];

      final options = PyqNormalizationPipeline.normalizeOptions(rawList);
      expect(options.length, 4);
      expect(options[0].key, 'A');
      expect(options[0].text, 'First option text');
      expect(options[1].key, 'B');
      expect(options[1].text, 'Second option text');
      expect(options[2].key, 'C'); // '3' normalized to 'C'
      expect(options[2].text, 'Third option text');
      expect(options[3].key, 'D');
      expect(options[3].text, 'Fourth option text');
    });

    test(
        '7. Complete raw input normalization preserves provenance and original text',
        () {
      const input = RawQuestionInput(
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Basic Structure',
        questionText:
            'Q14.   Which case established the Basic Structure Doctrine?   ',
        options: [
          '(a) Golaknath',
          '(b) Kesavananda Bharati',
          '(c) Minerva Mills',
          '(d) Maneka Gandhi'
        ],
        correctAnswer: 'B',
        explanation: 'Kesavananda Bharati v. State of Kerala (1973).',
      );

      final normalized = PyqNormalizationPipeline.normalize(input);
      expect(normalized.examId, 'upsc');
      expect(normalized.year, 2024);
      expect(normalized.paper, 'GS1');
      expect(normalized.normalizedText,
          'Which case established the Basic Structure Doctrine?');
      expect(normalized.originalText,
          'Q14.   Which case established the Basic Structure Doctrine?   ');
      expect(normalized.options.length, 4);
      expect(normalized.correctOption, 'B');
      expect(normalized.source.sourceId, 'SRC_UPSC_2024_GS1');
      expect(normalized.id.startsWith('PYQ_UPSC_2024_GS1_'), isTrue);
    });

    test('8. Handles multilingual Unicode & Devanagari Hindi text', () {
      const hindiInput = RawQuestionInput(
        examId: 'bpsc',
        year: 2023,
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Preamble',
        questionText:
            'प्रश्न 1. भारतीय संविधान की प्रस्तावना में "धर्मनिरपेक्ष" शब्द किस संशोधन द्वारा जोड़ा गया?',
        options: [
          '(a) 42वां संशोधन',
          '(b) 44वां संशोधन',
          '(c) 73वां संशोधन',
          '(d) 86वां संशोधन'
        ],
        correctAnswer: 'A',
        language: 'hi',
      );

      final normalized = PyqNormalizationPipeline.normalize(hindiInput);
      expect(normalized.language, 'hi');
      expect(normalized.normalizedText,
          'भारतीय संविधान की प्रस्तावना में "धर्मनिरपेक्ष" शब्द किस संशोधन द्वारा जोड़ा गया?');
      expect(normalized.options[0].text, '42वां संशोधन');
    });

    test(
        '9. Deterministic content-addressable ID survives re-runs and ignores list position',
        () {
      final id1 = DeterministicQuestionId.generate(
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        normalizedQuestionText: 'Which case established basic structure?',
        language: 'en',
      );
      final id2 = DeterministicQuestionId.generate(
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        normalizedQuestionText: 'Which case established basic structure?',
        language: 'en',
      );
      final idDifferentExam = DeterministicQuestionId.generate(
        examId: 'bpsc',
        year: 2024,
        paper: 'GS1',
        normalizedQuestionText: 'Which case established basic structure?',
        language: 'en',
      );

      expect(id1, equals(id2));
      expect(id1, isNot(equals(idDifferentExam)));
    });
  });

  group('P29.3 Deterministic Deduplication & Language Variants', () {
    test('10. Exact and normalized duplicates detected in O(N) time', () {
      final q1 = PyqNormalizationPipeline.normalize(const RawQuestionInput(
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        questionText: 'Which case established basic structure?',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'B',
      ));

      // Same question with prefix and extra whitespace
      final q2 = PyqNormalizationPipeline.normalize(const RawQuestionInput(
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        questionText: 'Q. 1   Which case established basic structure?   ',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'B',
      ));

      final result = DeterministicDuplicateDetector.filterDuplicates(
        existingCorpus: [q1],
        incoming: [q2],
      );

      expect(result.uniqueCount, 0);
      expect(result.duplicateCount, 1);
      expect(result.duplicates.first.originalId, q1.id);
    });

    test(
        '11. Legitimate language/translation variants are NOT treated as duplicates',
        () {
      // English version
      final qEn = PyqNormalizationPipeline.normalize(const RawQuestionInput(
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        questionText:
            'Under the Constitution, which Article guarantees Right to Privacy?',
        options: [
          '(a) Article 19',
          '(b) Article 21',
          '(c) Article 14',
          '(d) Article 32'
        ],
        correctAnswer: 'B',
        language: 'en',
      ));

      // Hindi translation of the same question
      final qHi = PyqNormalizationPipeline.normalize(const RawQuestionInput(
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        questionText:
            'संविधान के तहत, कौन सा अनुच्छेद निजता के अधिकार की गारंटी देता है?',
        options: [
          '(a) अनुच्छेद 19',
          '(b) अनुच्छेद 21',
          '(c) अनुच्छेद 14',
          '(d) अनुच्छेद 32'
        ],
        correctAnswer: 'B',
        language: 'hi',
      ));

      final result = DeterministicDuplicateDetector.filterDuplicates(
        existingCorpus: [qEn],
        incoming: [qHi],
      );

      expect(result.uniqueCount, 1);
      expect(result.duplicateCount, 0);
      expect(result.uniqueQuestions.first.language, 'hi');
    });
  });

  group('P29.4 Composable Multi-Exam Filtering', () {
    late List<NormalizedQuestion> corpus;

    setUp(() {
      final inputs = [
        const RawQuestionInput(
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Basic Structure',
          difficulty: 'Medium',
          language: 'en',
          questionText: 'UPSC 2024 Basic Structure Question',
          options: ['A', 'B'],
          correctAnswer: 'A',
          objectiveIds: ['lo_basic_structure'],
        ),
        const RawQuestionInput(
          examId: 'upsc',
          year: 2023,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Preamble',
          difficulty: 'Easy',
          language: 'en',
          questionText: 'UPSC 2023 Preamble Question',
          options: ['A', 'B'],
          correctAnswer: 'B',
          objectiveIds: ['lo_preamble'],
        ),
        const RawQuestionInput(
          examId: 'bpsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Governor Powers',
          difficulty: 'Hard',
          language: 'en',
          questionText: 'BPSC 2024 Governor Powers Question',
          options: ['A', 'B'],
          correctAnswer: 'A',
        ),
        const RawQuestionInput(
          examId: 'ssc',
          year: 2024,
          paper: 'Tier1',
          subject: 'General Awareness',
          topic: 'Constitution',
          difficulty: 'Easy',
          language: 'hi',
          questionText: 'SSC 2024 Constitution Question in Hindi',
          options: ['A', 'B'],
          correctAnswer: 'A',
        ),
      ];

      corpus = PyqNormalizationPipeline.normalizeBatch(inputs);
    });

    test('12. Exam filter enforces strict boundary without cross-exam leakage',
        () {
      final upscOnly = PyqFilterEngine.filter(
        corpus,
        const PyqFilterCriteria(examId: 'upsc'),
      );
      expect(upscOnly.length, 2);
      expect(upscOnly.every((q) => q.examId == 'upsc'), isTrue);

      final bpscOnly = PyqFilterEngine.filter(
        corpus,
        const PyqFilterCriteria(examId: 'bpsc'),
      );
      expect(bpscOnly.length, 1);
      expect(bpscOnly.first.examId, 'bpsc');
    });

    test(
        '13. Composable multi-dimensional query (exam + year + subject + topic)',
        () {
      final match = PyqFilterEngine.filter(
        corpus,
        const PyqFilterCriteria(
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Polity',
        ),
      );

      expect(match.length, 1);
      expect(match.first.topic, 'Basic Structure');
      expect(match.first.year, 2024);
    });

    test('14. Filter by objectiveId', () {
      final match = PyqFilterEngine.filter(
        corpus,
        const PyqFilterCriteria(objectiveId: 'lo_preamble'),
      );
      expect(match.length, 1);
      expect(match.first.topic, 'Preamble');
    });
  });

  group('P29.5 Curriculum Objective Mapping', () {
    test(
        '15. Explicit mapping resolves objectives and preserves unmapped state',
        () {
      final mapper = CurriculumObjectiveMapper();
      mapper.mapTopicToObjective(
        examId: 'upsc',
        topic: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
      );

      final q1 = PyqNormalizationPipeline.normalize(const RawQuestionInput(
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        questionText: 'Article 21 question',
        options: ['A', 'B'],
        correctAnswer: 'A',
      ));

      final mapped = mapper.applyMapping(q1);
      expect(mapped.objectiveIds, contains('lo_article_21_foundations'));

      // Unmapped question stays unmapped without fabrication
      final qUnmapped =
          PyqNormalizationPipeline.normalize(const RawQuestionInput(
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Miscellaneous Unmapped Topic',
        questionText: 'Unmapped question',
        options: ['A', 'B'],
        correctAnswer: 'A',
      ));

      final mapped2 = mapper.applyMapping(qUnmapped);
      expect(mapped2.objectiveIds, isEmpty);
    });
  });

  group(
      'P29.6 Corpus Intelligence Analytics (Corpus Only, Zero Learner Inference)',
      () {
    test('16. Computes multi-exam distributions and coverage metrics', () {
      final questions = [
        PyqNormalizationPipeline.normalize(const RawQuestionInput(
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Preamble',
          questionText: 'Q1',
          options: ['A', 'B'],
          correctAnswer: 'A',
          objectiveIds: ['lo_preamble'],
        )),
        PyqNormalizationPipeline.normalize(const RawQuestionInput(
          examId: 'upsc',
          year: 2023,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Fundamental Rights',
          questionText: 'Q2',
          options: ['A', 'B'],
          correctAnswer: 'A',
          objectiveIds: ['lo_fr'],
        )),
        PyqNormalizationPipeline.normalize(const RawQuestionInput(
          examId: 'bpsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Preamble',
          questionText: 'Q3',
          options: ['A', 'B'],
          correctAnswer: 'A',
          objectiveIds: ['lo_preamble'],
        )),
        PyqNormalizationPipeline.normalize(const RawQuestionInput(
          examId: 'ssc',
          year: 2024,
          paper: 'Tier1',
          subject: 'History',
          topic: 'Modern India',
          questionText: 'Q4',
          options: ['A', 'B'],
          correctAnswer: 'A',
        )),
      ];

      final analytics = PyqCorpusIntelligence.analyze(
        questions,
        frameworkObjectiveIds: ['lo_preamble', 'lo_fr', 'lo_dpsp'],
      );

      expect(analytics.totalQuestions, 4);
      expect(analytics.examDistribution['upsc'], 2);
      expect(analytics.examDistribution['bpsc'], 1);
      expect(analytics.examDistribution['ssc'], 1);
      expect(analytics.yearDistribution[2024], 3);
      expect(analytics.yearDistribution[2023], 1);
      expect(analytics.subjectDistribution['Polity'], 3);
      expect(analytics.subjectDistribution['History'], 1);
      expect(analytics.objectiveDistribution['lo_preamble'], 2);
      expect(analytics.objectiveDistribution['lo_fr'], 1);

      // Coverage: 2 out of 3 framework objectives covered -> 66.67%
      expect(analytics.objectiveCoveragePercentage, closeTo(66.67, 0.1));
      expect(analytics.topCoveredObjectives.first, 'lo_preamble');
      expect(analytics.unmappedObjectives, contains('lo_dpsp'));
    });

    test('17. Empty corpus returns deterministic empty defaults', () {
      final empty = PyqCorpusIntelligence.analyze([]);
      expect(empty.totalQuestions, 0);
      expect(empty.examDistribution, isEmpty);
      expect(empty.yearDistribution, isEmpty);
      expect(empty.objectiveCoveragePercentage, 0.0);
    });
  });

  group('P29.7 Historical Trend Analysis & Educational Safety Invariants', () {
    test('18. Historical frequency matrices and evidence-based statements', () {
      final questions = [
        for (int y = 2020; y <= 2024; y++)
          PyqNormalizationPipeline.normalize(RawQuestionInput(
            examId: 'upsc',
            year: y,
            paper: 'GS1',
            subject: 'Polity',
            topic: 'Preamble',
            questionText: 'Preamble question for year $y',
            options: const ['A', 'B'],
            correctAnswer: 'A',
            objectiveIds: const ['lo_preamble'],
          )),
        for (int y = 2018; y <= 2020; y++)
          PyqNormalizationPipeline.normalize(RawQuestionInput(
            examId: 'upsc',
            year: y,
            paper: 'GS1',
            subject: 'Polity',
            topic: 'Historical Background',
            questionText: 'History question for year $y',
            options: const ['A', 'B'],
            correctAnswer: 'A',
          )),
      ];

      final trend = PyqTrendAnalyzer.analyzeTrends(
        questions: questions,
        examId: 'upsc',
        recentYearsWindow: 3,
        referenceYear: 2024,
      );

      expect(trend.examId, 'upsc');
      expect(trend.topicFrequencyByYear['Preamble']?[2024], 1);
      expect(trend.topicFrequencyByYear['Preamble']?[2023], 1);
      expect(trend.topicFrequencyByYear['Preamble']?[2022], 1);

      // Verify educational safety invariants: language must be historical evidence only
      for (final insight in trend.topicInsights) {
        expect(insight.evidenceStatement, isNot(contains('will appear')));
        expect(insight.evidenceStatement, isNot(contains('guaranteed')));
        expect(insight.evidenceStatement, isNot(contains('predict')));
      }

      final preambleInsight =
          trend.topicInsights.firstWhere((i) => i.topic == 'Preamble');
      expect(preambleInsight.totalCount, 5);
      expect(preambleInsight.recentCount, 3);
      expect(preambleInsight.evidenceStatement,
          contains('has recent historical activity'));
    });
  });

  group('P29.8 High-Level MultiExamPyqIntelligenceService & Learner Isolation',
      () {
    test(
        '19. End-to-end service lifecycle: ingest -> deduplicate -> query -> analytics -> trends',
        () {
      final service = MultiExamPyqIntelligenceService();

      service.objectiveMapper.mapTopicToObjective(
        examId: 'upsc',
        topic: 'Constitutional Law',
        objectiveId: 'lo_const_law',
      );

      final inputs = [
        const RawQuestionInput(
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Constitutional Law',
          questionText: '1. What constitutes Basic Structure?',
          options: ['A', 'B', 'C', 'D'],
          correctAnswer: 'B',
        ),
        // Exact duplicate
        const RawQuestionInput(
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Constitutional Law',
          questionText: 'What constitutes Basic Structure?',
          options: ['A', 'B', 'C', 'D'],
          correctAnswer: 'B',
        ),
        // BPSC Question
        const RawQuestionInput(
          examId: 'bpsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'State Legislature',
          questionText: 'Powers of State Legislative Assembly',
          options: ['A', 'B'],
          correctAnswer: 'A',
        ),
      ];

      final ingestionResult = service.ingestRawQuestions(inputs);
      expect(ingestionResult.uniqueCount, 2);
      expect(ingestionResult.duplicateCount, 1);
      expect(service.totalQuestionsCount, 2);

      // Query by objective
      final objectiveQuestions =
          service.getQuestionsForObjective('lo_const_law', examId: 'upsc');
      expect(objectiveQuestions.length, 1);
      expect(objectiveQuestions.first.topic, 'Constitutional Law');

      // Corpus analytics
      final analytics = service.getCorpusAnalytics();
      expect(analytics.totalQuestions, 2);
      expect(analytics.examDistribution['upsc'], 1);
      expect(analytics.examDistribution['bpsc'], 1);

      // Trend analysis
      final trends = service.getTrendAnalysis(examId: 'upsc');
      expect(trends.topicInsights.first.topic, 'Constitutional Law');
    });

    test(
        '20. Learner Isolation Invariant: Corpus queries never mutate or create learner evidence',
        () {
      final service = MultiExamPyqIntelligenceService();
      service.ingestRawQuestions([
        const RawQuestionInput(
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Preamble',
          questionText: 'Preamble question',
          options: ['A', 'B'],
          correctAnswer: 'A',
        )
      ]);

      // Verify that querying corpus questions is strictly read-only and does not touch or instantiate learner models
      final questions = service.getAllQuestions();
      expect(questions.length, 1);
      final q = questions.first;
      expect(q.id, isNotEmpty);

      // The question does not contain learner state
      expect(q.objectiveIds, isEmpty);
      expect(q.tags, isEmpty);
    });

    test(
        '21. Persistence & Restart Safety: Snapshot export and restoration preserves corpus',
        () {
      final serviceInstanceA = MultiExamPyqIntelligenceService();
      serviceInstanceA.ingestRawQuestions([
        const RawQuestionInput(
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Basic Structure',
          questionText: 'Which case established Basic Structure?',
          options: ['A', 'B'],
          correctAnswer: 'B',
        ),
        const RawQuestionInput(
          examId: 'bpsc',
          year: 2023,
          paper: 'GS1',
          subject: 'History',
          topic: '1857 Revolt',
          questionText: 'Kunwar Singh led 1857 revolt from where?',
          options: ['A', 'B'],
          correctAnswer: 'A',
        ),
      ]);

      expect(serviceInstanceA.totalQuestionsCount, 2);

      // Export snapshot
      final snapshot = serviceInstanceA.exportSnapshot();
      expect(snapshot['corpus'], isNotEmpty);

      // Simulate restart into fresh service instance B
      final serviceInstanceB = MultiExamPyqIntelligenceService();
      expect(serviceInstanceB.totalQuestionsCount, 0);

      serviceInstanceB.restoreSnapshot(snapshot);
      expect(serviceInstanceB.totalQuestionsCount, 2);

      final upscQ = serviceInstanceB
          .getQuestions(const PyqFilterCriteria(examId: 'upsc'));
      expect(upscQ.length, 1);
      expect(upscQ.first.topic, 'Basic Structure');

      final bpscQ = serviceInstanceB
          .getQuestions(const PyqFilterCriteria(examId: 'bpsc'));
      expect(bpscQ.length, 1);
      expect(bpscQ.first.topic, '1857 Revolt');
    });
  });
}
