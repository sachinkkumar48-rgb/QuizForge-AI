import '../models/assessment_models.dart';

/// Repository contract for Smart Assessment persistence, attempt tracking,
/// adaptive state storage, analytics, offline caching, and remote sync.
abstract class AssessmentRepository {
  /// Save or cache an assessment
  Future<void> saveAssessment(Assessment assessment);

  /// Fetch an assessment by ID
  Future<Assessment?> getAssessment(String assessmentId);

  /// List available assessments by type or category
  Future<List<Assessment>> getAssessments({
    AssessmentType? type,
    String? subjectCategory,
  });

  /// Create a new assessment session
  Future<AssessmentSession> createSession(AssessmentSession session);

  /// Get an active or completed assessment session
  Future<AssessmentSession?> getSession(String sessionId);

  /// Update an assessment session state or attempt history
  Future<AssessmentSession> updateSession(AssessmentSession session);

  /// Record an assessment attempt
  Future<void> recordAttempt(AssessmentAttempt attempt);

  /// Save evaluation result
  Future<void> saveResult(AssessmentResult result);

  /// Fetch assessment result for a session or assessment ID
  Future<AssessmentResult?> getResult(String assessmentId, String userId);

  /// Save or update adaptive state (IRT theta, error)
  Future<void> saveAdaptiveState(AdaptiveAssessmentState state);

  /// Get adaptive state for a session
  Future<AdaptiveAssessmentState?> getAdaptiveState(String sessionId);

  /// Synchronize pending offline attempts and sessions
  Future<int> syncPendingAssessments();
}
