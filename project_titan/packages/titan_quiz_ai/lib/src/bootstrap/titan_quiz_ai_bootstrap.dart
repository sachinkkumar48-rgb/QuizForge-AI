import 'package:titan_ai/titan_ai.dart';
import 'package:titan_core/titan_core.dart';
import 'package:titan_domain/titan_domain.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';

import '../parsers/quiz_json_parser.dart';
import '../prompts/quiz_prompt_builder.dart';
import '../repository/quiz_generation_repository.dart';
import '../repository/quiz_generation_repository_impl.dart';
import '../services/ai_quiz_generation_service.dart';
import '../validators/quiz_json_validator.dart';

/// Central startup bootstrap coordinator for the TITAN AI Quiz Generation Pipeline Module.
class TitanQuizAIBootstrap implements TitanModuleBootstrap {
  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  void validate() {
    final locator = TitanServiceLocator.instance;
    TitanModuleValidator.validateRegisteredServices(
      locator,
      [AIService, PdfRepository, QuizRepository],
    );
  }

  @override
  void registerDependencies(TitanServiceLocator locator) {
    const promptBuilder = QuizPromptBuilder();
    const jsonValidator = QuizJsonValidator();
    const jsonParser = QuizJsonParser();

    locator.registerSingleton<QuizPromptBuilder>(promptBuilder,
        allowOverride: true);
    locator.registerSingleton<QuizJsonValidator>(jsonValidator,
        allowOverride: true);
    locator.registerSingleton<QuizJsonParser>(jsonParser, allowOverride: true);

    locator.registerLazySingleton<AIQuizGenerationService>(
      () => AIQuizGenerationService(
        pdfRepository: locator.get<PdfRepository>(),
        aiService: locator.get<AIService>(),
        promptBuilder: promptBuilder,
        jsonValidator: jsonValidator,
        jsonParser: jsonParser,
      ),
      allowOverride: true,
    );

    locator.registerLazySingleton<QuizGenerationRepository>(
      () => QuizGenerationRepositoryImpl(
        generationService: locator.get<AIQuizGenerationService>(),
        quizRepository: locator.get<QuizRepository>(),
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
    if (locator.isRegistered<QuizGenerationRepository>()) {
      final repo = locator.get<QuizGenerationRepository>();
      await repo.dispose();
      locator.unregister<QuizGenerationRepository>();
    }
    if (locator.isRegistered<AIQuizGenerationService>()) {
      locator.unregister<AIQuizGenerationService>();
    }
    if (locator.isRegistered<QuizJsonParser>()) {
      locator.unregister<QuizJsonParser>();
    }
    if (locator.isRegistered<QuizJsonValidator>()) {
      locator.unregister<QuizJsonValidator>();
    }
    if (locator.isRegistered<QuizPromptBuilder>()) {
      locator.unregister<QuizPromptBuilder>();
    }
    _isInitialized = false;
  }
}
