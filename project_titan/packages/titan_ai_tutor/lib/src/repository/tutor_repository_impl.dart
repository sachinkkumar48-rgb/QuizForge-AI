import '../models/tutor_models.dart';
import 'tutor_repository.dart';

/// Implementation of [TutorRepository] with in-memory storage, offline caching,
/// and future synchronization support.
class TutorRepositoryImpl implements TutorRepository {
  final Map<String, TutorSession> _sessions = {};
  final Map<String, TutorLesson> _lessons = {};
  final Map<String, TutorMemory> _memories =
      {}; // key: "${userId}_${conceptId}"
  final Map<String, TutorProgress> _progress = {}; // key: conceptId
  final Map<String, TutorGoal> _goals = {};
  final List<String> _pendingSyncSessionIds = [];

  @override
  Future<TutorSession> createSession(TutorSession session) async {
    _sessions[session.id] = session;
    _pendingSyncSessionIds.add(session.id);
    return session;
  }

  @override
  Future<TutorSession?> getSession(String sessionId) async {
    return _sessions[sessionId];
  }

  @override
  Future<TutorSession> updateSession(TutorSession session) async {
    _sessions[session.id] = session;
    if (!_pendingSyncSessionIds.contains(session.id)) {
      _pendingSyncSessionIds.add(session.id);
    }
    return session;
  }

  @override
  Future<List<TutorSession>> getUserSessions(String learnerId) async {
    return _sessions.values.where((s) => s.learnerId == learnerId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<void> saveLesson(TutorLesson lesson) async {
    _lessons[lesson.id] = lesson;
  }

  @override
  Future<TutorLesson?> getLesson(String lessonId) async {
    return _lessons[lessonId];
  }

  @override
  Future<void> saveMemory(TutorMemory memory) async {
    final key = '${memory.userId}_${memory.conceptId}';
    _memories[key] = memory;
  }

  @override
  Future<TutorMemory?> getMemory(String userId, String conceptId) async {
    final key = '${userId}_$conceptId';
    return _memories[key];
  }

  @override
  Future<TutorProgress> updateProgress(TutorProgress progress) async {
    _progress[progress.conceptId] = progress;
    return progress;
  }

  @override
  Future<TutorProgress?> getProgress(String conceptId) async {
    return _progress[conceptId];
  }

  @override
  Future<TutorGoal> saveGoal(TutorGoal goal) async {
    _goals[goal.id] = goal;
    return goal;
  }

  @override
  Future<List<TutorGoal>> getGoals(String userId) async {
    return _goals.values.where((g) => g.userId == userId).toList();
  }

  @override
  Future<int> syncPendingSessions() async {
    final count = _pendingSyncSessionIds.length;
    _pendingSyncSessionIds.clear();
    return count;
  }
}
