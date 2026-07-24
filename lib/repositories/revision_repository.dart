import '../models/revision_schedule.dart';

abstract class RevisionRepository {
  Future<RevisionSchedule?> getSchedule(String questionId);
  Future<Map<String, RevisionSchedule>> getAllSchedules();
  Future<List<RevisionSchedule>> getDueRevisions();
  Future<void> updateSchedule(RevisionSchedule schedule);
  Future<void> recordRevisionResult({
    required String questionId,
    required bool isCorrect,
    int confidenceRating = 3,
    String difficulty = 'Medium',
    bool isBookmarked = false,
  });
  Future<void> clear();
}
