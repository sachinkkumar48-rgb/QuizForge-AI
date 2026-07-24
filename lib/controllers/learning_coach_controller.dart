import 'package:flutter/foundation.dart';

import '../models/analytics_engine_models.dart';
import '../models/learning_coach_models.dart';
import '../models/pyq_question_model.dart';
import '../services/ai/coach/learning_coach.dart';
import '../services/ai/coach/learning_coach_factory.dart';

/// State controller bridging UI and [LearningCoach] instances.
class LearningCoachController extends ChangeNotifier {
  LearningCoach _coach;

  PerformanceAnalysis? _analysis;
  WeaknessExplanation? _explanation;
  StudyPlan? _studyPlan;
  RevisionRecommendation? _recommendation;

  bool _isLoading = false;
  String _errorMessage = '';

  LearningCoachController({LearningCoach? coach})
      : _coach = coach ?? LearningCoachFactory.getActiveCoach();

  // Getters
  LearningCoach get coach => _coach;
  CoachProviderType get activeProviderType =>
      LearningCoachFactory.activeCoachType;
  PerformanceAnalysis? get analysis => _analysis;
  WeaknessExplanation? get explanation => _explanation;
  StudyPlan? get studyPlan => _studyPlan;
  RevisionRecommendation? get recommendation => _recommendation;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  void switchProvider(CoachProviderType type) {
    LearningCoachFactory.setActiveCoachType(type);
    _coach = LearningCoachFactory.getActiveCoach();
    notifyListeners();
  }

  Future<void> analyzePerformance(LearningInsightsModel insights) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _analysis = await _coach.analyzePerformance(insights: insights);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> explainWeakness(String topic, double accuracyPercent) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _explanation = await _coach.explainWeakness(
        weaknessTopic: topic,
        accuracyPercent: accuracyPercent,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateStudyPlan({
    required List<String> weakTopics,
    required int totalDays,
    required double dailyHoursAvailable,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _studyPlan = await _coach.generateStudyPlan(
        weakTopics: weakTopics,
        totalDays: totalDays,
        dailyHoursAvailable: dailyHoursAvailable,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recommendRevision({
    required List<String> weakTopics,
    required List<PyqQuestionModel> questions,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _recommendation = await _coach.recommendRevision(
        weakTopics: weakTopics,
        questions: questions,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
