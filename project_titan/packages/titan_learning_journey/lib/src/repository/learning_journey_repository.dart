import '../models/journey_models.dart';

abstract class LearningJourneyRepository {
  Future<LearningJourney?> getJourney(String learnerId);
  Future<void> saveJourney(LearningJourney journey);

  Future<List<JourneyMilestone>> getMilestones(String journeyId);
  Future<void> saveMilestone(String journeyId, JourneyMilestone milestone);

  Future<List<JourneyCheckpoint>> getCheckpoints(String journeyId);
  Future<void> saveCheckpoint(String journeyId, JourneyCheckpoint checkpoint);

  Future<JourneyProgress?> getProgress(String journeyId);
  Future<void> saveProgress(JourneyProgress progress);

  Future<List<JourneyAchievement>> getAchievements(String journeyId);
  Future<void> saveAchievements(
      String journeyId, List<JourneyAchievement> achievements);

  Future<JourneyForecast?> getForecast(String journeyId);
  Future<void> saveForecast(JourneyForecast forecast);

  Future<LearningJourney?> getCachedJourney(String learnerId);
  Future<void> cacheJourney(LearningJourney journey);

  Future<void> saveSnapshot(JourneySnapshot snapshot);
  Future<List<JourneySnapshot>> getSnapshots(String journeyId);

  Future<bool> syncPendingChanges(String learnerId);
}
