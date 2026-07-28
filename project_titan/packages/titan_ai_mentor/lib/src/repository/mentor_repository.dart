import '../models/mentor_message.dart';
import '../models/mentor_session.dart';

/// Abstract repository interface for storing and retrieving mentor sessions & history.
abstract class MentorRepository {
  /// Creates a new mentor chat session.
  Future<MentorSession> createSession({
    required String userId,
    required String title,
  });

  /// Retrieves all chat sessions for a user.
  Future<List<MentorSession>> getSessions(String userId);

  /// Retrieves a specific session by ID.
  Future<MentorSession?> getSession(String sessionId);

  /// Saves or updates a mentor session.
  Future<void> saveSession(MentorSession session);

  /// Deletes a mentor session by ID.
  Future<void> deleteSession(String sessionId);

  /// Appends a message to a session's conversation history.
  Future<void> addMessage(String sessionId, MentorMessage message);
}
