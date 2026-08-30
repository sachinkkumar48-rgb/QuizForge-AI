import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P30 Multi-Exam PYQ Acquisition & Ingestion Pipeline Integration', () {
    test(
        'End-to-End Flow: Source Descriptors -> Fetcher -> Parsers -> Ingestion Engine -> P29 Intelligence -> GARUDA Learning',
        () async {
      // 1. Initialize Acquisition Engine and dependencies
      final fetcher = InMemorySourceFetcher();
      final engine = MultiExamPyqAcquisitionEngine(fetcher: fetcher);
      final intelligenceService = engine.intelligenceService;

      // Register curriculum objective mappings
      intelligenceService.objectiveMapper.mapTopicToObjective(
        examId: 'upsc',
        topic: 'Preamble',
        objectiveId: 'lo_preamble_identity',
      );
      intelligenceService.objectiveMapper.mapTopicToObjective(
        examId: 'upsc',
        topic: 'Fundamental Rights',
        objectiveId: 'lo_article_21_foundations',
      );

      // 2. Define Multi-Exam Sources in diverse formats
      // Source A: UPSC 2024 (JSON format)
      const upscDesc = PyqSourceDescriptor(
        sourceId: 'SRC_UPSC_2024_JSON',
        sourceName: 'UPSC CSE 2024 Prelims GS1',
        examId: 'upsc',
        publisher: 'Union Public Service Commission',
        sourceType: SourceType.officialPdf,
        format: PyqSourceFormat.json,
        years: [2024],
        languages: ['en'],
        uriOrPath: 'corpus/upsc_2024.json',
      );

      const upscJson = '''[
        {
          "examId": "upsc",
          "year": 2024,
          "paper": "GS1",
          "questionNumber": 1,
          "subject": "Polity",
          "topic": "Preamble",
          "questionText": "The Preamble to the Constitution of India is based on the Objective Resolution moved by whom?",
          "options": ["(A) Jawaharlal Nehru", "(B) Dr. B.R. Ambedkar", "(C) Dr. Rajendra Prasad", "(D) Sardar Patel"],
          "correctAnswer": "A",
          "explanation": "Moved by Jawaharlal Nehru on December 13, 1946.",
          "objectiveIds": ["lo_preamble_identity"]
        },
        {
          "examId": "upsc",
          "year": 2024,
          "paper": "GS1",
          "questionNumber": 2,
          "subject": "Polity",
          "topic": "Fundamental Rights",
          "questionText": "Which article of the Indian Constitution guarantees the Right to Life and Personal Liberty?",
          "options": ["(A) Article 19", "(B) Article 20", "(C) Article 21", "(D) Article 22"],
          "correctAnswer": "C",
          "explanation": "Article 21 protects life and personal liberty.",
          "objectiveIds": ["lo_article_21_foundations"]
        }
      ]''';

      // Source B: BPSC 2023 (CSV format)
      const bpscDesc = PyqSourceDescriptor(
        sourceId: 'SRC_BPSC_2023_CSV',
        sourceName: 'BPSC 69th Prelims History',
        examId: 'bpsc',
        publisher: 'Bihar Public Service Commission',
        sourceType: SourceType.verifiedArchive,
        format: PyqSourceFormat.csv,
        years: [2023],
        languages: ['en'],
        uriOrPath: 'corpus/bpsc_2023.csv',
      );

      const bpscCsv =
          '''id,examId,year,paper,subject,topic,questionText,optionA,optionB,optionC,optionD,correctKey,explanation,language
BPSC_01,bpsc,2023,GS1,History,Modern History,"Who was the leader of the Santhal Rebellion of 1855?",Sidhu and Kanhu,Birsa Munda,Kunwar Singh,Mangal Pandey,A,Sidhu and Kanhu led the Santhal rebellion.,en''';

      // Source C: Banking 2024 (Text format)
      const bankingDesc = PyqSourceDescriptor(
        sourceId: 'SRC_BANKING_2024_TXT',
        sourceName: 'IBPS PO 2024 Banking Awareness',
        examId: 'banking',
        publisher: 'IBPS',
        sourceType: SourceType.verifiedArchive,
        format: PyqSourceFormat.plainText,
        years: [2024],
        languages: ['en'],
        uriOrPath: 'corpus/banking_2024.txt',
      );

      const bankingText = '''
Q1. Which regulatory body oversees monetary policy in India?
(A) SEBI
(B) Reserve Bank of India
(C) NABARD
(D) IRDAI
Ans: B
Exp: RBI is India's central bank and regulatory authority.
''';

      // 3. Register content into fetcher
      fetcher.registerText(upscDesc, upscJson);
      fetcher.registerText(bpscDesc, bpscCsv);
      fetcher.registerText(bankingDesc, bankingText);

      // 4. Ingest through Acquisition Engine
      final jobs =
          await engine.ingestSources([upscDesc, bpscDesc, bankingDesc]);
      expect(jobs.length, 3);
      for (final j in jobs) {
        expect(j.status, ImportJobStatus.completed);
        expect(j.acceptedQuestions.isNotEmpty, isTrue);
        expect(j.summary.provenanceCompleteRate, 1.0);
      }

      expect(engine.totalQuestionsCount, 4);

      // 5. Test Idempotent Repeated Ingestion
      final repeatedJobs =
          await engine.ingestSources([upscDesc, bpscDesc, bankingDesc]);
      for (final j in repeatedJobs) {
        expect(j.status, ImportJobStatus.skippedAlreadyProcessed);
      }
      expect(engine.totalQuestionsCount, 4); // Zero duplicate explosion

      // 6. Bridge into GARUDA Learning (PyqQuestionProvider & AssessmentService)
      final upscNormalized = intelligenceService
          .getQuestions(const PyqFilterCriteria(examId: 'upsc'));
      expect(upscNormalized.length, 2);

      final pyqDomainQuestions =
          upscNormalized.map((nq) => nq.toPyqQuestion()).toList();

      final questionProvider = PyqQuestionProvider(
        questions: pyqDomainQuestions,
        topicOrTagToObjectiveIds: {
          'preamble': ['lo_preamble_identity'],
          'fundamental rights': ['lo_article_21_foundations'],
          'lo_preamble_identity': ['lo_preamble_identity'],
          'lo_article_21_foundations': ['lo_article_21_foundations'],
        },
      );

      final preambleQuestions =
          questionProvider.getQuestionsForObjectives(['lo_preamble_identity']);
      expect(preambleQuestions.length, 1);
      final questionPreamble = preambleQuestions.first;
      expect(questionPreamble.prompt, contains('Preamble'));

      // 7. Assessment Service Evaluation
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final curriculumService = CurriculumService(framework: framework);

      final learnerRepo = InMemoryLearnerRepository();
      learnerRepo.save(Learner(
        id: 'learner_p30_integration',
        name: 'P30 Test Learner',
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

      final attemptResult = assessmentService.submitAttempt(
        learnerId: 'learner_p30_integration',
        questionId: questionPreamble.id,
        objectiveId: 'lo_preamble_identity',
        submittedAnswer: 'A',
      );

      expect(attemptResult.isCorrect, isTrue);
      final storedAttempt = attemptRepo.getAttemptById(attemptResult.attemptId);
      expect(storedAttempt?.objectiveId, 'lo_preamble_identity');

      // 8. Verify Provenance Integrity
      final storedJob = engine.jobHistory.first;
      expect(storedJob.sourceDescriptor.sourceId, 'SRC_UPSC_2024_JSON');
      expect(storedJob.sourceChecksum.length, 64);
    });
  });
}
