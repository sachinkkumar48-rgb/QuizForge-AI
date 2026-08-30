import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group(
      'P29 End-to-End Multi-Exam PYQ Intelligence Integration with GARUDA Learning',
      () {
    test(
        'Full End-to-End Pipeline: Ingest -> Normalize -> Deduplicate -> Map -> Query -> Trends -> GARUDA Learning',
        () async {
      // 1. Initialize MultiExamPyqIntelligenceService
      final pyqService = MultiExamPyqIntelligenceService();

      // Verify exam registry supports UPSC, BPSC, SSC, Banking, Railways
      expect(pyqService.registry.isRegistered('upsc'), isTrue);
      expect(pyqService.registry.isRegistered('bpsc'), isTrue);
      expect(pyqService.registry.isRegistered('ssc'), isTrue);
      expect(pyqService.registry.isRegistered('banking'), isTrue);
      expect(pyqService.registry.isRegistered('railways'), isTrue);

      // 2. Set up curriculum objective mappings for P17 curriculum
      pyqService.objectiveMapper.mapTopicToObjective(
        examId: 'upsc',
        topic: 'Preamble',
        objectiveId: 'lo_preamble_identity',
      );
      pyqService.objectiveMapper.mapTopicToObjective(
        examId: 'upsc',
        topic: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
      );

      // 3. Ingest multi-exam raw questions (including duplicates, variants, multi-year)
      final rawInputs = [
        // UPSC 2024 Preamble
        const RawQuestionInput(
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Preamble',
          questionText:
              'Q1. The Preamble to the Indian Constitution is based on which resolution?',
          options: [
            '(a) Objective Resolution',
            '(b) Karachi Resolution',
            '(c) Lahore Resolution',
            '(d) Poona Pact'
          ],
          correctAnswer: 'A',
          explanation: 'Moved by Jawaharlal Nehru in 1946.',
        ),
        // Duplicate of above with formatting variation
        const RawQuestionInput(
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Preamble',
          questionText:
              'The Preamble to the Indian Constitution is based on which resolution?',
          options: [
            'A. Objective Resolution',
            'B. Karachi Resolution',
            'C. Lahore Resolution',
            'D. Poona Pact'
          ],
          correctAnswer: 'A',
        ),
        // UPSC 2023 Fundamental Rights
        const RawQuestionInput(
          examId: 'upsc',
          year: 2023,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Fundamental Rights',
          questionText:
              'Q18. Which Article protects the Right to Travel Abroad?',
          options: [
            '(a) Article 14',
            '(b) Article 19',
            '(c) Article 21',
            '(d) Article 25'
          ],
          correctAnswer: 'C',
          explanation: 'Affirmed in Maneka Gandhi v. Union of India (1978).',
        ),
        // BPSC 2024 Question (Multi-exam isolation check)
        const RawQuestionInput(
          examId: 'bpsc',
          year: 2024,
          paper: 'GS1',
          subject: 'State Administration',
          topic: 'State Executive',
          questionText: 'Who appoints the Advocate General of a State?',
          options: [
            '(a) Governor',
            '(b) Chief Minister',
            '(c) President',
            '(d) High Court CJ'
          ],
          correctAnswer: 'A',
        ),
      ];

      final importReport = pyqService.ingestRawQuestions(rawInputs);
      expect(importReport.uniqueCount, 3,
          reason: 'Duplicate UPSC Preamble question correctly detected');
      expect(importReport.duplicateCount, 1);
      expect(pyqService.totalQuestionsCount, 3);

      // 4. Query by exam (verify zero cross-exam leakage)
      final upscQuestions =
          pyqService.getQuestions(const PyqFilterCriteria(examId: 'upsc'));
      expect(upscQuestions.length, 2);
      expect(upscQuestions.every((q) => q.examId == 'upsc'), isTrue);

      final bpscQuestions =
          pyqService.getQuestions(const PyqFilterCriteria(examId: 'bpsc'));
      expect(bpscQuestions.length, 1);
      expect(bpscQuestions.first.examId, 'bpsc');

      // 5. Query by topic
      final preambleQuestions = pyqService.getQuestions(const PyqFilterCriteria(
        examId: 'upsc',
        topic: 'Preamble',
      ));
      expect(preambleQuestions.length, 1);
      expect(preambleQuestions.first.objectiveIds,
          contains('lo_preamble_identity'));

      // 6. Calculate historical frequency & trend analysis
      final trendReport =
          pyqService.getTrendAnalysis(examId: 'upsc', recentYearsWindow: 3);
      expect(trendReport.topicFrequencyByYear['Preamble']?[2024], 1);
      expect(trendReport.topicFrequencyByYear['Fundamental Rights']?[2023], 1);
      expect(trendReport.topicInsights.isNotEmpty, isTrue);

      // 7. Bridge into GARUDA Learning via PyqQuestionProvider
      final pyqEntities = upscQuestions.map((q) => q.toPyqQuestion()).toList();
      final questionProvider = PyqQuestionProvider(
        questions: pyqEntities,
        topicOrTagToObjectiveIds: {
          'preamble': ['lo_preamble_identity'],
          'fundamental rights': ['lo_article_21_foundations'],
          'lo_preamble_identity': ['lo_preamble_identity'],
          'lo_article_21_foundations': ['lo_article_21_foundations'],
        },
      );

      final learningQuestions =
          questionProvider.getQuestionsForObjectives(['lo_preamble_identity']);
      expect(learningQuestions.length, 1);
      final lq = learningQuestions.first;
      expect(lq.prompt, contains('Preamble to the Indian Constitution'));
      expect(lq.expectedAnswer, 'A');

      // 8. Verify compatibility with GARUDA AssessmentService (P19/P26/P27)
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final curriculumService = CurriculumService(framework: framework);

      final learnerRepo = InMemoryLearnerRepository();
      learnerRepo.save(Learner(
        id: 'learner_p29_integration',
        name: 'P29 Test Learner',
        createdAt: DateTime.utc(2026, 8, 30),
      ));

      final attemptRepo = InMemoryAttemptRepository();
      final progressRepo = InMemoryProgressRepository();

      final assessmentService = AssessmentService(
        learnerRepository: learnerRepo,
        attemptRepository: attemptRepo,
        curriculumService: curriculumService,
        questionProvider: questionProvider,
        progressTracker: ProgressTracker(
          attemptRepository: attemptRepo,
          progressRepository: progressRepo,
        ),
      );

      // Submit attempt using question derived from multi-exam PYQ intelligence
      final attemptResult = assessmentService.submitAttempt(
        learnerId: 'learner_p29_integration',
        questionId: lq.id,
        objectiveId: 'lo_preamble_identity',
        submittedAnswer: 'A',
      );

      expect(attemptResult.isCorrect, isTrue);
      final storedAttempt = attemptRepo.getAttemptById(attemptResult.attemptId);
      expect(storedAttempt?.objectiveId, 'lo_preamble_identity');

      // 9. Corpus Intelligence analytics verification against real P17 framework
      final frameworkObjIds = framework.allObjectives.map((o) => o.id).toList();
      final corpusAnalytics = pyqService.getCorpusAnalytics(
        frameworkObjectiveIds: frameworkObjIds,
      );
      expect(corpusAnalytics.totalQuestions, 3);
      expect(corpusAnalytics.examDistribution['upsc'], 2);
      expect(corpusAnalytics.examDistribution['bpsc'], 1);
      expect(corpusAnalytics.topCoveredObjectives,
          contains('lo_preamble_identity'));
      expect(corpusAnalytics.topCoveredObjectives,
          contains('lo_article_21_foundations'));
    });
  });
}
