import '../models/learner_profile.dart';

/// Repository contract managing persistence and retrieval of learner proficiency profiles.
abstract class LearnerProfileRepository {
  Future<LearnerProfile?> getProfile(String learnerId);
  Future<void> saveProfile(LearnerProfile profile);
  Future<void> deleteProfile(String learnerId);
  Future<void> clearAll();
}

/// In-memory thread-safe implementation of [LearnerProfileRepository] for testing and local sessions.
class InMemoryLearnerProfileRepository implements LearnerProfileRepository {
  final _profiles = <String, LearnerProfile>{};

  @override
  Future<LearnerProfile?> getProfile(String learnerId) async {
    return _profiles[learnerId];
  }

  @override
  Future<void> saveProfile(LearnerProfile profile) async {
    _profiles[profile.learnerId] = profile;
  }

  @override
  Future<void> deleteProfile(String learnerId) async {
    _profiles.remove(learnerId);
  }

  @override
  Future<void> clearAll() async {
    _profiles.clear();
  }
}
