import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_revision/titan_revision.dart';
import '../models/learning_profile_models.dart';
import '../repository/learning_profile_repository.dart';

/// Clean Architecture Use Case for updating learner state from analytics or revision inputs.
class UpdateLearningProfileUseCase {
  final LearningProfileRepository _repository;

  const UpdateLearningProfileUseCase(this._repository);

  /// Updates learner profile state using completed quiz session analytics.
  Future<LearningProfile> fromQuizAnalytics(ResultAnalytics analytics) {
    return _repository.updateProfileFromQuizAnalytics(analytics);
  }

  /// Updates learner profile state using active revision queue state.
  Future<LearningProfile> fromRevisionQueue(RevisionQueue queue) {
    return _repository.updateProfileFromRevisionQueue(queue);
  }
}
