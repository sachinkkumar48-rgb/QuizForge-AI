import '../models/tutor_models.dart';

/// Repository interface for AI Tutor session management, lesson persistence,
/// adaptive state, tutoring history, progress tracking, and offline sync.
abstract class TutorRepository {
  /// Create or start a new tutor session
  Future<TutorSession> createSession(TutorSession session);

  /// Fetch an active or past tutor session by ID
  Future<TutorSession?> getSession(String sessionId);

  /// Update session state, exercises, or status
  Future<TutorSession> updateSession(TutorSession session);

  /// List past tutor sessions for a user
  Future<List<TutorSession>> getUserSessions(String learnerId);

  /// Save or cache a generated tutor lesson
  Future<void> saveLesson(TutorLesson lesson);

  /// Retrieve a tutor lesson by ID
  Future<TutorLesson?> getLesson(String lessonId);

  /// Save or update learner memory
  Future<void> saveMemory(TutorMemory memory);

  /// Retrieve learner memory for a specific concept
  Future<TutorMemory?> getMemory(String userId, String conceptId);

  /// Update learner progress for a concept
  Future<TutorProgress> updateProgress(TutorProgress progress);

  /// Get progress metrics for a concept
  Future<TutorProgress?> getProgress(String conceptId);

  /// Save a learner goal
  Future<TutorGoal> saveGoal(TutorGoal goal);

  /// Get learner goals for a user
  Future<List<TutorGoal>> getGoals(String userId);

  /// Sync offline cached sessions with remote backend when online
  Future<int> syncPendingSessions();
}
