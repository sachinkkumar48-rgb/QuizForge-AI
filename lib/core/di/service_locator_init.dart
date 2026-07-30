import 'package:titan_core/titan_core.dart';

import '../../controllers/ai_mentor_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/quiz_controller.dart';
import '../../domain/usecases/generate_quiz_usecase.dart';
import '../../domain/usecases/generate_study_plan_usecase.dart';
import '../../repositories/ai_mentor_repository.dart';
import '../../repositories/quiz_repository.dart';
import '../../repositories/titan_quiz_repository.dart';
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
}

/// Helper shortcut for obtaining a registered dependency.
T locate<T extends Object>() {
  final locator = TitanServiceLocator.instance;
  if (!locator.isRegistered<T>()) {
    setupServiceLocator();
  }
  return locator.get<T>();
}
