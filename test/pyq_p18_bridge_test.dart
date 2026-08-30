import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/models/answer_model.dart';
import 'package:garuda_pyq/models/option_model.dart';
import 'package:garuda_pyq/models/question_model.dart' as pyq;
import 'package:garuda_pyq/models/source_model.dart';
import 'package:hive/hive.dart';
import 'package:quizforge_upsc/models/pyq_question_model.dart';
import 'package:quizforge_upsc/repositories/impl/hive_pyq_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late InMemoryLearnerRepository learnerRepo;
  late InMemoryAttemptRepository attemptRepo;
  late InMemoryProgressRepository progressRepo;
  late CurriculumService curriculumService;
  late AssessmentService assessmentService;
  late PyqQuestionProvider questionProvider;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_pyq_bridge_test_');
    Hive.init(tempDir.path);

    final framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
    curriculumService = CurriculumService(framework: framework);
    learnerRepo = InMemoryLearnerRepository();
    attemptRepo = InMemoryAttemptRepository();
    progressRepo = InMemoryProgressRepository();

    learnerRepo.save(Learner(
      id: 'learner_bridge_01',
      name: 'Bridge Test Learner',
      createdAt: DateTime.utc(2026, 8, 29),
    ));

    final pyqQ = pyq.Question(
      id: 'q_preamble_01',
      questionNumber: 1,
      examId: 'upsc_cse',
      year: 2024,
      stage: 'Prelims',
      paper: 'GS1',
      subject: 'Polity',
      topic: 'Basic Structure',
      questionType: pyq.QuestionType.mcq,
      originalQuestion: 'Is the Preamble an integral part of the Constitution?',
      options: const [
        Option(key: 'A', text: 'Yes', isCorrect: true),
        Option(key: 'B', text: 'No', isCorrect: false),
      ],
      officialAnswer: const Answer(
        correctOptionKeys: ['A'],
        officialAnswerSource: 'UPSC Key',
      ),
      garudaExplanation: 'Yes, as held in Kesavananda Bharati.',
      source: QuestionSource(
        sourceType: SourceType.officialWebsite,
        url: 'https://upsc.gov.in',
        checksum: 'chk_test',
        publisher: 'UPSC',
        retrievedDate: DateTime.utc(2024, 6, 1),
      ),
    );

    questionProvider = PyqQuestionProvider(
      questions: [pyqQ],
      topicOrTagToObjectiveIds: {
        'basic structure': ['lo_basic_structure_doctrine'],
      },
    );

    assessmentService = AssessmentService(
      learnerRepository: learnerRepo,
      attemptRepository: attemptRepo,
      curriculumService: curriculumService,
      questionProvider: questionProvider,
      progressTracker: ProgressTracker(
        attemptRepository: attemptRepo,
        progressRepository: progressRepo,
      ),
    );
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
      'HivePyqRepository.recordAttempt routes through P18 AssessmentService and updates P18 progress',
      () async {
    final repo = HivePyqRepository(
      assessmentService: assessmentService,
      defaultLearnerId: 'learner_bridge_01',
      curriculumService: curriculumService,
      objectiveResolver: (q) => 'lo_basic_structure_doctrine',
    );

    final box = await Hive.openBox<String>('pyq_questions');
    final sampleModel = PyqQuestionModel(
      id: 'q_preamble_01',
      year: 2024,
      exam: 'UPSC CSE Prelims',
      paper: 'GS1',
      subject: 'Polity',
      topic: 'Basic Structure',
      difficulty: 'Medium',
      question: 'Is the Preamble an integral part of the Constitution?',
      options: const ['Yes', 'No', 'None', 'Other'],
      correctAnswer: 'A',
      officialAnswer: 'A',
      explanation:
          PyqExplanation(official: 'Yes, as held in Kesavananda Bharati.'),
      reference: 'Constitution of India',
    );
    await box.put(sampleModel.id, jsonEncode(sampleModel.toJson()));

    // 1. Submit attempt via HivePyqRepository
    await repo.recordAttempt(
      questionId: 'q_preamble_01',
      selectedAnswer: 'A',
      learnerId: 'learner_bridge_01',
      objectiveId: 'lo_basic_structure_doctrine',
    );

    // 2. Verify authoritative P18 Evidence was recorded
    final attempts = attemptRepo.getAttemptsForLearner('learner_bridge_01');
    expect(attempts.length, 1);
    expect(attempts.first.questionId, 'q_preamble_01');
    expect(attempts.first.objectiveId, 'lo_basic_structure_doctrine');
    expect(attempts.first.submittedAnswer, 'A');

    final result = attemptRepo.getResultForAttempt(attempts.first.attemptId);
    expect(result, isNotNull);
    expect(result!.isCorrect, isTrue);
    expect(result.score, 1.0);

    // 3. Verify P18 Progress was updated
    final progress = progressRepo.getProgress(
        'learner_bridge_01', 'lo_basic_structure_doctrine');
    expect(progress, isNotNull);
    expect(progress!.attemptCount, 1);
    expect(progress.correctCount, 1);
  });
}
