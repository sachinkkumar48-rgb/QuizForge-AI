import 'claude_learning_coach.dart';
import 'gemini_learning_coach.dart';
import 'learning_coach.dart';
import 'local_llm_learning_coach.dart';
import 'openai_learning_coach.dart';

enum CoachProviderType {
  gemini,
  openAi,
  claude,
  localLlm,
}

class LearningCoachFactory {
  static final Map<CoachProviderType, LearningCoach> _coaches = {
    CoachProviderType.gemini: GeminiLearningCoach(),
    CoachProviderType.openAi: OpenAiLearningCoach(),
    CoachProviderType.claude: ClaudeLearningCoach(),
    CoachProviderType.localLlm: LocalLlmLearningCoach(),
  };

  static CoachProviderType _activeType = CoachProviderType.gemini;

  static void registerCoach(CoachProviderType type, LearningCoach coach) {
    _coaches[type] = coach;
  }

  static void setActiveCoachType(CoachProviderType type) {
    _activeType = type;
  }

  static CoachProviderType get activeCoachType => _activeType;

  static LearningCoach getActiveCoach() {
    final coach = _coaches[_activeType];
    if (coach == null) {
      throw StateError("LearningCoach for '$_activeType' is not registered.");
    }
    return coach;
  }

  static List<LearningCoach> getAllCoaches() {
    return _coaches.values.toList();
  }

  static void reset() {
    _coaches.clear();
    _coaches[CoachProviderType.gemini] = GeminiLearningCoach();
    _coaches[CoachProviderType.openAi] = OpenAiLearningCoach();
    _coaches[CoachProviderType.claude] = ClaudeLearningCoach();
    _coaches[CoachProviderType.localLlm] = LocalLlmLearningCoach();
    _activeType = CoachProviderType.gemini;
  }
}
