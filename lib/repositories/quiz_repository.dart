import '../core/network/api_client.dart';
import 'titan_quiz_repository.dart';

/// Legacy [QuizRepository] class extending [TitanQuizRepositoryImpl]
/// for backwards compatibility across existing test suites and references.
class QuizRepository extends TitanQuizRepositoryImpl {
  QuizRepository({
    super.apiClient,
    super.batchGenerator,
    super.integrationService,
    super.generationAdapter,
    super.quizSourceRepository,
  });
}
