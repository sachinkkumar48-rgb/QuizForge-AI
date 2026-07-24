import 'package:titan_core/titan_core.dart';
import 'package:titan_domain/titan_domain.dart';
import 'package:titan_storage/titan_storage.dart';

import '../repository/quiz_repository.dart';
import '../repository/quiz_repository_impl.dart';
import '../services/quiz_scoring_service.dart';
import '../services/quiz_statistics_service.dart';
import '../services/quiz_validation_service.dart';

/// Central startup bootstrap coordinator for the TITAN Quiz Domain Module.
class TitanQuizBootstrap implements TitanModuleBootstrap {
  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  void validate() {
    final locator = TitanServiceLocator.instance;
    TitanModuleValidator.validateRegisteredServices(
      locator,
      [StorageService],
    );
  }

  @override
  void registerDependencies(TitanServiceLocator locator) {
    const validationService = QuizValidationService();
    const scoringService = QuizScoringService();
    const statisticsService =
        QuizStatisticsService(scoringService: scoringService);

    locator.registerSingleton<QuizValidationService>(validationService,
        allowOverride: true);
    locator.registerSingleton<QuizScoringService>(scoringService,
        allowOverride: true);
    locator.registerSingleton<QuizStatisticsService>(statisticsService,
        allowOverride: true);

    locator.registerLazySingleton<QuizRepository>(
      () => QuizRepositoryImpl(
        storageService: locator.get<StorageService>(),
        validationService: validationService,
      ),
      allowOverride: true,
    );
  }

  @override
  Future<void> initialize() async {
    validate();
    registerDependencies(TitanServiceLocator.instance);
    _isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    final locator = TitanServiceLocator.instance;
    if (locator.isRegistered<QuizRepository>()) {
      final repo = locator.get<QuizRepository>();
      await repo.dispose();
      locator.unregister<QuizRepository>();
    }
    if (locator.isRegistered<QuizStatisticsService>()) {
      locator.unregister<QuizStatisticsService>();
    }
    if (locator.isRegistered<QuizScoringService>()) {
      locator.unregister<QuizScoringService>();
    }
    if (locator.isRegistered<QuizValidationService>()) {
      locator.unregister<QuizValidationService>();
    }
    _isInitialized = false;
  }
}
