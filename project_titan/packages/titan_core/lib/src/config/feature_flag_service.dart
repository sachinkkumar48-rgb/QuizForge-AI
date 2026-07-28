/// Feature Flag Service managing beta feature toggles for Project TITAN.
class FeatureFlagService {
  final Map<String, bool> _flags;

  FeatureFlagService({Map<String, bool>? initialFlags})
      : _flags = Map<String, bool>.from(initialFlags ?? defaultBetaFlags);

  /// Default 8 beta feature flags requested for TITAN 2.0 release.
  static const Map<String, bool> defaultBetaFlags = {
    'video_classes': false,
    'live_classes': false,
    'marketplace': false,
    'voice_mentor': true,
    'ai_tutor': true,
    'gamification': true,
    'multiplayer': false,
    'teacher_portal': false,
  };

  /// Checks if a feature flag is enabled.
  bool isEnabled(String flagKey) {
    return _flags[flagKey] ?? false;
  }

  /// Sets feature flag state.
  void setFlag(String flagKey, bool enabled) {
    _flags[flagKey] = enabled;
  }

  /// Returns all active feature flags.
  Map<String, bool> getAllFlags() {
    return Map<String, bool>.unmodifiable(_flags);
  }

  /// Feature flag getters for required beta capabilities
  bool get videoClasses => isEnabled('video_classes');
  bool get liveClasses => isEnabled('live_classes');
  bool get marketplace => isEnabled('marketplace');
  bool get voiceMentor => isEnabled('voice_mentor');
  bool get aiTutor => isEnabled('ai_tutor');
  bool get gamification => isEnabled('gamification');
  bool get multiplayer => isEnabled('multiplayer');
  bool get teacherPortal => isEnabled('teacher_portal');
}
