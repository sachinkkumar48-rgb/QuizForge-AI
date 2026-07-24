import 'package:titan_core/titan_core.dart';
import 'package:titan_domain/titan_domain.dart';
import 'package:titan_quiz/titan_quiz.dart';

import '../repository/quiz_session_repository.dart';
import '../repository/quiz_session_repository_impl.dart';
import '../services/quiz_progress_service.dart';
import '../services/quiz_session_service.dart';
import '../services/quiz_timer_service.dart';
import '../validators/quiz_session_validator.dart';

/// Central startup bootstrap coordinator for the TITAN Quiz Session Engine Module.
class TitanQuizSessionBootstrap implements TitanModuleBootstrap {
  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  void validate() {
    final locator = TitanServiceLocator.instance;
    TitanModuleValidator.validateRegisteredServices(
      locator,
      [QuizRepository],
    );
  }

  @override
  void registerDependencies(TitanServiceLocator locator) {
    const timerService = QuizTimerService();
    const progressService = QuizProgressService();
    const validator = QuizSessionValidator();

    locator.registerSingleton<QuizTimerService>(timerService,
        allowOverride: true);
    locator.registerSingleton<QuizProgressService>(progressService,
        allowOverride: true);
    locator.registerSingleton<QuizSessionValidator>(validator,
        allowOverride: true);

    locator.registerLazySingleton<QuizSessionService>(
      () => QuizSessionService(
        timerService: timerService,
        validator: validator,
        statisticsService: locator.isRegistered<QuizStatisticsService>()
            ? locator.get<QuizStatisticsService>()
            : const QuizStatisticsService(),
      ),
      allowOverride: true,
    );

    locator.registerLazySingleton<QuizSessionRepository>(
      () => QuizSessionRepositoryImpl(
        sessionService: locator.get<QuizSessionService>(),
      ),
      allowOverride: true,
    );
  }

  @override
  Future<void> initialize() async {
    validate();
    registerDependencies(TitanServiceLocator.instance);
    final repo = TitanServiceLocator.instance.get<QuizSessionRepository>();
    if (!repo.isInitialized) {
      await repo.initialize();
    }
    _isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    final locator = TitanServiceLocator.instance;
    if (locator.isRegistered<QuizSessionRepository>()) {
      final repo = locator.get<QuizSessionRepository>();
      await repo.dispose();
      locator.unregister<QuizSessionRepository>();
    }
    if (locator.isRegistered<QuizSessionService>()) {
      locator.unregister<QuizSessionService>();
    }
    if (locator.isRegistered<QuizSessionValidator>()) {
      locator.unregister<QuizSessionValidator>();
    }
    if (locator.isRegistered<QuizProgressService>()) {
      locator.unregister<QuizProgressService>();
    }
    if (locator.isRegistered<QuizTimerService>()) {
      locator.unregister<QuizTimerService>();
    }
    _isInitialized = false;
  }
}
