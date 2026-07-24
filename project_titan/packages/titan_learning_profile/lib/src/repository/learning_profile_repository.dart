import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_revision/titan_revision.dart';
import '../models/learning_profile_models.dart';

/// Abstract repository interface defining operations for accessing and updating learner state.
abstract class LearningProfileRepository {
  /// Fetches the current aggregated [LearningProfile] for a user.
  Future<LearningProfile> getLearningProfile({String userId = 'user_titan'});

  /// Updates learner state by ingesting quiz result analytics.
  Future<LearningProfile> updateProfileFromQuizAnalytics(
      ResultAnalytics analytics);

  /// Updates learner state by ingesting revision attempt results.
  Future<LearningProfile> updateProfileFromRevisionQueue(RevisionQueue queue);

  /// Resets or overrides profile data for testing/initialization.
  Future<void> saveLearningProfile(LearningProfile profile);
}
