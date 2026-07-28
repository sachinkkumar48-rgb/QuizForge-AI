import '../models/journey_models.dart';
import 'learning_journey_repository.dart';

class LearningJourneyRepositoryImpl implements LearningJourneyRepository {
  final Map<String, LearningJourney> _journeyStorage = {};
  final Map<String, LearningJourney> _cacheStorage = {};
  final Map<String, List<JourneyMilestone>> _milestoneStorage = {};
  final Map<String, List<JourneyCheckpoint>> _checkpointStorage = {};
  final Map<String, JourneyProgress> _progressStorage = {};
  final Map<String, List<JourneyAchievement>> _achievementStorage = {};
  final Map<String, JourneyForecast> _forecastStorage = {};
  final Map<String, List<JourneySnapshot>> _snapshotStorage = {};
  final List<String> _pendingSyncLearnerIds = [];

  @override
  Future<LearningJourney?> getJourney(String learnerId) async {
    if (_journeyStorage.containsKey(learnerId)) {
      return _journeyStorage[learnerId];
    }
    return getCachedJourney(learnerId);
  }

  @override
  Future<void> saveJourney(LearningJourney journey) async {
    _journeyStorage[journey.learnerId] = journey;
    await cacheJourney(journey);
    if (!_pendingSyncLearnerIds.contains(journey.learnerId)) {
      _pendingSyncLearnerIds.add(journey.learnerId);
    }
  }

  @override
  Future<List<JourneyMilestone>> getMilestones(String journeyId) async {
    return _milestoneStorage[journeyId] ?? const [];
  }

  @override
  Future<void> saveMilestone(
      String journeyId, JourneyMilestone milestone) async {
    final list = _milestoneStorage.putIfAbsent(journeyId, () => []);
    final index = list.indexWhere((m) => m.id == milestone.id);
    if (index >= 0) {
      list[index] = milestone;
    } else {
      list.add(milestone);
    }
  }

  @override
  Future<List<JourneyCheckpoint>> getCheckpoints(String journeyId) async {
    return _checkpointStorage[journeyId] ?? const [];
  }

  @override
  Future<void> saveCheckpoint(
      String journeyId, JourneyCheckpoint checkpoint) async {
    final list = _checkpointStorage.putIfAbsent(journeyId, () => []);
    final index = list.indexWhere((c) => c.id == checkpoint.id);
    if (index >= 0) {
      list[index] = checkpoint;
    } else {
      list.add(checkpoint);
    }
  }

  @override
  Future<JourneyProgress?> getProgress(String journeyId) async {
    return _progressStorage[journeyId];
  }

  @override
  Future<void> saveProgress(JourneyProgress progress) async {
    _progressStorage[progress.journeyId] = progress;
  }

  @override
  Future<List<JourneyAchievement>> getAchievements(String journeyId) async {
    return _achievementStorage[journeyId] ?? const [];
  }

  @override
  Future<void> saveAchievements(
      String journeyId, List<JourneyAchievement> achievements) async {
    _achievementStorage[journeyId] = achievements;
  }

  @override
  Future<JourneyForecast?> getForecast(String journeyId) async {
    return _forecastStorage[journeyId];
  }

  @override
  Future<void> saveForecast(JourneyForecast forecast) async {
    _forecastStorage[forecast.journeyId] = forecast;
  }

  @override
  Future<LearningJourney?> getCachedJourney(String learnerId) async {
    return _cacheStorage[learnerId];
  }

  @override
  Future<void> cacheJourney(LearningJourney journey) async {
    _cacheStorage[journey.learnerId] = journey;
  }

  @override
  Future<void> saveSnapshot(JourneySnapshot snapshot) async {
    final list = _snapshotStorage.putIfAbsent(snapshot.journeyId, () => []);
    list.add(snapshot);
  }

  @override
  Future<List<JourneySnapshot>> getSnapshots(String journeyId) async {
    return _snapshotStorage[journeyId] ?? const [];
  }

  @override
  Future<bool> syncPendingChanges(String learnerId) async {
    _pendingSyncLearnerIds.remove(learnerId);
    return true;
  }
}
