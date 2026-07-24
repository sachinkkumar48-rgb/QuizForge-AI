import '../models/learning_profile_models.dart';
import '../repository/learning_profile_repository.dart';

/// Clean Architecture Use Case for fetching current aggregated learner profile state.
class GetLearningProfileUseCase {
  final LearningProfileRepository _repository;

  const GetLearningProfileUseCase(this._repository);

  /// Executes retrieval of the active [LearningProfile].
  Future<LearningProfile> execute({String userId = 'user_titan'}) {
    return _repository.getLearningProfile(userId: userId);
  }
}
