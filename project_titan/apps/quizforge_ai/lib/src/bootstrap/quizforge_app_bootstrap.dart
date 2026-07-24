import 'package:titan_core/titan_core.dart';
import 'package:titan_domain/titan_domain.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';

import '../coordinator/application_coordinator.dart';

/// Central application bootstrap registering all TITAN repositories and ApplicationCoordinator.
class QuizForgeAppBootstrap implements TitanModuleBootstrap {
  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  void validate() {
    final locator = TitanServiceLocator.instance;
    TitanModuleValidator.validateRegisteredServices(
      locator,
      [
        PdfRepository,
        QuizGenerationRepository,
        QuizSessionRepository,
        QuizRepository,
      ],
    );
  }

  @override
  void registerDependencies(TitanServiceLocator locator) {
    locator.registerLazySingleton<ApplicationCoordinator>(
      () => ApplicationCoordinator(
        pdfRepository: locator.get<PdfRepository>(),
        quizGenerationRepository: locator.get<QuizGenerationRepository>(),
        quizSessionRepository: locator.get<QuizSessionRepository>(),
        quizRepository: locator.get<QuizRepository>(),
      ),
      allowOverride: true,
    );
  }

  @override
  Future<void> initialize() async {
    registerDependencies(TitanServiceLocator.instance);
    _isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    final locator = TitanServiceLocator.instance;
    if (locator.isRegistered<ApplicationCoordinator>()) {
      locator.unregister<ApplicationCoordinator>();
    }
    _isInitialized = false;
  }
}
