import 'package:flutter/foundation.dart';
import '../models/ai_mentor_models.dart';
import 'impl/ai_mentor_repository_impl.dart';

/// Clean Architecture Repository Contract for AI Mentor insights,
/// weak topic diagnostics, study plan generation, and actionable recommendations.
abstract class AIMentorRepository {
  static AIMentorRepository? _instance;

  static AIMentorRepository get instance {
    _instance ??= AIMentorRepositoryImpl();
    return _instance!;
  }

  @visibleForTesting
  static set instance(AIMentorRepository mock) {
    _instance = mock;
  }

  factory AIMentorRepository() => instance;

  /// Retrieves full AI Mentor overview overview including greetings, weak topics, and recommendations.
  Future<AIMentorData> getMentorOverview();

  /// Retrieves list of identified weak topics.
  Future<List<WeakTopicInfo>> getWeakTopics();

  /// Generates a customized multi-day study plan.
  Future<List<StudyPlanItem>> generateStudyPlan({
    int targetDays = 7,
    double dailyHours = 3.0,
  });

  /// Retrieves actionable AI mentor recommendations.
  Future<List<MentorRecommendation>> getRecommendations();
}
