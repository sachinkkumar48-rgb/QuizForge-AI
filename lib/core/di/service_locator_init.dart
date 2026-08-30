import 'package:garuda_learning/garuda_learning.dart';
import 'package:titan_core/titan_core.dart';

import '../../controllers/ai_mentor_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/garuda_dashboard_viewmodel.dart';
import '../../controllers/quiz_controller.dart';
import '../../domain/usecases/generate_quiz_usecase.dart';
import '../../domain/usecases/generate_study_plan_usecase.dart';
import '../../repositories/ai_mentor_repository.dart';
import '../../repositories/impl/garuda_learning_dashboard_repository.dart';
import '../../repositories/impl/hive_pyq_repository.dart';
import '../../repositories/pyq_repository.dart';
import '../../repositories/quiz_repository.dart';
import '../../repositories/titan_quiz_repository.dart';
import '../../services/active_learner_service.dart';
import '../../services/knowledge_integration_service.dart';
import '../../services/quiz_batch_generator.dart';
import '../../services/quiz_generation_adapter.dart';
import '../network/api_client.dart';

/// Initializes dependency injection for QuizForge AI using Project TITAN's [TitanServiceLocator].
void setupServiceLocator() {
  final locator = TitanServiceLocator.instance;

  if (!locator.isRegistered<ApiClient>()) {
    locator.registerLazySingleton<ApiClient>(
      () => ApiClient(),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<QuizBatchGenerator>()) {
    locator.registerLazySingleton<QuizBatchGenerator>(
      () => QuizBatchGenerator(apiClient: locator.get<ApiClient>()),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<KnowledgeIntegrationService>()) {
    locator.registerLazySingleton<KnowledgeIntegrationService>(
      () => KnowledgeIntegrationService(),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<QuizGenerationAdapter>()) {
    locator.registerLazySingleton<QuizGenerationAdapter>(
      () => const QuizGenerationAdapter(),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<TitanQuizRepository>()) {
    locator.registerLazySingleton<TitanQuizRepository>(
      () => TitanQuizRepositoryImpl(
        apiClient: locator.get<ApiClient>(),
        batchGenerator: locator.get<QuizBatchGenerator>(),
        integrationService: locator.get<KnowledgeIntegrationService>(),
        generationAdapter: locator.get<QuizGenerationAdapter>(),
      ),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<QuizRepository>()) {
    locator.registerLazySingleton<QuizRepository>(
      () => QuizRepository(
        apiClient: locator.get<ApiClient>(),
        batchGenerator: locator.get<QuizBatchGenerator>(),
        integrationService: locator.get<KnowledgeIntegrationService>(),
        generationAdapter: locator.get<QuizGenerationAdapter>(),
      ),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<GenerateQuizUseCase>()) {
    locator.registerLazySingleton<GenerateQuizUseCase>(
      () => GenerateQuizUseCaseImpl(
        repository: locator.get<TitanQuizRepository>(),
      ),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<AIMentorRepository>()) {
    locator.registerLazySingleton<AIMentorRepository>(
      () => AIMentorRepository(),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<GenerateStudyPlanUseCase>()) {
    locator.registerLazySingleton<GenerateStudyPlanUseCase>(
      () => GenerateStudyPlanUseCaseImpl(
        repository: locator.get<AIMentorRepository>(),
      ),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<QuizController>()) {
    locator.registerFactory<QuizController>(
      () => QuizController(
        generateQuizUseCase: locator.get<GenerateQuizUseCase>(),
      ),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<DashboardController>()) {
    locator.registerFactory<DashboardController>(
      () => DashboardController(),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<AIMentorController>()) {
    locator.registerFactory<AIMentorController>(
      () => AIMentorController(
        repository: locator.get<AIMentorRepository>(),
        generateStudyPlanUseCase: locator.get<GenerateStudyPlanUseCase>(),
      ),
      allowOverride: true,
    );
  }

  // --- GARUDA Learning Engine Authoritative Services & Repositories (P17-P27) ---
  if (!locator.isRegistered<ActiveLearnerService>()) {
    locator.registerLazySingleton<ActiveLearnerService>(
      () => ActiveLearnerService(),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<CurriculumFramework>()) {
    locator.registerLazySingleton<CurriculumFramework>(
      () => CurriculumSeedData.buildUpscConstitutionalLawFramework(),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<CurriculumService>()) {
    locator.registerLazySingleton<CurriculumService>(
      () => CurriculumService(framework: locator.get<CurriculumFramework>()),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<LearnerRepository>()) {
    locator.registerLazySingleton<LearnerRepository>(
      () {
        final repo = InMemoryLearnerRepository();
        repo.save(Learner(
          id: locator.get<ActiveLearnerService>().activeLearnerId,
          name: 'TITAN UPSC Aspirant',
          createdAt: DateTime.utc(2026, 8, 29),
        ));
        return repo;
      },
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<AttemptRepository>()) {
    locator.registerLazySingleton<AttemptRepository>(
      () => InMemoryAttemptRepository(),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<ProgressRepository>()) {
    locator.registerLazySingleton<ProgressRepository>(
      () => InMemoryProgressRepository(),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<ProgressTracker>()) {
    locator.registerLazySingleton<ProgressTracker>(
      () => ProgressTracker(
        attemptRepository: locator.get<AttemptRepository>(),
        progressRepository: locator.get<ProgressRepository>(),
      ),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<QuestionProvider>()) {
    locator.registerLazySingleton<QuestionProvider>(
      () => CaseLawQuestionProvider(),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<AssessmentService>()) {
    locator.registerLazySingleton<AssessmentService>(
      () => AssessmentService(
        learnerRepository: locator.get<LearnerRepository>(),
        attemptRepository: locator.get<AttemptRepository>(),
        curriculumService: locator.get<CurriculumService>(),
        questionProvider: locator.get<QuestionProvider>(),
        progressTracker: locator.get<ProgressTracker>(),
      ),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<DiagnosticPlacementRepository>()) {
    locator.registerLazySingleton<DiagnosticPlacementRepository>(
      () => InMemoryDiagnosticPlacementRepository(),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<DiagnosticAssessmentService>()) {
    locator.registerLazySingleton<DiagnosticAssessmentService>(
      () => DiagnosticAssessmentService(
        learnerRepository: locator.get<LearnerRepository>(),
        curriculumService: locator.get<CurriculumService>(),
        questionProvider: locator.get<QuestionProvider>(),
        attemptRepository: locator.get<AttemptRepository>(),
        diagnosticRepository: locator.get<DiagnosticPlacementRepository>(),
      ),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<DeterministicStudyPlannerService>()) {
    locator.registerLazySingleton<DeterministicStudyPlannerService>(
      () => const DeterministicStudyPlannerService(),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<RemedialLessonRepository>()) {
    locator.registerLazySingleton<RemedialLessonRepository>(
      () => InMemoryRemedialLessonRepository(),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<DeterministicRemedialLessonService>()) {
    locator.registerLazySingleton<DeterministicRemedialLessonService>(
      () => DeterministicRemedialLessonService(
        lessonRepository: locator.get<RemedialLessonRepository>(),
      ),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<PyqRepository>()) {
    locator.registerLazySingleton<PyqRepository>(
      () => HivePyqRepository(
        assessmentService: locator.get<AssessmentService>(),
        curriculumService: locator.get<CurriculumService>(),
        defaultLearnerId: locator.get<ActiveLearnerService>().activeLearnerId,
      ),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<GarudaDashboardRepository>()) {
    locator.registerLazySingleton<GarudaDashboardRepository>(
      () => GarudaLearningDashboardRepository(
        curriculumService: locator.get<CurriculumService>(),
        progressRepository: locator.get<ProgressRepository>(),
        attemptRepository: locator.get<AttemptRepository>(),
        diagnosticService: locator.get<DiagnosticAssessmentService>(),
        studyPlannerService: locator.get<DeterministicStudyPlannerService>(),
        remedialService: locator.get<DeterministicRemedialLessonService>(),
      ),
      allowOverride: true,
    );
  }

  if (!locator.isRegistered<DashboardViewModel>()) {
    locator.registerFactory<DashboardViewModel>(
      () => DashboardViewModel(
        repository: locator.get<GarudaDashboardRepository>(),
      ),
      allowOverride: true,
    );
  }
}

/// Helper shortcut for obtaining a registered dependency.
T locate<T extends Object>() {
  final locator = TitanServiceLocator.instance;
  if (!locator.isRegistered<T>()) {
    setupServiceLocator();
  }
  return locator.get<T>();
}
