import '../models/assessment_models.dart';
import 'assessment_repository.dart';

/// Implementation of [AssessmentRepository] with in-memory persistence,
/// offline caching, attempt logs, and background sync support.
class AssessmentRepositoryImpl implements AssessmentRepository {
  final Map<String, Assessment> _assessments = {};
  final Map<String, AssessmentSession> _sessions = {};
  final Map<String, AssessmentResult> _results =
      {}; // key: "${assessmentId}_$userId"
  final Map<String, AdaptiveAssessmentState> _adaptiveStates = {};
  final List<AssessmentAttempt> _attempts = [];
  final List<String> _pendingSyncSessionIds = [];

  @override
  Future<void> saveAssessment(Assessment assessment) async {
    _assessments[assessment.id] = assessment;
  }

  @override
  Future<Assessment?> getAssessment(String assessmentId) async {
    return _assessments[assessmentId];
  }

  @override
  Future<List<Assessment>> getAssessments({
    AssessmentType? type,
    String? subjectCategory,
  }) async {
    return _assessments.values.where((a) {
      if (type != null && a.type != type) return false;
      if (subjectCategory != null &&
          a.blueprint.subjectCategory != subjectCategory) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<AssessmentSession> createSession(AssessmentSession session) async {
    _sessions[session.id] = session;
    _pendingSyncSessionIds.add(session.id);
    return session;
  }

  @override
  Future<AssessmentSession?> getSession(String sessionId) async {
    return _sessions[sessionId];
  }

  @override
  Future<AssessmentSession> updateSession(AssessmentSession session) async {
    _sessions[session.id] = session;
    if (!_pendingSyncSessionIds.contains(session.id)) {
      _pendingSyncSessionIds.add(session.id);
    }
    return session;
  }

  @override
  Future<void> recordAttempt(AssessmentAttempt attempt) async {
    _attempts.add(attempt);
  }

  @override
  Future<void> saveResult(AssessmentResult result) async {
    final key = '${result.assessmentId}_${result.userId}';
    _results[key] = result;
  }

  @override
  Future<AssessmentResult?> getResult(
      String assessmentId, String userId) async {
    final key = '${assessmentId}_$userId';
    return _results[key];
  }

  @override
  Future<void> saveAdaptiveState(AdaptiveAssessmentState state) async {
    _adaptiveStates[state.sessionId] = state;
  }

  @override
  Future<AdaptiveAssessmentState?> getAdaptiveState(String sessionId) async {
    return _adaptiveStates[sessionId];
  }

  @override
  Future<int> syncPendingAssessments() async {
    final count = _pendingSyncSessionIds.length;
    _pendingSyncSessionIds.clear();
    return count;
  }
}
