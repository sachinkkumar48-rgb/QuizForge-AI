import '../models/live_models.dart';

/// Clean Architecture abstract repository interface for Live Classes Platform.
abstract class LiveClassRepository {
  /// Fetches live class by ID.
  Future<LiveClass?> getLiveClassById(String classId);

  /// Retrieves list of upcoming live classes.
  Future<List<LiveClass>> getUpcomingClasses();

  /// Retrieves all live classes (including completed with recordings).
  Future<List<LiveClass>> getAllLiveClasses();

  /// Schedules a new live class.
  Future<LiveClass> scheduleClass(LiveClass liveClass);

  /// Updates an existing live class.
  Future<LiveClass> updateClass(LiveClass liveClass);

  /// Cancels a scheduled live class.
  Future<bool> cancelClass(String classId);

  /// Joins a live class session as a participant.
  Future<Participant> joinSession(String sessionId, Participant participant);

  /// Leaves a live class session.
  Future<bool> leaveSession(String sessionId, String userId);

  /// Records student attendance.
  Future<Attendance> recordAttendance(Attendance attendance);

  /// Fetches attendance records for a session.
  Future<List<Attendance>> getAttendanceForSession(String sessionId);

  /// Sends a chat message in a session.
  Future<ChatMessage> sendChatMessage(ChatMessage message);

  /// Fetches chat history for a session.
  Future<List<ChatMessage>> getChatHistory(String sessionId);

  /// Saves a whiteboard snapshot.
  Future<WhiteboardSnapshot> saveWhiteboardSnapshot(
      WhiteboardSnapshot snapshot);

  /// Retrieves whiteboard snapshots for a session.
  Future<List<WhiteboardSnapshot>> getWhiteboardSnapshots(String sessionId);

  /// Updates recording metadata for a session.
  Future<Recording> saveRecordingMetadata(Recording recording);

  /// Creates a session reminder.
  Future<SessionReminder> createReminder(SessionReminder reminder);

  /// Fetches reminders for a user.
  Future<List<SessionReminder>> getRemindersForUser(String userId);

  /// Caches live classes locally for offline access.
  Future<void> cacheClassesLocally(List<LiveClass> classes);
}
