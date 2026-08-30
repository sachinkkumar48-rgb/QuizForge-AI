/// Active Learner Service (TITAN-KO-027.0).
///
/// Provides application-wide resolution of the current active learner identity
/// across UI surfaces, PYQ attempts, and diagnostic assessments.
library;

class ActiveLearnerService {
  static const String defaultLearnerId = 'learner_titan_primary';
  String _activeLearnerId;

  ActiveLearnerService({String initialLearnerId = defaultLearnerId})
      : _activeLearnerId = initialLearnerId;

  /// Returns the current active learner ID.
  String get activeLearnerId => _activeLearnerId;

  /// Updates the active learner ID.
  void setActiveLearnerId(String learnerId) {
    final trimmed = learnerId.trim();
    if (trimmed.isNotEmpty) {
      _activeLearnerId = trimmed;
    }
  }
}
